#import "MXTheme.h"
#import "MXClient.h"
#import "MeshL10n.h"

static NSString* lp(NSString*uid){ NSRange c=[uid rangeOfString:@":"]; NSString*s=(c.location!=NSNotFound)?[uid substringToIndex:c.location]:uid; return [s hasPrefix:@"@"]?[s substringFromIndex:1]:s; }
#define BUBFONT [UIFont systemFontOfSize:15]

@interface MXChatController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property(nonatomic,strong) NSString *roomId;
@property(nonatomic,strong) NSString *roomName;
@end
@implementation MXChatController {
    UITableView *_tv; UIView *_bar; UITextField *_input; UIButton *_send;
    NSArray *_msgs; CGFloat _barH;
}
- (BOOL)showSender:(NSInteger)row {
    if(row<0||row>=(NSInteger)_msgs.count) return NO;
    NSDictionary*m=_msgs[row]; if([m[@"mine"] boolValue]) return NO;
    if(row==0) return YES;
    return ![_msgs[row-1][@"sender"] isEqualToString:m[@"sender"]];
}
- (CGSize)bodySize:(NSString *)s max:(CGFloat)maxw {
    return [s sizeWithFont:BUBFONT constrainedToSize:CGSizeMake(maxw,100000) lineBreakMode:NSLineBreakByWordWrapping];
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; self.view.backgroundColor=MBG;
    self.title=_roomName?:L(@"Chat");
    CGFloat W=self.view.bounds.size.width, H=self.view.bounds.size.height; _barH=48;
    _tv=[[UITableView alloc] initWithFrame:CGRectMake(0,0,W,H-_barH) style:UITableViewStylePlain];
    _tv.dataSource=self; _tv.delegate=self; _tv.separatorStyle=UITableViewCellSeparatorStyleNone; _tv.backgroundColor=MBG;
    [self.view addSubview:_tv];
    _bar=[[UIView alloc] initWithFrame:CGRectMake(0,H-_barH,W,_barH)]; _bar.backgroundColor=MCARD;
    UIView*ln=[[UIView alloc] initWithFrame:CGRectMake(0,0,W,0.5)]; ln.backgroundColor=MLINE; [_bar addSubview:ln];
    _input=[[UITextField alloc] initWithFrame:CGRectMake(10,7,W-78,34)]; _input.backgroundColor=MTRACK; _input.layer.cornerRadius=17; _input.placeholder=L(@"Message"); _input.font=[UIFont systemFontOfSize:15]; _input.delegate=self; _input.returnKeyType=UIReturnKeySend;
    UIView*pad=[[UIView alloc] initWithFrame:CGRectMake(0,0,12,34)]; _input.leftView=pad; _input.leftViewMode=UITextFieldViewModeAlways; [_bar addSubview:_input];
    _send=[UIButton buttonWithType:UIButtonTypeCustom]; _send.frame=CGRectMake(W-64,7,56,34); [_send setTitle:L(@"Send") forState:UIControlStateNormal]; [_send setTitleColor:MGRN forState:UIControlStateNormal]; _send.titleLabel.font=[UIFont boldSystemFontOfSize:15]; [_send addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside]; [_bar addSubview:_send];
    [self.view addSubview:_bar];

    UITapGestureRecognizer*t=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKb)]; t.cancelsTouchesInView=NO; [_tv addGestureRecognizer:t];
}
- (void)viewDidLoad { [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:MXSyncUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbHide:) name:UIKeyboardWillHideNotification object:nil];
    [self reload];
}
- (void)reload { _msgs=[MXClient messagesForRoom:_roomId]; [_tv reloadData]; [self scrollBottom:NO]; }
- (void)scrollBottom:(BOOL)anim { if(_msgs.count) [_tv scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_msgs.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:anim]; }
- (void)hideKb { [_input resignFirstResponder]; }

- (void)kbShow:(NSNotification *)n {
    CGRect kb=[n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue]; kb=[self.view convertRect:kb fromView:nil];
    CGFloat ov=CGRectGetMaxY(self.view.bounds)-kb.origin.y; if(ov<0)ov=0;
    [UIView animateWithDuration:0.25 animations:^{
        _bar.frame=CGRectMake(0,self.view.bounds.size.height-_barH-ov,self.view.bounds.size.width,_barH);
        _tv.frame=CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height-_barH-ov);
    } completion:^(BOOL f){ [self scrollBottom:YES]; }];
}
- (void)kbHide:(NSNotification *)n {
    [UIView animateWithDuration:0.25 animations:^{
        _bar.frame=CGRectMake(0,self.view.bounds.size.height-_barH,self.view.bounds.size.width,_barH);
        _tv.frame=CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height-_barH);
    }];
}
- (BOOL)textFieldShouldReturn:(UITextField *)tf { [self send]; return NO; }
- (void)send {
    NSString*t=[_input.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(!t.length) return; _input.text=@"";
    [MXClient sendRoom:_roomId text:t completion:nil];
}

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return _msgs.count; }
- (CGFloat)tableView:(UITableView *)t heightForRowAtIndexPath:(NSIndexPath *)ip {
    CGFloat maxw=(t.bounds.size.width-24)*0.74-20;
    CGSize sz=[self bodySize:_msgs[ip.row][@"body"] max:maxw];
    CGFloat h=sz.height+20+8; if([self showSender:ip.row]) h+=16; return h;
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell*c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    c.backgroundColor=[UIColor clearColor]; c.selectionStyle=UITableViewCellSelectionStyleNone;
    NSDictionary*m=_msgs[ip.row]; BOOL mine=[m[@"mine"] boolValue]; NSString*body=m[@"body"];
    CGFloat W=t.bounds.size.width, pad=10, maxw=(W-24)*0.74-20; CGFloat top=4;
    if([self showSender:ip.row]){
        UILabel*sn=[[UILabel alloc] initWithFrame:CGRectMake(16,2,W-32,14)]; sn.text=lp(m[@"sender"]); sn.font=[UIFont systemFontOfSize:11]; sn.textColor=MMUT; sn.backgroundColor=[UIColor clearColor]; [c.contentView addSubview:sn]; top=18;
    }
    CGSize sz=[self bodySize:body max:maxw]; CGFloat bw=sz.width+2*pad, bh=sz.height+2*pad;
    UIView*bub=[[UIView alloc] initWithFrame:CGRectMake(mine? W-12-bw : 12, top, bw, bh)];
    bub.backgroundColor= mine?MGRN:MCARD; bub.layer.cornerRadius=15;
    if(!mine){ bub.layer.borderWidth=0.5; bub.layer.borderColor=MLINE.CGColor; }
    UILabel*lbl=[[UILabel alloc] initWithFrame:CGRectMake(pad,pad,bw-2*pad,bh-2*pad)]; lbl.numberOfLines=0; lbl.font=BUBFONT; lbl.text=body; lbl.textColor= mine?[UIColor whiteColor]:MINK; lbl.backgroundColor=[UIColor clearColor]; [bub addSubview:lbl];
    if([m[@"pending"] boolValue]) bub.alpha=0.6;
    [c.contentView addSubview:bub];
    return c;
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)s { [_input resignFirstResponder]; }
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
@end
