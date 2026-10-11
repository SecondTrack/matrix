#import "MXTheme.h"
#import "MXClient.h"
#import "MeshL10n.h"

@interface MXRoomsController : UIViewController @end

@interface MXLoginController : UIViewController <UITextFieldDelegate> @end
@implementation MXLoginController {
    UITextField *_hs, *_user, *_pw; UILabel *_err; UIButton *_btn; UIActivityIndicatorView *_spin;
    UISegmentedControl *_seg; NSInteger _mode;
}
- (UITextField *)field:(CGRect)f placeholder:(NSString *)p secure:(BOOL)sec {
    UITextField*t=[[UITextField alloc] initWithFrame:f]; t.placeholder=p; t.secureTextEntry=sec;
    t.backgroundColor=MCARD; t.layer.cornerRadius=10; t.layer.borderWidth=0.5; t.layer.borderColor=MLINE.CGColor;
    t.font=[UIFont systemFontOfSize:16]; t.autocapitalizationType=UITextAutocapitalizationTypeNone; t.autocorrectionType=UITextAutocorrectionTypeNo;
    t.delegate=self; t.returnKeyType=UIReturnKeyNext;
    UIView*pad=[[UIView alloc] initWithFrame:CGRectMake(0,0,12,f.size.height)]; t.leftView=pad; t.leftViewMode=UITextFieldViewModeAlways;
    [self.view addSubview:t]; return t;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; self.view.backgroundColor=MBG;
    CGFloat W=self.view.bounds.size.width;
    UILabel*title=[[UILabel alloc] initWithFrame:CGRectMake(0,64,W,40)]; title.text=@"Matrix"; title.font=[UIFont boldSystemFontOfSize:34]; title.textColor=MINK; title.textAlignment=NSTextAlignmentCenter; title.backgroundColor=[UIColor clearColor]; [self.view addSubview:title];
    _seg=[[UISegmentedControl alloc] initWithItems:@[L(@"Sign In"),L(@"Register")]]; _seg.frame=CGRectMake(20,104,W-40,34); _seg.selectedSegmentIndex=0; _seg.tintColor=MGRN; [_seg addTarget:self action:@selector(segChanged) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:_seg];

    _hs=[self field:CGRectMake(20,150,W-40,46) placeholder:L(@"Homeserver (matrix.org)") secure:NO]; _hs.text=@"matrix.org"; _hs.keyboardType=UIKeyboardTypeURL;
    _user=[self field:CGRectMake(20,204,W-40,46) placeholder:L(@"Username (e.g. alice)") secure:NO];
    _pw=[self field:CGRectMake(20,258,W-40,46) placeholder:L(@"Password") secure:YES]; _pw.returnKeyType=UIReturnKeyGo;

    _btn=[UIButton buttonWithType:UIButtonTypeCustom]; _btn.frame=CGRectMake(20,322,W-40,48); _btn.backgroundColor=MGRN; _btn.layer.cornerRadius=12;
    [_btn setTitle:L(@"Sign In") forState:UIControlStateNormal]; [_btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; _btn.titleLabel.font=[UIFont boldSystemFontOfSize:17];
    [_btn addTarget:self action:@selector(submit) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:_btn];
    _spin=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]; _spin.frame=_btn.bounds; _spin.hidesWhenStopped=YES; [_btn addSubview:_spin];

    _err=[[UILabel alloc] initWithFrame:CGRectMake(20,382,W-40,40)]; _err.numberOfLines=2; _err.font=[UIFont systemFontOfSize:13]; _err.textColor=MXC(255,59,48); _err.textAlignment=NSTextAlignmentCenter; _err.backgroundColor=[UIColor clearColor]; [self.view addSubview:_err];

    UITapGestureRecognizer*t=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKb)]; t.cancelsTouchesInView=NO; [self.view addGestureRecognizer:t];
}
- (void)dismissKb { [self.view endEditing:YES]; }
- (BOOL)textFieldShouldReturn:(UITextField *)tf { if(tf==_hs)[_user becomeFirstResponder]; else if(tf==_user)[_pw becomeFirstResponder]; else { [tf resignFirstResponder]; [self submit]; } return YES; }

- (void)segChanged { _mode=_seg.selectedSegmentIndex; [_btn setTitle:(_mode?L(@"Register"):L(@"Sign In")) forState:UIControlStateNormal]; _err.text=@""; }
- (void)submit {
    [self.view endEditing:YES];
    if(!_user.text.length || !_pw.text.length){ _err.text=L(@"Enter username and password"); return; }
    _err.text=@""; [_spin startAnimating]; [_btn setTitle:@"" forState:UIControlStateNormal]; _btn.enabled=NO;
    void(^fin)(BOOL,NSString*)=^(BOOL ok,NSString*e){
        [_spin stopAnimating]; [_btn setTitle:(_mode?L(@"Register"):L(@"Sign In")) forState:UIControlStateNormal]; _btn.enabled=YES;
        if(ok){ [MXClient startSync]; [self.navigationController setViewControllers:@[[[MXRoomsController alloc] init]] animated:YES]; }
        else _err.text=e?:L(@"Failed");
    };
    if(_mode) [MXClient registerUser:_user.text password:_pw.text homeserver:_hs.text completion:fin];
    else [MXClient loginUser:_user.text password:_pw.text homeserver:_hs.text completion:fin];
}
@end
