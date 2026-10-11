#import "MXTheme.h"
#import "MXClient.h"

@interface MXLoginController : UIViewController @end
@interface MXRoomsController : UIViewController @end

@interface MXAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation MXAppDelegate
- (BOOL)application:(UIApplication *)a didFinishLaunchingWithOptions:(NSDictionary *)o {
    [a setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    [MXClient loadSaved];
    self.window=[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIViewController*root=[MXClient isLoggedIn]?[[MXRoomsController alloc] init]:[[MXLoginController alloc] init];
    UINavigationController*nav=[[UINavigationController alloc] initWithRootViewController:root];
    [nav.navigationBar setBackgroundImage:MXSolid(MGRN) forBarMetrics:UIBarMetricsDefault];
    [nav.navigationBar setShadowImage:MXSolid([UIColor colorWithWhite:0 alpha:0.12])];
    nav.navigationBar.tintColor=[UIColor whiteColor];
    nav.navigationBar.titleTextAttributes=@{ UITextAttributeTextColor:[UIColor whiteColor],
                                             UITextAttributeTextShadowColor:[UIColor clearColor],
                                             UITextAttributeFont:[UIFont boldSystemFontOfSize:18] };
    self.window.rootViewController=nav;
    [self.window makeKeyAndVisible];
    if([MXClient isLoggedIn]) [MXClient startSync];
    return YES;
}
@end
