//
//  TGSpriterNode.h
//  Spriter
//
//  Created by Salvatore Gionfriddo on 4/17/12.
//  Copyright 2012 Taco Graveyard. All rights reserved.
//

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
-(void)update:(ccTime)dt;

@end

@interface TGSpriterNode : CCNode <NSXMLParserDelegate> {
    NSXMLParser * parser_;
    
    NSString * characterName_;
    NSMutableDictionary * animations_; // {name: TGSpriterAnimation,...}
    NSMutableDictionary * frames_; // {name: TGSpriterFrame,..}
    
    TGSpriterAnimation * curAnimation_;
    
    //NSMutableArray * frames_;
    //NSMutableArray * frameDurations_;
    //int frameIdx_;
    //double frameDuration_;
    
    // batch node use?
    CCSpriteBatchNode * batchNode_;
    BOOL useBatchNode_;
    
    // SAX vars
    TGSpriterConfigNode * configRoot_;
    TGSpriterConfigNode * curConfigNode_;
    int totalNodes_;
}

+(id) spriterNodeWithFiles:(NSString*)scmlFile;
+(id) spriterNodeWithFiles:(NSString *)scmlFile spriteSheet:(NSString*)spriteSheet;
-(id) initNodeWithFiles:(NSString*)scmlFile;
-(id) initNodeWithFiles:(NSString*)scmlFile spriteSheet:(NSString*)spriteSheet;

-(void) runAnimation:(NSString*)animation;

/*
 spriterdata
    char - character. In the beta there will always be only one Character per file
        name - character's name
        anim - Animation. There can be any number of <anim>'s per <char>
            name - The name of the animation.
            frame - Keyframe. There can be any number of <frame>'s per <anim>
                name - These will correspond the <frame>'s listed after the <char>'s.
                duration - How long to keep the frame on screen (in ms).
    frame - There can be any number of <frame>'s per file.
        name - <name> of the <frame>, referred to by the keyframes above.
        sprite - Each <frame> can have any number of <sprite>'s.
            image - refers to the path and filename of the imagefile to draw
            color - in RGB integer form (16777215 is white)
            opacity - from 0 – 100 with 5 digits of precision
            angle - in degrees counterclockwise ( = 0; = 45)
            xflip - multiply width by -1
            yflip - multiply height by -1
            width - width to display sprite, in pixels
            height - height to display sprite, in pixels
            x - x position to display sprite (relative to character's position)
            y - y position to display sprite (relative to character's position)
 */

@end