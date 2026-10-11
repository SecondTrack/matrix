#import "MXClient.h"
#import "MXNet.h"
#import "MeshL10n.h"

NSString * const MXSyncUpdated = @"MXSyncUpdated";

static NSString *gHost=nil, *gToken=nil, *gUserId=nil, *gNext=nil;
static NSMutableDictionary *gRoom=nil;   // roomId -> {name, heroes, last, ts}
static NSMutableDictionary *gMsgs=nil;    // roomId -> NSMutableArray<NSMutableDictionary>
static NSMutableSet *gSeen=nil;           // event ids
static BOOL gSyncing=NO;

static dispatch_queue_t mxQ(void){ static dispatch_queue_t q; static dispatch_once_t o; dispatch_once(&o,^{ q=dispatch_queue_create("mx.sync",DISPATCH_QUEUE_SERIAL); }); return q; }
static NSString* localpart(NSString*uid){ NSRange c=[uid rangeOfString:@":"]; NSString*s=(c.location!=NSNotFound)?[uid substringToIndex:c.location]:uid; return [s hasPrefix:@"@"]?[s substringFromIndex:1]:s; }
static NSString* normHost(NSString*hs){
    NSString*host=hs.length?hs:@"matrix.org";
    host=[host stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    host=[host stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    return [host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@implementation MXClient

+ (void)ensure { if(!gRoom){gRoom=[NSMutableDictionary dictionary];gMsgs=[NSMutableDictionary dictionary];gSeen=[NSMutableSet set];} }

+ (void)loadSaved {
    [self ensure];
    NSUserDefaults*u=[NSUserDefaults standardUserDefaults];
    gHost=[u stringForKey:@"mxHost"]; gToken=[u stringForKey:@"mxToken"]; gUserId=[u stringForKey:@"mxUser"];
}
+ (BOOL)isLoggedIn { return gToken.length>0 && gHost.length>0; }
+ (NSString *)userId { return gUserId; }
+ (void)logout {
    gToken=nil; gNext=nil; [gRoom removeAllObjects]; [gMsgs removeAllObjects]; [gSeen removeAllObjects];
    NSUserDefaults*u=[NSUserDefaults standardUserDefaults];
    [u removeObjectForKey:@"mxToken"]; [u removeObjectForKey:@"mxUser"]; [u synchronize];
}

+ (void)loginUser:(NSString *)user password:(NSString *)pass homeserver:(NSString *)hs
       completion:(void(^)(BOOL,NSString*))done {
    [self ensure];
    NSString*host=hs.length?hs:@"matrix.org";
    host=[host stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    host=[host stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    host=[host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    dispatch_async(mxQ(), ^{
        NSDictionary*body=@{ @"type":@"m.login.password",
                             @"identifier":@{ @"type":@"m.id.user", @"user":user },
                             @"password":pass,
                             @"initial_device_display_name":@"iPod touch (Reboot)" };
        int st=0; id r=[MXNet json:@"POST" host:host path:@"/_matrix/client/v3/login" bearer:nil jsonBody:body status:&st];
        NSString*tok=[r isKindOfClass:[NSDictionary class]]?r[@"access_token"]:nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(tok.length){
                gHost=host; gToken=tok; gUserId=r[@"user_id"];
                NSUserDefaults*u=[NSUserDefaults standardUserDefaults];
                [u setObject:gHost forKey:@"mxHost"]; [u setObject:gToken forKey:@"mxToken"]; [u setObject:(gUserId?:@"") forKey:@"mxUser"]; [u synchronize];
                if(done)done(YES,nil);
            } else {
                NSString*e=[r isKindOfClass:[NSDictionary class]]?(r[@"error"]?:L(@"Login failed")):LF(@"No response (HTTP %d)",st);
                if(done)done(NO,e);
            }
        });
    });
}

+ (void)applySession:(NSDictionary *)r host:(NSString *)host {
    gHost=host; gToken=r[@"access_token"]; gUserId=r[@"user_id"];
    NSUserDefaults*u=[NSUserDefaults standardUserDefaults];
    [u setObject:gHost forKey:@"mxHost"]; [u setObject:(gToken?:@"") forKey:@"mxToken"]; [u setObject:(gUserId?:@"") forKey:@"mxUser"]; [u synchronize];
}
// nächste machbare UIA-Stufe (nur dummy/terms unterstützt); nil wenn Server Captcha/E-Mail verlangt
+ (NSString *)nextStage:(NSArray *)flows completed:(NSArray *)completed {
    NSSet*sup=[NSSet setWithObjects:@"m.login.dummy",@"m.login.terms",nil];
    if(![flows isKindOfClass:[NSArray class]]) return nil;
    for(NSDictionary*f in flows){
        NSArray*stages=f[@"stages"]; BOOL ok=YES;
        for(NSString*s in stages) if(![sup containsObject:s]){ ok=NO; break; }
        if(!ok) continue;
        for(NSString*s in stages) if(![completed containsObject:s]) return s;
    }
    return nil;
}
+ (void)registerUser:(NSString *)user password:(NSString *)pass homeserver:(NSString *)hs
          completion:(void(^)(BOOL,NSString*))done {
    [self ensure];
    NSString*host=normHost(hs);
    dispatch_async(mxQ(), ^{
        NSMutableDictionary*auth=nil; NSString*fail=nil; BOOL success=NO; NSDictionary*okResp=nil;
        for(int guard=0; guard<8; guard++){
            NSMutableDictionary*body=[@{ @"username":user, @"password":pass, @"initial_device_display_name":@"iPod touch (Reboot)" } mutableCopy];
            if(auth) body[@"auth"]=auth;
            int st=0; id r=[MXNet json:@"POST" host:host path:@"/_matrix/client/v3/register" bearer:nil jsonBody:body status:&st];
            if(![r isKindOfClass:[NSDictionary class]]){ fail=LF(@"No response (HTTP %d)",st); break; }
            if(r[@"access_token"]){ success=YES; okResp=r; break; }
            if(st==401 && r[@"flows"]){
                NSString*session=r[@"session"]; NSArray*completed=r[@"completed"]?:@[];
                NSString*next=[self nextStage:r[@"flows"] completed:completed];
                if(!next){ fail=L(@"This server requires a captcha/email to register (not possible in the app). Use a homeserver with open registration — or register once in a browser (app.element.io) and sign in here with username + password."); break; }
                auth=[@{ @"type":next, @"session":session?:@"" } mutableCopy];
                continue;
            }
            fail=[r[@"error"] isKindOfClass:[NSString class]]?r[@"error"]:LF(@"Registration failed (HTTP %d)",st);
            break;
        }
        if(!fail && !success) fail=L(@"Registration: too many steps");
        dispatch_async(dispatch_get_main_queue(), ^{
            if(success){ [self applySession:okResp host:host]; if(done)done(YES,nil); }
            else if(done)done(NO,fail);
        });
    });
}

// ---- Sync ----
+ (void)startSync {
    if(gSyncing || ![self isLoggedIn]) return;
    gSyncing=YES;
    dispatch_async(mxQ(), ^{
        while(gToken.length){
            NSString*filter=[MXNet enc:@"{\"room\":{\"timeline\":{\"limit\":20}},\"presence\":{\"types\":[]}}"];
            NSMutableString*path=[NSMutableString stringWithFormat:@"/_matrix/client/v3/sync?filter=%@&timeout=%@",filter,gNext?@"30000":@"0"];
            if(gNext) [path appendFormat:@"&since=%@",[MXNet enc:gNext]];
            int st=0; id r=[MXNet json:@"GET" host:gHost path:path bearer:gToken jsonBody:nil status:&st];
            if(st==401){ dispatch_async(dispatch_get_main_queue(),^{ [self logout]; [[NSNotificationCenter defaultCenter] postNotificationName:MXSyncUpdated object:nil]; }); break; }
            if([r isKindOfClass:[NSDictionary class]]){
                [self processSync:r];
                dispatch_async(dispatch_get_main_queue(), ^{ [[NSNotificationCenter defaultCenter] postNotificationName:MXSyncUpdated object:nil]; });
            } else {
                [NSThread sleepForTimeInterval:3.0];   // Fehler -> kurz warten
            }
        }
        gSyncing=NO;
    });
}

+ (void)processSync:(NSDictionary *)resp {
    gNext=resp[@"next_batch"];
    NSDictionary*join=resp[@"rooms"][@"join"]; if(![join isKindOfClass:[NSDictionary class]]) return;
    for(NSString*rid in join){
        NSDictionary*rd=join[rid];
        NSMutableDictionary*info=gRoom[rid]; if(!info){ info=[NSMutableDictionary dictionary]; gRoom[rid]=info; }
        // Name aus State
        for(NSDictionary*e in rd[@"state"][@"events"]){
            if([e[@"type"] isEqualToString:@"m.room.name"] && e[@"content"][@"name"]) info[@"name"]=e[@"content"][@"name"];
            else if([e[@"type"] isEqualToString:@"m.room.canonical_alias"] && !info[@"name"] && e[@"content"][@"alias"]) info[@"name"]=e[@"content"][@"alias"];
        }
        NSArray*heroes=rd[@"summary"][@"m.heroes"]; if([heroes isKindOfClass:[NSArray class]]&&heroes.count) info[@"heroes"]=heroes;
        // Timeline
        NSMutableArray*list=gMsgs[rid]; if(!list){ list=[NSMutableArray array]; gMsgs[rid]=list; }
        for(NSDictionary*e in rd[@"timeline"][@"events"]){
            NSString*type=e[@"type"]; NSString*eid=e[@"event_id"];
            if([type isEqualToString:@"m.room.name"] && e[@"content"][@"name"]) info[@"name"]=e[@"content"][@"name"];
            if(![type isEqualToString:@"m.room.message"] && ![type isEqualToString:@"m.room.encrypted"]) continue;
            if(eid && [gSeen containsObject:eid]) continue;
            NSString*sender=e[@"sender"]; BOOL mine=[sender isEqualToString:gUserId];
            NSString*body;
            if([type isEqualToString:@"m.room.encrypted"]) body=L(@"🔒 encrypted (E2E coming later)");
            else { body=e[@"content"][@"body"]; NSString*mt=e[@"content"][@"msgtype"];
                   if([mt isEqualToString:@"m.image"])body=L(@"🖼 Image"); else if([mt isEqualToString:@"m.file"])body=L(@"📎 File"); else if([mt isEqualToString:@"m.audio"])body=L(@"🎵 Audio"); }
            if(![body isKindOfClass:[NSString class]]) continue;
            double ts=[e[@"origin_server_ts"] doubleValue];
            // Pending-Echo ersetzen (eigene gerade gesendete Nachricht)
            if(mine){ NSMutableDictionary*pend=nil; for(NSMutableDictionary*m in list) if([m[@"pending"] boolValue]&&[m[@"body"] isEqualToString:body]){pend=m;break;}
                if(pend){ pend[@"pending"]=@NO; pend[@"eid"]=eid?:@""; pend[@"ts"]=@(ts); if(eid)[gSeen addObject:eid]; continue; } }
            if(eid)[gSeen addObject:eid];
            [list addObject:[@{@"sender":sender?:@"?",@"body":body,@"ts":@(ts),@"mine":@(mine),@"eid":eid?:@"",@"pending":@NO} mutableCopy]];
        }
        // Raum-Metadaten (letzte Nachricht)
        NSDictionary*last=[list lastObject];
        if(last){ info[@"last"]=last[@"body"]; info[@"ts"]=last[@"ts"]; }
        else if(!info[@"ts"]) info[@"ts"]=@0;
        info[@"id"]=rid;
    }
}

+ (NSString *)nameForRoom:(NSString *)roomId {
    NSDictionary*info=gRoom[roomId];
    if(info[@"name"]) return info[@"name"];
    NSArray*heroes=info[@"heroes"];
    if([heroes isKindOfClass:[NSArray class]]&&heroes.count){
        NSMutableArray*n=[NSMutableArray array]; for(NSString*h in heroes)[n addObject:localpart(h)];
        return [n componentsJoinedByString:@", "];
    }
    return localpart(roomId);
}

+ (NSArray *)rooms {
    NSMutableArray*all=[NSMutableArray array];
    for(NSString*rid in gRoom){ NSMutableDictionary*m=[gRoom[rid] mutableCopy]; m[@"id"]=rid; m[@"name"]=[self nameForRoom:rid]; [all addObject:m]; }
    [all sortUsingComparator:^NSComparisonResult(NSDictionary*a,NSDictionary*b){ return [b[@"ts"] compare:a[@"ts"]?:@0]; }];
    return all;
}
+ (NSArray *)messagesForRoom:(NSString *)roomId { return gMsgs[roomId]?:@[]; }

+ (void)sendRoom:(NSString *)roomId text:(NSString *)text completion:(void(^)(BOOL))done {
    if(!text.length){ if(done)done(NO); return; }
    // optimistisch anzeigen
    NSMutableArray*list=gMsgs[roomId]; if(!list){ list=[NSMutableArray array]; gMsgs[roomId]=list; }
    [list addObject:[@{@"sender":gUserId?:@"",@"body":text,@"ts":@([[NSDate date] timeIntervalSince1970]*1000),@"mine":@YES,@"eid":@"",@"pending":@YES} mutableCopy]];
    [[NSNotificationCenter defaultCenter] postNotificationName:MXSyncUpdated object:nil];
    dispatch_async(mxQ(), ^{
        NSString*txn=[NSString stringWithFormat:@"m%ld",(long)([[NSDate date] timeIntervalSince1970]*1000)];
        NSString*path=[NSString stringWithFormat:@"/_matrix/client/v3/rooms/%@/send/m.room.message/%@",[MXNet enc:roomId],txn];
        int st=0; id r=[MXNet json:@"PUT" host:gHost path:path bearer:gToken jsonBody:@{@"msgtype":@"m.text",@"body":text} status:&st];
        BOOL ok=([r isKindOfClass:[NSDictionary class]] && r[@"event_id"]);
        dispatch_async(dispatch_get_main_queue(), ^{ if(done)done(ok); });
    });
}

@end
