//
//  ExternalDisplayHelper.h
//  Kepler
//
//  Helper to show AirPlay picker from C++ code
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Show the system AirPlay picker at the specified location
void showAirPlayPicker(void* parentView, float x, float y, float width, float height);

// Check if external display is connected
bool hasExternalDisplay(void);

#ifdef __cplusplus
}
#endif
