//
//  ExternalDisplayHelper.mm
//  Kepler
//
//  Helper to show AirPlay picker from C++ code
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

static UIWindow* externalWindow = nil;

#ifdef __cplusplus
extern "C" {
#endif

void showAirPlayPicker(void* parentView, float x, float y, float width, float height) {
    UIView* view = (__bridge UIView*)parentView;
    
    NSLog(@"Showing AirPlay instructions");

    // Show an alert with instructions since we can't programmatically trigger screen mirroring
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Screen Mirroring"
                                                                   message:@"To mirror your display via AirPlay:\n\n1. Swipe down from the top-right corner to open Control Center\n2. Tap the Screen Mirroring button\n3. Select your AirPlay device"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    // Get the root view controller to present the alert
    UIViewController* rootVC = nil;
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        if (window.rootViewController) {
            rootVC = window.rootViewController;
            break;
        }
    }
    
    if (rootVC) {
        [rootVC presentViewController:alert animated:YES completion:nil];
    } else {
        NSLog(@"Could not find root view controller to present alert");
    }
}

bool hasExternalDisplay(void) {
    return UIScreen.screens.count > 1;
}

#ifdef __cplusplus
}
#endif
