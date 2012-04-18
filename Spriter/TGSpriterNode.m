//
//  TGSpriterNode.m
//  Spriter
//
//  Created by Salvatore Gionfriddo on 4/17/12.
//  Copyright 2012 Taco Graveyard. All rights reserved.
//

#import "TGSpriterNode.h"

#pragma mark Support Classes

@implementation TGSpriterConfigNode

@synthesize name=name_,parent=parent_,children=children_, value=value_;

+(id) configNode:(NSString*)name {
    TGSpriterConfigNode * configNode;
    
    if ( (configNode = [[super alloc] init]) ) {
        configNode.name = name;
        configNode.children = [[NSMutableArray alloc] init];
    }
    
    return configNode;
}

@end

// holds the sprites associated with a given frame
@implementation TGSpriterFrame

+(id) spriterFrame {
    return [[super alloc] init];
}
-(id) init {
    if ( (self = [super init]) ) {
        sprites_ = [[NSMutableArray alloc] init];
    }
    return self;
}
-(void) dealloc {
    if (sprites_) {
        [sprites_ removeAllObjects];
        [sprites_ release];
    }
    
    [super dealloc];
}
-(void) addSprite:(CCSprite*)sprite {
    [sprites_ addObject:sprite];
}
-(void) setVisible:(BOOL)visible {
    for (CCSprite * sprite in sprites_) {
        sprite.visible = visible;
    }
}

@end

// holds the frames for a given animation
@implementation TGSpriterAnimation

+(id) spriterAnimation {
    return [[super alloc] init];
}
-(id) init {
    if ( (self = [super init]) ) {
        frames_ = [[NSMutableArray alloc] init];
        frameDurations_ = [[NSMutableArray alloc] init];
        frameIdx_ = 0;
        frameDuration_ = 0;
    }
    return self;
}

-(void) addFrame:(TGSpriterFrame*)frame duration:(double)duration {
    [frames_ addObject:frame];
    [frameDurations_ addObject:[NSNumber numberWithDouble:duration]];
    frameIdx_ = [frames_ count] - 1;
}
-(void) hide {
    [[frames_ objectAtIndex:frameIdx_] setVisible:FALSE];
}
-(void)update:(ccTime)dt {
    frameDuration_ += dt;
    
    if (frameDuration_ > [[frameDurations_ objectAtIndex:frameIdx_] doubleValue]) {
        [[frames_ objectAtIndex:frameIdx_] setVisible:FALSE];
        frameIdx_ = (frameIdx_ + 1) % [frames_ count];
        [[frames_ objectAtIndex:frameIdx_] setVisible:TRUE];
        frameDuration_ -= [[frameDurations_ objectAtIndex:frameIdx_] doubleValue];
    }
}

@end

#pragma mark TGSpriterNode

@implementation TGSpriterNode


+(id) spriterNodeWithFiles:(NSString*)scmlFile {
    return [[[super alloc] initNodeWithFiles:scmlFile] autorelease];
}

+(id) spriterNodeWithFiles:(NSString *)scmlFile spriteSheet:(NSString*)spriteSheet {
    return [[[super alloc] initNodeWithFiles:scmlFile spriteSheet:spriteSheet] autorelease];
}
-(id) initNodeWithFiles:(NSString*)scmlFile {
    if ( (self = [super init]) ) {
        frames_ = [[[NSMutableDictionary alloc] init] retain];
        animations_ = [[[NSMutableDictionary alloc] init] retain];
        
        NSString * path = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:scmlFile];
        NSData * scmlData = [NSData dataWithContentsOfFile:path];
        parser_ = [[[NSXMLParser alloc] initWithData:scmlData] retain];
        parser_.delegate = self;
        [parser_ parse];
    }
    
    return self;
}

-(id) initNodeWithFiles:(NSString*)scmlFile spriteSheet:(NSString*)spriteSheet {
    if ( (self = [super init]) ) {
        frames_ = [[[NSMutableDictionary alloc] init] retain];
        animations_ = [[[NSMutableDictionary alloc] init] retain];
        
        useBatchNode_ = TRUE;
        batchNode_ = [CCSpriteBatchNode batchNodeWithFile:spriteSheet];
        [self addChild:batchNode_];
        
        NSString * path = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:scmlFile];
        NSData * scmlData = [NSData dataWithContentsOfFile:path];
        parser_ = [[[NSXMLParser alloc] initWithData:scmlData] retain];
        parser_.delegate = self;
        [parser_ parse];
    }
    
    return self;
}

-(void) dealloc {
    if (parser_)
        [parser_ release];
    
    if (configRoot_)
        [configRoot_ release];
    
    if (animations_) {
        [animations_ removeAllObjects];
        [animations_ release];
    }
    
    if (frames_) {
        [frames_ removeAllObjects];
        [frames_ release];
    }
    
    [super dealloc];
}

#pragma mark Animation

-(void) runAnimation:(NSString*)animation {
    [self unschedule:@selector(update:)];
    
    if (curAnimation_)
        [curAnimation_ hide];
        
    curAnimation_ = [animations_ objectForKey:animation];
    
    [self schedule:@selector(update:)];
}

-(void) update:(ccTime)dt {
    [curAnimation_ update:dt];
}

#pragma mark NSXMLParserDelegate

-(void)parserDidStartDocument:(NSXMLParser *)parser {
    configRoot_ = [[TGSpriterConfigNode configNode:@"root"] retain];
    curConfigNode_ = configRoot_;
}

