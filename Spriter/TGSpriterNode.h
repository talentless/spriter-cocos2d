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

@interface TGSpriterNode : CCNode <NSXMLParserDelegate> {
    NSXMLParser * parser_;
    
    NSString * characterName_;
    NSMutableDictionary * animations_; // {name: [(name,duration),(name,duration),...],...}
   // NSMutableDictionary * frames_; // {name: [(image, color, opacity, angle, xflip,yflip,width,height, x,y),..],..}
    
    NSString * animation_;
    NSMutableArray * frames_;
    NSMutableArray * frameDurations_;
    int frameIdx_;
    double frameDuration_;
    
    // batch node use?
    
    // SAX vars
    TGSpriterConfigNode * configRoot_;
    TGSpriterConfigNode * curConfigNode_;
    int totalNodes_;
}

+(id) spriterNodeWithFiles:(NSString*)scmlFile;
-(id) initNodeWithFiles:(NSString*)scmlFile;

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