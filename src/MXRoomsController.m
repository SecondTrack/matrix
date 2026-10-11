#import "MXTheme.h"
#import "MXClient.h"
#import "MeshL10n.h"

@interface MXChatController : UIViewController
@property(nonatomic,strong) NSString *roomId;
@property(nonatomic,strong) NSString *roomName;
@end
@interface MXLoginController : UIViewController @end

@interface MXRoomsController : UIViewController <UITableViewDataSource, UITableViewDelegate> @end
@implementation MXRoomsController {
    UITableView *_tv; NSArray *_rooms;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; self.view.backgroundColor=MBG;
    self.title=L(@"Chats");
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:L(@"Sign Out") style:UIBarButtonItemStylePlain target:self action:@selector(logout)];
    _tv=[[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tv.dataSource=self; _tv.delegate=self; _tv.backgroundColor=MBG; _tv.rowHeight=64;
    [self.view addSubview:_tv];
}
- (void)viewDidLoad { [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:MXSyncUpdated object:nil];
    [MXClient startSync];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self reload]; }
- (void)reload { _rooms=[MXClient rooms]; [_tv reloadData]; }
- (void)logout { [MXClient logout]; [self.navigationController setViewControllers:@[[[MXLoginController alloc] init]] animated:YES]; }

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return _rooms.count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell*c=[t dequeueReusableCellWithIdentifier:@"r"];
    if(!c) c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"r"];
    NSDictionary*r=_rooms[ip.row];
    c.textLabel.text=r[@"name"]; c.textLabel.font=[UIFont boldSystemFontOfSize:16];
    c.detailTextLabel.text=r[@"last"]?:@""; c.detailTextLabel.textColor=MMUT; c.detailTextLabel.font=[UIFont systemFontOfSize:13];
    c.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [t deselectRowAtIndexPath:ip animated:YES];
    NSDictionary*r=_rooms[ip.row];
    MXChatController*cc=[[MXChatController alloc] init]; cc.roomId=r[@"id"]; cc.roomName=r[@"name"];
    [self.navigationController pushViewController:cc animated:YES];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
@end
