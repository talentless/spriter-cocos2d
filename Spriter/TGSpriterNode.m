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

@synthesize name=name_,parent=parent_,children=children_, value=value_, properties=properties_;

+(id) configNode:(NSString*)name {
    TGSpriterConfigNode * configNode;
    
    if ( (configNode = [[super alloc] init]) ) {
        configNode.name = name;
        configNode.children = [[NSMutableArray alloc] init];
        configNode.properties = [[NSMutableDictionary alloc] init];
    }
    
    return configNode;
}

@end

@implementation TGSpriterObjectRef

@synthesize timelineId=timelineId_, timelineKey=timelineKey;

+(id) spriterObjectRef {
    return [[super alloc] init];
}

@end

// holds the sprites associated with a given frame
@implementation TGSpriterMainlineKey

@synthesize startsAt=startsAt_, objectRefs=objectRefs_;

+(id) spriterFrame {
    return [[super alloc] init];
}
-(id) init {
    if ( (self = [super init]) ) {
        objectRefs_ = [[[NSMutableArray alloc] init] retain];
    }
    return self;
}
-(void) dealloc {
    if (objectRefs_) {
        [objectRefs_ removeAllObjects];
        [objectRefs_ release];
    }
    
    [super dealloc];
}

-(void) addObjectRef:(TGSpriterObjectRef*)sprite; {
    [objectRefs_ addObject:sprite];
}

@end

@implementation TGSpriterTimeline

@synthesize keys=keys_;

+(id)spriterTimeline {
    return [[super alloc] init];
}
-(void) addKeyFrame:(TGSpriterTimelineKey*)frame {
    [keys_ addObject:frame];
}
-(id) init {
    if ( (self = [super init]) ) {
        keys_ = [[[NSMutableArray alloc] init] retain];
    }
    return self;
}
-(void) dealloc {
    if (keys_) {
        [keys_ removeAllObjects];
        [keys_ release];
    }
    
    [super dealloc];
}

@end

@implementation TGSpriterTimelineKey

@synthesize file=file_, folder=folder_, position=position_, anchorPoint=anchorPoint_, rotation=rotation_, startsAt=startsAt_, spin=spin_;

+(id)spriterTimelineKey {
    return [[super alloc] init];
}

@end

// holds the frames for a given animation
@implementation TGSpriterAnimation

@synthesize name=name_, duration=duration_, mainline=mainline_, timelines=timelines_;

+(id) spriterAnimation {
    return [[super alloc] init];
}
-(id) init {
    if ( (self = [super init]) ) {
        mainline_ = [[NSMutableArray alloc] init];
        timelines_ = [[NSMutableArray alloc] init];
        duration_ = 0;
    }
    return self;
}
-(void) addKeyFrame:(TGSpriterMainlineKey*)frame {
    [mainline_ addObject:frame];
}


