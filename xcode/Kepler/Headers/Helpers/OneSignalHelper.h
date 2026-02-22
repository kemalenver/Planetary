//
//  OneSignalHelper.h
//  Kepler
//
//  Helper to initialize OneSignal from C++ code
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void initializeOneSignal(const char* appId);
void requestOneSignalPermission();

#ifdef __cplusplus
}
#endif
