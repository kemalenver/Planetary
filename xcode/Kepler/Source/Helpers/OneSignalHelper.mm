//
//  OneSignalHelper.mm
//  Kepler
//
//  Helper to initialize OneSignal from C++ code
//  Following official OneSignal iOS SDK integration guidelines
//

#import <Foundation/Foundation.h>
#import <OneSignalFramework/OneSignalFramework.h>

#ifdef __cplusplus
extern "C" {
#endif

static BOOL oneSignalInitialized = NO;
static NSString *oneSignalAppId = nil;

void initializeOneSignal(const char* appId) {
    NSString *appIdString = [NSString stringWithUTF8String:appId];
    oneSignalAppId = appIdString;

    NSLog(@"OneSignal: Initializing with app ID: %@", appIdString);

    // Initialize OneSignal SDK
    // As per OneSignal guidelines, initialize should be called as early as possible
    // We're initializing after app launch is complete for this specific app architecture
    [OneSignal initialize:appIdString withLaunchOptions:nil];

    NSLog(@"OneSignal: Initialization complete");
    oneSignalInitialized = YES;
}

void requestOneSignalPermission() {
    if (!oneSignalInitialized) {
        NSLog(@"OneSignal: ERROR - Cannot request permission before initialization");
        return;
    }

    NSLog(@"OneSignal: Requesting notification permission...");

    // Request notification permission with fallback to settings
    // fallbackToSettings:YES will show a prompt to open Settings if permission was previously denied
    [OneSignal.Notifications requestPermission:^(BOOL accepted) {
        NSLog(@"OneSignal: Permission result - User %@ notifications", accepted ? @"accepted" : @"declined");

        if (accepted) {
            // Log subscription details after successful permission grant
            NSLog(@"OneSignal: Push notifications enabled successfully");
        } else {
            NSLog(@"OneSignal: Push notifications declined - User can enable in Settings app");
        }
    } fallbackToSettings:YES];
}

#ifdef __cplusplus
}
#endif
