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
 
 This is a fast and dirty implementation based on the spec for the BETA version. The spec
 WILL change with the development of Spriter 1.0 and this code will change with it. This
 code should be considered high unstable until the release of 1.0.
 
 2.) NSXMLParser
 
 The NSXMLParser is used to avoid introducing addition project dependencies. NSXMLParser
 is slow and I would rather use a DOM parser than a SAX parser, but I felt like introducing
 was additional dependcies was important to avoid. If this ends up in cocos2d proper and
 they wish to use a faster parser, then a lot of the parsing code included can be cleaned up.
 
 This isn't the cleanest parsing implementation. I building up a simple tree as the
 SAX parser runs its course, and then I use that tree to build up animations and frames.
 
 3.) Tweening
 
 Tweening isn't in the beta spec.
 
 
*/

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface TGSpriterConfigNode : NSObject {
    NSString * name_;
    TGSpriterConfigNode * parent_;
    NSMutableArray * children_;
    NSString * value_;
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) TGSpriterConfigNode * parent;
@property (nonatomic, retain) NSMutableArray * children;
@property (nonatomic, retain) NSString * value;

+(id) configNode:(NSString*)name;

@end

// holds the sprites associated with a given frame
@interface TGSpriterFrame : NSObject {
    NSMutableArray * sprites_;
}

+(id) spriterFrame;
-(void) addSprite:(CCSprite*)sprite;
-(void) setVisible:(BOOL)visible;

@end

// holds the frames for a given animation
@interface TGSpriterAnimation : NSObject {
    NSMutableArray * frames_;
    NSMutableArray * frameDurations_;
    int frameIdx_;
    double frameDuration_;
}

+(id) spriterAnimation;
-(void) addFrame:(TGSpriterFrame*)frame duration:(double)duration;
-(void) hide;
-(void)update:(ccTime)dt;

@end

@interface TGSpriterNode : CCNode <NSXMLParserDelegate> {
    NSXMLParser * parser_;
    
    NSString * characterName_;
    NSMutableDictionary * animations_; // {name: TGSpriterAnimation,...}
    NSMutableDictionary * frames_; // {name: TGSpriterFrame,..}
    
    TGSpriterAnimation * curAnimation_;
    
    // batch node use
    CCSpriteBatchNode * batchNode_;
    BOOL useBatchNode_;
    
    // parsing vars
    TGSpriterConfigNode * configRoot_;
    TGSpriterConfigNode * curConfigNode_;
}

+(id) spriterNodeWithFiles:(NSString*)scmlFile;
+(id) spriterNodeWithFiles:(NSString *)scmlFile spriteSheet:(NSString*)spriteSheet;
-(id) initNodeWithFiles:(NSString*)scmlFile;
-(id) initNodeWithFiles:(NSString*)scmlFile spriteSheet:(NSString*)spriteSheet;

// call this to run an animation
-(void) runAnimation:(NSString*)animation;

@end