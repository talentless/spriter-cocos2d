//
//  HelloWorldLayer.m
//  Spriter
//
//  Created by Salvatore Gionfriddo on 4/17/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#import "TGSpriterNode.h"

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init])) {
        TGSpriterNode * n = [TGSpriterNode spriterNodeWithFiles:@"BetaFormatHero.SCML"];
        n.position = ccp(120,100);
        //[n showFrame:@"idle_healthy_0"];
        
        [n runAnimation:@"idle_healthy"];
        
        [self addChild:n];
        
        n = [TGSpriterNode spriterNodeWithFiles:@"BetaFormatHero.SCML"];
        n.position = ccp(360,100);
        //[n showFrame:@"idle_healthy_0"];
        
        [n runAnimation:@"walk"];
        
        [self addChild:n];
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
