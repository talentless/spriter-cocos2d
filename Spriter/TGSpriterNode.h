//
//  TGSpriterNode.h
//  Spriter
//
//  Created by Salvatore Gionfriddo on 4/17/12.
//  Copyright 2012 Taco Graveyard. All rights reserved.
//

/*
 Notes:
 
 1.) WARNING
 
 This is a fast and dirty implementation based on the spec for the BETA version (V2).
 This code will change as features are added to the beta build.
 
 2.) NSXMLParser
 
 The NSXMLParser is used to avoid introducing addition project dependencies. NSXMLParser
 is slow and I would rather use a DOM parser than a SAX parser, but I felt like introducing
 was additional dependcies was important to avoid. If this ends up in cocos2d proper and
 they wish to use a faster parser, then a lot of the parsing code included can be cleaned up.
 
 This isn't the cleanest parsing implementation. I'm building up a simple tree as the
 SAX parser runs its course, and then I use that tree to build up animations and frames.
 
 3.) TGSpriterNode without a sprite sheet
 
 Since I only use this as part of a batch node, that is the only method I am supporting at the
 moment. At some point I will add support back in for using this node with out a sprite sheet.
 I also plan on adding a method for batching the drawing of this node with other TGSpriterNodes
 using the same sprite sheet. Reduce draw calls for the win!
 
 */

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface TGSpriterConfigNode : NSObject {
    NSString * name_;
    TGSpriterConfigNode * parent_;
    NSMutableArray * children_;
    NSString * value_;
    NSMutableDictionary * properties_;
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) TGSpriterConfigNode * parent;
@property (nonatomic, retain) NSMutableArray * children;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSMutableDictionary * properties;

+(id) configNode:(NSString*)name;

@end

#pragma mark -

@interface TGSpriterObjectRef : NSObject {
    int timelineId_;
    int timelineKey_;
}

@property int timelineId;
@property int timelineKey;

+(id) spriterObjectRef;

@end

@interface TGSpriterMainlineKey : NSObject {
    NSMutableArray * objectRefs_;
    double startsAt_;
}

@property (nonatomic, readonly) NSMutableArray * objectRefs;
@property double startsAt;

+(id) spriterFrame;
-(void) addObjectRef:(TGSpriterObjectRef*)sprite;

@end

@interface TGSpriterTimelineKey : NSObject {
    int file_;
    int folder_;
    
    double startsAt_;
    
    CGPoint position_;
    CGPoint anchorPoint_;
    double rotation_;
    int spin_;
    double scaleX_;
    double scaleY_;
}

@property int file;
@property int folder;
@property double startsAt;
@property CGPoint position;
@property CGPoint anchorPoint;
@property double rotation;
@property int spin;
@property double scaleX;
@property double scaleY;

+(id) spriterTimelineKey;

@end

@interface TGSpriterTimeline : NSObject {
    NSMutableArray * keys_;
}
@property (nonatomic, readonly) NSMutableArray * keys;
+(id) spriterTimeline;
-(void) addKeyFrame:(TGSpriterTimelineKey*)frame;

@end

// holds the frames for a given animation
@interface TGSpriterAnimation : NSObject {
    NSString * name_;
    
    NSMutableArray * mainline_;
    NSMutableArray * timelines_;
    double duration_;
    
    int nodes_;
}

@property (nonatomic, readonly) NSMutableArray * mainline;
@property (nonatomic, readonly) NSMutableArray * timelines;

@property (nonatomic, retain) NSString * name;
@property double duration;

+(id) spriterAnimation;
-(void) addKeyFrame:(TGSpriterMainlineKey*)frame;
-(void) addTimeline:(TGSpriterTimeline*)timeline;

@end

@interface TGSpriterSprite : CCSprite {
    int folder;
    int file;
    NSString * displayFrameName;
}
@property int folder;
@property int file;
@property (nonatomic, retain) NSString * displayFrameName;

@end

#pragma mark -
#pragma mark The Important Stuff

/*
 This is the actual node you should use.
 */
@interface TGSpriterNode : CCNode <NSXMLParserDelegate> {
    NSXMLParser * parser_;
    
    NSString * characterName_;
    NSMutableDictionary * animations_;
    NSMutableDictionary * frames_;
    
    int * folderIndexes_;
    int * flattenedFolder_;
    NSMutableArray * files_; // an array of arrays, much faster access time [O(1)] than a dict lookup
    
    TGSpriterAnimation * curAnimation_;
    TGSpriterMainlineKey * curKeyFrame_;
    TGSpriterMainlineKey * nextKeyFrame_;
    double duration_;
    int frameIdx_;
    
    NSMutableArray * spriterNodes_;
    
    // batch node use
    CCSpriteBatchNode * batchNode_;
    BOOL useBatchNode_;
    
    // parsing vars
    TGSpriterConfigNode * configRoot_;
    TGSpriterConfigNode * curConfigNode_;
    
    // vars for manipulating scml positions to match game world scale and coords
    double sdScale_;
    CGPoint offset_;
    
    BOOL smoothTransitions_;
    TGSpriterAnimation * prevAnimation_;
    
    double playbackSpeed_;
    BOOL smoothTransitions;
}

/*
 smoothTransitions is an experimental property for smoothly moving to a new animation when
 runAnimation is called in the middle of another animation. This does not work properly at
 this time, but it is something I plan on looking into again
 */
@property BOOL smoothTransitions;
@property double playbackSpeed; // defaults to 1, allows you to play the animation faster or slower

+(id) spriterNodeWithFiles:(NSString *)scmlFile spriteSheet:(NSString*)spriteSheet;

// sdScale defaults to 0.5, it assumes that the Spriter assets were made with retina sized assets
// offset lets you correct for spriter animations that were not assembled in the center of the viewport
+(id) spriterNodeWithFiles:(NSString *)scmlFile spriteSheet:(NSString*)spriteSheet sdScale:(double)sdScale offset:(CGPoint)offse;
-(id) initNodeWithFiles:(NSString*)scmlFile spriteSheet:(NSString*)spriteSheet sdScale:(double)sdScale offset:(CGPoint)offset;

// call this to run an animation
-(void) runAnimation:(NSString*)animation;

// hooks for classes that override this for custom behavior
// should we be message passing to a delegate instead?
-(BOOL) animationEnded;
-(void) animationFrameChanged;

@end