//
//  OneSignalHelper.mm
//  Kepler
//
//  Helper to initialize OneSignal from C++ code
//

#import <Foundation/Foundation.h>
#import <OneSignalFramework/OneSignalFramework.h>

#ifdef __cplusplus
extern "C" {
#endif

void initializeOneSignal(const char* appId) {
    NSString *appIdString = [NSString stringWithUTF8String:appId];

    // Initialize OneSignal
    [OneSignal initialize:appIdString withLaunchOptions:nil];

    // Request notification permission
    [OneSignal.Notifications requestPermission:^(BOOL accepted) {
        NSLog(@"User accepted notifications: %d", accepted);
    } fallbackToSettings:NO];
}

#ifdef __cplusplus
}
#endif
