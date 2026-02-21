//
//  ExternalDisplayHelper.mm
//  Kepler
//
//  Helper for external display and AirPlay support
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#import "ExternalDisplayHelper.h"

// Custom UIView subclass that uses CAEAGLLayer
@interface EAGLView : UIView
@end

@implementation EAGLView
+ (Class)layerClass {
    return [CAEAGLLayer class];
}
@end

// External display state
static UIWindow* externalWindow = nil;
static EAGLView* externalGLView = nil;
static EAGLContext* externalContext = nil;
static GLuint externalFramebuffer = 0;
static GLuint externalRenderbuffer = 0;
static GLuint externalDepthbuffer = 0;
static ExternalDisplayCallback displayCallback = NULL;
static void* callbackUserData = NULL;

// Forward declarations
static void setupExternalDisplay(UIScreen* screen);
static void teardownExternalDisplay(void);
static void screenDidConnect(NSNotification* notification);
static void screenDidDisconnect(NSNotification* notification);

#ifdef __cplusplus
extern "C" {
#endif

void showAirPlayPicker(void* parentView, float x, float y, float width, float height) {
    UIView* view = (__bridge UIView*)parentView;
    
    NSLog(@"Showing AirPlay instructions");

    // Show an alert with instructions
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Screen Mirroring"
                                                                   message:@"To use external display via AirPlay:\n\n1. Swipe down from the top-right corner to open Control Center\n2. Tap the Screen Mirroring button\n3. Select your AirPlay device\n\nThe 3D visualization will automatically appear on the external display!"
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
    return externalWindow != nil && UIScreen.screens.count > 1;
}

void initExternalDisplayMonitoring(ExternalDisplayCallback callback, void* userData) {
    displayCallback = callback;
    callbackUserData = userData;
    
    // Register for screen connection/disconnection notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification* note) {
        screenDidConnect(note);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidDisconnectNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification* note) {
        screenDidDisconnect(note);
    }];
    
    // Check if external screen is already connected
    if (UIScreen.screens.count > 1) {
        UIScreen* externalScreen = UIScreen.screens[1];
        setupExternalDisplay(externalScreen);
    }
    
    NSLog(@"External display monitoring initialized");
}

unsigned int getExternalDisplayFramebuffer(void) {
    return externalFramebuffer;
}

void getExternalDisplaySize(float* width, float* height) {
    if (externalWindow && width && height) {
        CGRect bounds = externalWindow.bounds;
        *width = bounds.size.width;
        *height = bounds.size.height;
    } else if (width && height) {
        *width = 0;
        *height = 0;
    }
}

void beginExternalDisplayRendering(void) {
    if (!externalContext || externalFramebuffer == 0) {
        return;
    }
    
    // Switch to external context
    [EAGLContext setCurrentContext:externalContext];
    
    // Bind external framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, externalFramebuffer);
    
    // Set viewport
    float width, height;
    getExternalDisplaySize(&width, &height);
    glViewport(0, 0, (GLint)width, (GLint)height);
}

void endExternalDisplayRendering(void) {
    if (!externalContext || externalRenderbuffer == 0) {
        return;
    }
    
    // Bind the renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, externalRenderbuffer);
    
    // Present the renderbuffer
    [externalContext presentRenderbuffer:GL_RENDERBUFFER];
    
    NSLog(@"Presented external display renderbuffer");
}

void* getMainGLContext(void) {
    return (__bridge void*)[EAGLContext currentContext];
}

void restoreMainGLContext(void* mainContext) {
    if (mainContext) {
        EAGLContext* ctx = (__bridge EAGLContext*)mainContext;
        [EAGLContext setCurrentContext:ctx];
    }
}

void cleanupExternalDisplay(void) {
    teardownExternalDisplay();
    [[NSNotificationCenter defaultCenter] removeObserver:nil name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:nil name:UIScreenDidDisconnectNotification object:nil];
}

