#import <Foundation/Foundation.h>
// Benachrichtigung nach jedem Sync (Main-Thread).
extern NSString * const MXSyncUpdated;

@interface MXClient : NSObject
+ (void)loadSaved;                 // Token/Host aus Defaults laden
+ (BOOL)isLoggedIn;
+ (NSString *)userId;
+ (void)logout;
+ (void)loginUser:(NSString *)user password:(NSString *)pass homeserver:(NSString *)hs
       completion:(void(^)(BOOL ok, NSString *err))done;
+ (void)registerUser:(NSString *)user password:(NSString *)pass homeserver:(NSString *)hs
          completion:(void(^)(BOOL ok, NSString *err))done;
+ (void)startSync;                 // Hintergrund-Sync-Schleife
+ (NSArray *)rooms;                // [{id,name,last,ts}] nach ts absteigend
+ (NSArray *)messagesForRoom:(NSString *)roomId;   // [{sender,body,ts,mine}] aufsteigend
+ (NSString *)nameForRoom:(NSString *)roomId;
+ (void)sendRoom:(NSString *)roomId text:(NSString *)text completion:(void(^)(BOOL ok))done;
@end