-(void)parserDidEndDocument:(NSXMLParser *)parser {
    // load all frames
    for (TGSpriterConfigNode * c in [[configRoot_.children objectAtIndex:0] children]) {
        if (![[c name] isEqualToString:@"frame"])
            continue;
        
        NSString * spriterFrameName = @"";
        TGSpriterFrame * spriterFrame = [TGSpriterFrame spriterFrame];
        
        for (TGSpriterConfigNode * frameNodes in c.children) {
            if ([frameNodes.name isEqualToString:@"name"]) {
                spriterFrameName = frameNodes.value;
            } else if ([frameNodes.name isEqualToString:@"sprite"]) {
                NSString * img;
                double x = 0, y = 0, angle=0, width = 0, height = 0;
                int opacity = 255;
                BOOL flipX = FALSE, flipY = FALSE;
                ccColor3B color = ccc3(255, 255, 255);
                for (TGSpriterConfigNode * spriteProp in frameNodes.children) {
                    //CCLOG(@"\t%@: %@", spriteProp.name, spriteProp.value);
                    if ([spriteProp.name isEqualToString:@"image"]) {
                        img = [[spriteProp.value componentsSeparatedByString:@"\\"] lastObject];
                    } else if ([spriteProp.name isEqualToString:@"x"]) {
                        x = [spriteProp.value doubleValue];
                    } else if ([spriteProp.name isEqualToString:@"y"]) {
                        y = -[spriteProp.value doubleValue];
                    } else if ([spriteProp.name isEqualToString:@"angle"]) {
                        angle = -[spriteProp.value doubleValue];
                    } else if ([spriteProp.name isEqualToString:@"opacity"]) {
                        opacity = [spriteProp.value doubleValue] / 100.0 * 255;
                    } else if ([spriteProp.name isEqualToString:@"flipX"]) {
                        flipX = [spriteProp.value boolValue];
                    } else if ([spriteProp.name isEqualToString:@"flipY"]) {
                        flipY = [spriteProp.value boolValue];
                    } else if ([spriteProp.name isEqualToString:@"color"]) {
                        int c = [spriteProp.value intValue];
                        int red = c / pow(256, 2);
                        int green = (c - red * pow(256, 2)) / 256;
                        int blue = c -  red * pow(256, 2) - blue * 256;
                        color = ccc3(red, green, blue);
                    } else if ([spriteProp.name isEqualToString:@"width"]) {
                        width = [spriteProp.value doubleValue];
                    } else if ([spriteProp.name isEqualToString:@"height"]) {
                        height = [spriteProp.value doubleValue];
                    }
                }
                CCSprite * sprite;
                if (useBatchNode_) {
                    sprite = [CCSprite spriteWithSpriteFrameName:img];
                } else {
                    sprite = [CCSprite spriteWithFile:img];
                }
                sprite.anchorPoint = ccp(0,1);
                sprite.position = ccp(x,y);
                sprite.rotation = angle;
                sprite.flipX = flipX;
                sprite.flipY = flipY;
                sprite.color = color;
                sprite.scaleX = width / sprite.contentSize.width;
                sprite.scaleY = height / sprite.contentSize.height;
                sprite.visible = FALSE;
                
                if (useBatchNode_) {
                    [batchNode_ addChild:sprite];
                } else {
                    [self addChild:sprite];
                }
                [spriterFrame addSprite:sprite];
            }
        }
        [frames_ setObject:spriterFrame forKey:spriterFrameName];
    }
    
    // load all animations
    for (TGSpriterConfigNode * c in [[configRoot_.children objectAtIndex:0] children]) {
        if (![[c name] isEqualToString:@"char"])
            continue;
        
        for (TGSpriterConfigNode * charNodes in c.children) {
            if ([charNodes.name isEqualToString:@"name"]) {
                //CCLOG(@"Character Name: %@", charNodes.value);
                continue;
            } else if ([charNodes.name isEqualToString:@"anim"]) {
                TGSpriterAnimation * animation = [TGSpriterAnimation spriterAnimation];
                NSString * animationName = @"";
                for (TGSpriterConfigNode * frames in charNodes.children) {
                    if ([frames.name isEqualToString:@"name"]) { // animation name
                        animationName = frames.value;
                    } else if ([frames.name isEqualToString:@"frame"]) {
                        NSString * frameName = @"";
                        double frameDuration = 0;
                        for (TGSpriterConfigNode * frameProp in frames.children) {
                            if ([frameProp.name isEqualToString:@"name"]) {
                                frameName = frameProp.value;
                            } else if ([frameProp.name isEqualToString:@"duration"]) {
                                // the spec stats milliseconds, but this doesn't match the reference implementation.
                                frameDuration = [frameProp.value doubleValue]/100.0;// milliseconds?? should be 1000
                            }
                        }
                        [animation addFrame:[frames_ objectForKey:frameName] duration:frameDuration];
                    }
                }
                [animations_ setObject:animation forKey:animationName];
            }
        }
    }
    
    // clean up
    if (configRoot_) {
        [configRoot_ release];
        configRoot_ = nil;
    }
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    TGSpriterConfigNode * newNode = [TGSpriterConfigNode configNode:elementName];
    newNode.parent = curConfigNode_;
    [curConfigNode_.children addObject:newNode];
    curConfigNode_ = newNode;
}

-(void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    curConfigNode_ = curConfigNode_.parent;
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (curConfigNode_.value == nil) {
        curConfigNode_.value = string;
    } else {
        curConfigNode_.value = [curConfigNode_.value stringByAppendingString:string];
    }
}

@end
