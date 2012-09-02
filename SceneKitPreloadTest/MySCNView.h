//
//  MySCNView.h
//  SceneKitPreloadTest
//
//  Created by Jonathon Mah on 2012-09-01.
//  Copyright (c) 2012 Delicious Monster Software. All rights reserved.
//

#import <SceneKit/SceneKit.h>


@interface MySCNView : SCNView

- (void)preloadMaterial:(SCNMaterial *)material;

@end