-(void) addTimeline:(TGSpriterTimeline*)timeline {
    [timelines_ addObject:timeline];
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
    return nil; // not implemented 
    if ( (self = [super init]) ) {
        frames_ = [[[NSMutableDictionary alloc] init] retain];
        animations_ = [[[NSMutableDictionary alloc] init] retain];
        files_ = [[[NSMutableDictionary alloc] init] retain];
        
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
        files_ = [[[NSMutableDictionary alloc] init] retain];
        spriterNodes_ = [[[NSMutableArray alloc] init] retain];
        
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
    
    if (files_) {
        [files_ removeAllObjects];
        [files_ release];
    }
    
    if (frames_) {
        [frames_ removeAllObjects];
        [frames_ release];
    }
    
    if (spriterNodes_) {
        [spriterNodes_ removeAllObjects];
        [spriterNodes_ release];
    }
    
    [super dealloc];
}

#pragma mark Animation

-(void) runAnimation:(NSString*)animation {
    [self unschedule:@selector(update:)];
    
    duration_ = 0;
    frameIdx_ = 0;
    curAnimation_ = [animations_ objectForKey:animation];
    curKeyFrame_ = [curAnimation_.mainline objectAtIndex:0];
    nextKeyFrame_ = [curAnimation_.mainline objectAtIndex:(frameIdx_+1)%[curAnimation_.mainline count]];
    
    [self schedule:@selector(update:)];
}

-(void) update:(ccTime)dt {
    // increment the time
    duration_ += dt;
    int milliseconds = duration_ * 10000;
    int startTime = curKeyFrame_.startsAt;
    int endTime = nextKeyFrame_.startsAt;
    if (nextKeyFrame_.startsAt == 0) {
        endTime = curAnimation_.duration;
    }
    // swap the key frames if we passed the duration
    if (milliseconds > endTime) {
        curKeyFrame_ = nextKeyFrame_;
        frameIdx_ = (frameIdx_+1)%[curAnimation_.mainline count];
        nextKeyFrame_ = [curAnimation_.mainline objectAtIndex:(frameIdx_+1)%[curAnimation_.mainline count]];
        startTime = curKeyFrame_.startsAt;
        endTime = nextKeyFrame_.startsAt;
    }
    if (milliseconds > curAnimation_.duration) {
        duration_ -= milliseconds * 0.0001;
        milliseconds -= 10000;
    }
    
    // hide existing nodes (this is more important later when we have temp objects)
    for (CCNode * n in spriterNodes_) {
        [n setVisible:FALSE];
    }
    
    // interpolation
    double interpolationFactor = ((milliseconds - startTime)/(1.0*(endTime-startTime)));
    
    // walk through mainline objects
    for (int keyIdx = 0; keyIdx < [curKeyFrame_.objectRefs count]; keyIdx++) {
        // look up the current and next timeline keys
        TGSpriterObjectRef * curObjectRef = [curKeyFrame_.objectRefs objectAtIndex:keyIdx];
        TGSpriterObjectRef * nextObjectRef = [nextKeyFrame_.objectRefs objectAtIndex:keyIdx];
        
        TGSpriterTimeline * objectTimeline = [curAnimation_.timelines objectAtIndex:[curObjectRef timelineId]];
        
        TGSpriterTimelineKey * curTimelineKey = [objectTimeline.keys objectAtIndex:[curObjectRef timelineKey]];
        TGSpriterTimelineKey * nextTimelineKey = [objectTimeline.keys objectAtIndex:[nextObjectRef timelineKey]];
        
        // Get the display frame
        NSString * displayFrameName = [files_ objectForKey:[NSString stringWithFormat:@"%d-%d", [curTimelineKey folder], [curTimelineKey file]]];
        
        CCSprite * sprite;
        // set this data to the first available spriterNode, create a new one if this animation has more objects
        if (keyIdx >= [spriterNodes_ count]) {
            sprite = [CCSprite spriteWithSpriteFrameName:displayFrameName];
            [batchNode_ addChild:sprite];
            [spriterNodes_ addObject:sprite];
        } else {
            sprite = [spriterNodes_ objectAtIndex:keyIdx];
            [sprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:displayFrameName]];
        }
        sprite.visible = TRUE;
        
        sprite.position = ccp([self interpolate:curTimelineKey.position.x b:nextTimelineKey.position.x f:interpolationFactor],
                              [self interpolate:curTimelineKey.position.y b:nextTimelineKey.position.y f:interpolationFactor]);
        sprite.anchorPoint = ccp([self interpolate:curTimelineKey.anchorPoint.x b:nextTimelineKey.anchorPoint.x f:interpolationFactor],
                              [self interpolate:curTimelineKey.anchorPoint.y b:nextTimelineKey.anchorPoint.y f:interpolationFactor]);
        
        double nextRotation = nextTimelineKey.rotation;
        double curRotation = curTimelineKey.rotation;
        if (curTimelineKey.spin == 1 && (nextRotation-curRotation) < 0) {
            nextRotation += 360;
        } else if (curTimelineKey.spin == -1 && (nextRotation-curRotation) > 0) {
            nextRotation -= 360;
        }
        sprite.rotation = -[self interpolate:curRotation b:nextRotation f:interpolationFactor];
    }
}

-(double) interpolate:(double)a b:(double)b f:(double)f {
    if (f == INFINITY) { f = 0.0; }
    if (f < 0) { f = 0.0; }
    if (f > 1) { f = 1.0; }
    if (f == NAN) { f = 1.0; }
    return a+(b-a)*f;
}

#pragma mark NSXMLParserDelegate

-(void)parserDidStartDocument:(NSXMLParser *)parser {
    configRoot_ = [[TGSpriterConfigNode configNode:@"root"] retain];
    curConfigNode_ = configRoot_;
}

