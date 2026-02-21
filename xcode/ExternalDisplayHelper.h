//
//  ExternalDisplayHelper.h
//  Kepler
//
//  Helper for external display and AirPlay support
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Callback function type for external display events
typedef void (*ExternalDisplayCallback)(bool connected, void* userData);

// Show the system AirPlay picker (shows instructions alert)
void showAirPlayPicker(void* parentView, float x, float y, float width, float height);

// Check if external display is currently connected
bool hasExternalDisplay(void);

// Initialize external display monitoring with callback
void initExternalDisplayMonitoring(ExternalDisplayCallback callback, void* userData);

// Get the external display's OpenGL framebuffer (returns 0 if none)
unsigned int getExternalDisplayFramebuffer(void);

// Get external display resolution
void getExternalDisplaySize(float* width, float* height);

// Prepare external display for rendering (switches context, binds FBO)
void beginExternalDisplayRendering(void);

// Finish external display rendering (presents, does NOT restore context - caller must do that)
void endExternalDisplayRendering(void);

// Get the main app's OpenGL context (to restore after external rendering)
void* getMainGLContext(void);

// Restore the main app's OpenGL context
void restoreMainGLContext(void* mainContext);

// Cleanup external display resources
void cleanupExternalDisplay(void);

#ifdef __cplusplus
}
#endif