#ifdef __cplusplus
}
#endif
// MARK: - Internal Implementation

static void screenDidConnect(NSNotification* notification) {
    UIScreen* newScreen = notification.object;
    NSLog(@"External screen connected: %@ (%fx%f)", newScreen, newScreen.bounds.size.width, newScreen.bounds.size.height);
    setupExternalDisplay(newScreen);
}

static void screenDidDisconnect(NSNotification* notification) {
    NSLog(@"External screen disconnected");
    teardownExternalDisplay();
}

static void setupExternalDisplay(UIScreen* screen) {
    if (externalWindow) {
        NSLog(@"External display already set up");
        return;
    }
    
    // Create window for external screen
    externalWindow = [[UIWindow alloc] initWithFrame:screen.bounds];
    externalWindow.screen = screen;
    
    // Create OpenGL view with EAGLView (which has CAEAGLLayer)
    externalGLView = [[EAGLView alloc] initWithFrame:screen.bounds];
    externalGLView.opaque = YES;
    externalGLView.backgroundColor = [UIColor blackColor];
    
    // Get the EAGL layer
    CAEAGLLayer* eaglLayer = (CAEAGLLayer*)externalGLView.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking: @NO,
        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
    };
    
    // Create OpenGL ES context (share with main context if possible)
    EAGLContext* mainContext = [EAGLContext currentContext];
    if (mainContext) {
        externalContext = [[EAGLContext alloc] initWithAPI:mainContext.API sharegroup:mainContext.sharegroup];
    } else {
        externalContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    if (!externalContext) {
        NSLog(@"Failed to create external OpenGL context");
        externalWindow = nil;
        externalGLView = nil;
        return;
    }
    
    // Make external context current to create framebuffers
    EAGLContext* previousContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:externalContext];
    
    // Create framebuffer
    glGenFramebuffers(1, &externalFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, externalFramebuffer);
    
    // Create color renderbuffer
    glGenRenderbuffers(1, &externalRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, externalRenderbuffer);
    [externalContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, externalRenderbuffer);
    
    // Get renderbuffer size
    GLint width, height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    // Create depth renderbuffer
    glGenRenderbuffers(1, &externalDepthbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, externalDepthbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, externalDepthbuffer);
    
    // Check framebuffer status
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to create external framebuffer: %x", status);
        teardownExternalDisplay();
        [EAGLContext setCurrentContext:previousContext];
        return;
    }
    
    NSLog(@"External framebuffer created: %dx%d (FBO: %d)", width, height, externalFramebuffer);
    
    // Restore previous context
    [EAGLContext setCurrentContext:previousContext];
    
    // Add view to window and show
    [externalWindow addSubview:externalGLView];
    externalWindow.hidden = NO;
    
    // Notify callback
    if (displayCallback) {
        displayCallback(true, callbackUserData);
    }
    
    NSLog(@"External display setup complete");
}

static void teardownExternalDisplay(void) {
    if (!externalWindow) {
        return;
    }
    
    // Make external context current for cleanup
    EAGLContext* previousContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:externalContext];
    
    // Delete framebuffers
    if (externalFramebuffer) {
        glDeleteFramebuffers(1, &externalFramebuffer);
        externalFramebuffer = 0;
    }
    if (externalRenderbuffer) {
        glDeleteRenderbuffers(1, &externalRenderbuffer);
        externalRenderbuffer = 0;
    }
    if (externalDepthbuffer) {
        glDeleteRenderbuffers(1, &externalDepthbuffer);
        externalDepthbuffer = 0;
    }
    
    // Restore previous context
    [EAGLContext setCurrentContext:previousContext];
    
    // Clean up window
    externalWindow.hidden = YES;
    externalWindow = nil;
    externalGLView = nil;
    externalContext = nil;
    
    // Notify callback
    if (displayCallback) {
        displayCallback(false, callbackUserData);
    }
    
    NSLog(@"External display torn down");
}