-(void)parserDidEndDocument:(NSXMLParser *)parser {
    // load all frames
    for (TGSpriterConfigNode * c in [[configRoot_.children objectAtIndex:0] children]) {
        CCLOG(@"%@", c.name);
        
        if ([[c name] isEqualToString:@"folder"]) {
            for (TGSpriterConfigNode * file in c.children) {
                CCLOG(@"%@: %d-%d => %@", c.name, [[c.properties objectForKey:@"id"] intValue], [[file.properties objectForKey:@"id"] intValue], [[file.properties objectForKey:@"name"] lastPathComponent]);
                
                NSString * fileKey = [NSString stringWithFormat:@"%d-%d", [[c.properties objectForKey:@"id"] intValue], [[file.properties objectForKey:@"id"] intValue]];
                [files_ setObject:[[file.properties objectForKey:@"name"] lastPathComponent] forKey:fileKey];
                
            }
        } else if ([[c name] isEqualToString:@"entity"]) {
            // SpriterNode->[TGSpriterAnimation]->[TGSpriterFrame]->[TGSpriteObjectKey]
            for (TGSpriterConfigNode * animation in c.children) {
                // animation
                
                TGSpriterAnimation * spriterAnimation = [TGSpriterAnimation spriterAnimation];
                spriterAnimation.name = [animation.properties objectForKey:@"name"];
                spriterAnimation.duration = [[animation.properties objectForKey:@"length"] intValue];
                
                CCLOG(@"Parsing Animation: %@ (%d ms.)", spriterAnimation.name, (int)spriterAnimation.duration);
                
                for (TGSpriterConfigNode * animConfig in animation.children) {
                    //      mainline
                    
                    if ([[animConfig name] isEqualToString:@"mainline"]) {
                        //          key
                        for (TGSpriterConfigNode * key in animConfig.children) {
                            TGSpriterMainlineKey * mainlineKey = [TGSpriterMainlineKey spriterFrame];
                            for (TGSpriterConfigNode * object_ref in key.children) {
                                //              object_ref->timeline,key,z_index
                                TGSpriterObjectRef * objectRef = [TGSpriterObjectRef spriterObjectRef];
                                objectRef.timelineId = [[object_ref.properties objectForKey:@"timeline"] intValue];
                                objectRef.timelineKey = [[object_ref.properties objectForKey:@"key"] intValue];
                                
                                [mainlineKey addObjectRef:objectRef];
                            }
                            [spriterAnimation addKeyFrame:mainlineKey];
                        }
                    } else if ([[animConfig name] isEqualToString:@"timeline"]) {
                        //      timeline->id
                        TGSpriterTimeline * timeline = [TGSpriterTimeline spriterTimeline];
                        for (TGSpriterConfigNode * key in animConfig.children) {
                            //          key->id,time
                            for (TGSpriterConfigNode * object in key.children) {
                                //              object->folder,file,x,y,etc
                                TGSpriterTimelineKey * timelineKey = [TGSpriterTimelineKey spriterTimelineKey];
                                timelineKey.folder = [[object.properties objectForKey:@"folder"] intValue];
                                timelineKey.file = [[object.properties objectForKey:@"file"] intValue];
                                
                                timelineKey.position = ccp([[object.properties objectForKey:@"x"] doubleValue],
                                                           [[object.properties objectForKey:@"y"] doubleValue]);
                                timelineKey.anchorPoint = ccp([[object.properties objectForKey:@"pivot_x"] doubleValue],
                                                           [[object.properties objectForKey:@"pivot_y"] doubleValue]);
                                
                                
                                timelineKey.startsAt = [[key.properties objectForKey:@"time"] intValue];
                                timelineKey.rotation = [[object.properties objectForKey:@"angle"] doubleValue];
                                
                                if ([key.properties objectForKey:@"spin"]) {
                                    timelineKey.spin = [[key.properties objectForKey:@"spin"] intValue];
                                } else {
                                    timelineKey.spin = 1;
                                }
                                
                                [timeline addKeyFrame:timelineKey];
                            }
                        }
                        [spriterAnimation addTimeline:timeline];
                    }
                }
                
                [animations_ setObject:spriterAnimation forKey:spriterAnimation.name];
            }
        }
        
        continue;
    }
        
        /*
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
         */
    
        /*
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
         */
    
    // clean up
    if (configRoot_) {
        [configRoot_ release];
        configRoot_ = nil;
    }
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    TGSpriterConfigNode * newNode = [TGSpriterConfigNode configNode:elementName];
    newNode.parent = curConfigNode_;
    
    for (NSString * s in attributeDict) {
        [newNode.properties setObject:[attributeDict objectForKey:s] forKey:s];
    }
    
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
