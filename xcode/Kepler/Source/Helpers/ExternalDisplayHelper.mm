//
//  ExternalDisplayHelper.mm
//  Kepler
//
//  Helper to show AirPlay picker from C++ code
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVKit/AVRoutePickerView.h>

#ifdef __cplusplus
extern "C" {
#endif

void showAirPlayPicker(void* parentView, float x, float y, float width, float height) {
    UIView* view = (__bridge UIView*)parentView;

    // Create AVRoutePickerView at the specified location
    CGRect rect = CGRectMake(x, y, width, height);
    AVRoutePickerView* routePickerView = [[AVRoutePickerView alloc] initWithFrame:rect];
    routePickerView.activeTintColor = [UIColor whiteColor];
    routePickerView.tintColor = [UIColor lightGrayColor];

    // Add to parent view
    [view addSubview:routePickerView];

    // Programmatically trigger the picker button
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (UIView* subview in routePickerView.subviews) {
            if ([subview isKindOfClass:[UIButton class]]) {
                [(UIButton*)subview sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            }
        }

        // Remove the view after a delay to clean up
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [routePickerView removeFromSuperview];
        });
    });
}

bool hasExternalDisplay(void) {
    return UIScreen.screens.count > 1;
}

#ifdef __cplusplus
}
#endif
