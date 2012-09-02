//
//  MySCNView.m
//  SceneKitPreloadTest
//
//  Created by Jonathon Mah on 2012-09-01.
//  Copyright (c) 2012 Delicious Monster Software. All rights reserved.
//

#import "MySCNView.h"


@implementation MySCNView
{
    NSOpenGLContext *_preloadContext;
    SCNRenderer *_preloadRenderer;
    SCNGeometry *_preloadPlane;
}

- (id)initWithCoder:(NSCoder *)decoder;
{
    if (!(self = [super initWithCoder:decoder]))
        return nil;

    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersionLegacy, // required for Scene Kit at the moment (sad?)

        // From +[SCNView defaultPixelFormatWithSampleCount:] on 10.8 (12A269)
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFASampleBuffers, 1,
        NSOpenGLPFASamples, 4, // Sample count parameter
        NSOpenGLPFAAccelerated,

        // Extras
        NSOpenGLPFAAllowOfflineRenderers,
        0
    };
    self.pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    return self;
}

- (void)preparePreloadStuff;
{
    if (_preloadRenderer)
        return;

    NSParameterAssert(self.openGLContext);
    _preloadContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat shareContext:self.openGLContext];
    [_preloadContext makeCurrentContext];
    //glViewport(0, 0, 100, 100);
    //GLuint fbo;
    //glGenFramebuffers(1, &fbo); NSLog(@"Created framebuffer id %u", fbo);
    //glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    _preloadRenderer = [SCNRenderer rendererWithContext:_preloadContext.CGLContextObj options:nil];
    _preloadRenderer.scene = [SCNScene scene];

    _preloadPlane = [SCNPlane planeWithWidth:1.0 height:1.0];
    [_preloadRenderer.scene.rootNode addChildNode:[SCNNode nodeWithGeometry:_preloadPlane]];
}

- (void)preloadMaterial:(SCNMaterial *)material;
{
    [self preparePreloadStuff];

    _preloadPlane.firstMaterial = material;
    [SCNTransaction flush];

    //[_preloadContext makeCurrentContext];
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [_preloadRenderer render];
    //glFlush();
}


@end
