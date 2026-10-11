#import <UIKit/UIKit.h>
static inline UIColor* MXC(int r,int g,int b){ return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]; }
#define MBG   MXC(242,242,247)
#define MCARD [UIColor whiteColor]
#define MINK  MXC(0,0,0)
#define MMUT  MXC(142,142,147)
#define MLINE MXC(209,209,214)
#define MTRACK MXC(233,233,238)
#define MGRN  MXC(13,189,139)
static inline UIImage* MXSolid(UIColor*c){
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1,1),YES,0); [c setFill]; UIRectFill(CGRectMake(0,0,1,1));
    UIImage*i=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return i;
}
