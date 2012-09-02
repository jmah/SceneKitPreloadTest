//
//  MyAppDelegate.m
//  SceneKitPreloadTest
//
//  Created by Jonathon Mah on 2012-09-01.
//  Copyright (c) 2012 Delicious Monster Software. All rights reserved.
//

#import "MyAppDelegate.h"
#import <SceneKit/SceneKit.h>
#import "MySCNView.h"


@implementation MyAppDelegate
{
    SCNBox *_box;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
    SCNScene *scene = [SCNScene scene];
    _box = [SCNBox boxWithWidth:1.0 height:1.0 length:1.0 chamferRadius:0.0];
    [self resetMaterials:nil];
    SCNNode *boxNode = [SCNNode nodeWithGeometry:_box];
    [scene.rootNode addChildNode:boxNode];
    self.sceneView.scene = scene;

    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"rotation"];
    rotateAnimation.duration = 8.0;
    rotateAnimation.fromValue = [NSValue valueWithSCNVector4:SCNVector4Make(0.2, 0.3, 0.4, 0.0)];
    rotateAnimation.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(0.2, 0.3, 0.4, M_PI * 2.0)];
    rotateAnimation.repeatCount = HUGE_VALF;
    [boxNode addAnimation:rotateAnimation forKey:@"tumble"];
}

- (NSArray *)generateBoxMaterials;
{
    NSLog(@"---- New materials ----");
    NSMutableArray *boxMaterials = [NSMutableArray arrayWithCapacity:6];
    NSImage *baseImage = [NSImage imageNamed:@"IMG_2923"];
    for (NSUInteger i = 0; i < 6; i++) {
        SCNMaterial *m = [SCNMaterial material];
        m.diffuse.contents = [baseImage copy]; // new instance so existing cache not used
        m.diffuse.mipFilter = SCNLinearFiltering;
        m.diffuse.minificationFilter = SCNLinearFiltering;
        m.diffuse.magnificationFilter = SCNLinearFiltering;
        [boxMaterials addObject:m];
    }
    return boxMaterials;
}

- (IBAction)resetMaterials:(id)sender;
{
    SCNMaterial *m = [SCNMaterial material];
    m.diffuse.contents = [NSColor greenColor];
    _box.materials = @[m];
}

- (IBAction)changeBoxMaterial:(id)sender;
{
    [self resetMaterials:nil];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            NSArray *boxMaterials = [self generateBoxMaterials];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSDate *startDate = [NSDate date];
                _box.materials = boxMaterials;
                [SCNTransaction flush];

                [self.sceneView.layer display];
                NSLog(@"%.3fs to change sync", -startDate.timeIntervalSinceNow);
            });
        }
    });

}

- (IBAction)prepareThenChangeBoxMaterial:(id)sender;
{
    [self resetMaterials:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @autoreleasepool {
            NSArray *boxMaterials = [self generateBoxMaterials];
            for (SCNMaterial *m in boxMaterials)
                [self.sceneView preloadMaterial:m];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDate *startDate = [NSDate date];
                _box.materials = boxMaterials;
                [SCNTransaction flush];
                [self.sceneView.layer display];
                NSLog(@"%.3fs to change async", -startDate.timeIntervalSinceNow);
            });
        }
    });
}

@end