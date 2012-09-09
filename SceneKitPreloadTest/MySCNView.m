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
    dispatch_once_t _preloadQueueOnceToken;
    dispatch_queue_t _preloadQueue;
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

- (void)setOpenGLContext:(NSOpenGLContext *)openGLContext;
{
    [super setOpenGLContext:openGLContext];
    if (!_preloadQueue)
        return;
    dispatch_async(_preloadQueue, ^{
        // Must regenerate additional context to share with this new one
        _preloadRenderer = nil;
        _preloadPlane = nil;
    });
}

- (void)preloadMaterial:(SCNMaterial *)material;
{
    dispatch_once(&_preloadQueueOnceToken, ^{
        _preloadQueue = dispatch_queue_create("com.delicious-monster.SceneKitPreload", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), _preloadQueue);
    });

    dispatch_sync(_preloadQueue, ^{
        if (!self.openGLContext)
            return; // Too soon, can't preload yet
        if (!_preloadRenderer)
            [self setUpPreloadRenderer];

        NSArray *const defaultMaterials = _preloadPlane.materials;
        _preloadPlane.materials = @[material];
        [SCNTransaction flush];

        const CGLContextObj mainContext = self.context;
        GLint mainContextVirtualScreen;
        // TODO: Handle error return values, perhaps.
        CGLLockContext(mainContext);
        CGLGetVirtualScreen(mainContext, &mainContextVirtualScreen);
        CGLUnlockContext(mainContext);

        CGLSetVirtualScreen(_preloadRenderer.context, mainContextVirtualScreen);
        [_preloadRenderer render];
        CGLSetCurrentContext(_preloadRenderer.context);
        glFlush(); // Without this, textures can get corrupted, sometimes.
        _preloadPlane.materials = defaultMaterials; // Don't retain material
    });
}
- (void)setUpPreloadRenderer;
{
    NSParameterAssert(self.openGLContext);
    NSOpenGLContext *preloadContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat shareContext:self.openGLContext];

    _preloadRenderer = [SCNRenderer rendererWithContext:preloadContext.CGLContextObj options:nil];
    _preloadRenderer.scene = [SCNScene scene];

    _preloadPlane = [SCNPlane planeWithWidth:1.0 height:1.0];
    [_preloadRenderer.scene.rootNode addChildNode:[SCNNode nodeWithGeometry:_preloadPlane]];
}

@end
