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

@synthesize timelineId=timelineId_, timelineKey=timelineKey_;

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

@synthesize file=file_, folder=folder_, position=position_, anchorPoint=anchorPoint_, rotation=rotation_, startsAt=startsAt_, spin=spin_, scaleX=scaleX_, scaleY=scaleY_;

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


@implementation TGSpriterSprite

@synthesize folder, file, displayFrameName;

-(void) dealloc {
    if (displayFrameName) {
        [displayFrameName release];
    }
    
    [super dealloc];
}

@end

#pragma mark -
#pragma mark TGSpriterNode

@implementation TGSpriterNode

@synthesize smoothTransitions, playbackSpeed=playbackSpeed_;

+(id) spriterNodeWithFiles:(NSString *)scmlFile spriteSheet:(NSString*)spriteSheet sdScale:(double)sdScale offset:(CGPoint)offset {
    return [[[super alloc] initNodeWithFiles:scmlFile spriteSheet:spriteSheet sdScale:sdScale offset:offset] autorelease];
}
+(id) spriterNodeWithFiles:(NSString *)scmlFile spriteSheet:(NSString*)spriteSheet {
    return [[[super alloc] initNodeWithFiles:scmlFile spriteSheet:spriteSheet sdScale:0.5 offset:ccp(0,0)] autorelease];
}

-(id) initNodeWithFiles:(NSString*)scmlFile spriteSheet:(NSString*)spriteSheet sdScale:(double)sdScale offset:(CGPoint)offset {
    if ( (self = [super init]) ) {
        sdScale_ = sdScale; // assumes animation was built with retina assets
        offset_ = offset;
        playbackSpeed_ = 1.0;
        
        frames_ = [[[NSMutableDictionary alloc] init] retain];
        animations_ = [[[NSMutableDictionary alloc] init] retain];
        files_ = [[[NSMutableArray alloc] init] retain];
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
    
    //CCLOG(@"running animation: %@", animation);
    
    duration_ = 0;
    frameIdx_ = 0;
    if (smoothTransitions) {
        prevAnimation_ = curAnimation_;
    }
    curAnimation_ = [animations_ objectForKey:animation];
    if (smoothTransitions) {
        nextKeyFrame_ = [curAnimation_.mainline objectAtIndex:0];
    } else {
        curKeyFrame_ = [curAnimation_.mainline objectAtIndex:0];
        nextKeyFrame_ = [curAnimation_.mainline objectAtIndex:(frameIdx_+1)%[curAnimation_.mainline count]];
    }
    
    [self schedule:@selector(update:)];
}

-(void) update:(ccTime)dt {
    // increment the time
    duration_ += dt;
    int milliseconds = duration_ * 1000 * playbackSpeed_;
    int startTime = curKeyFrame_.startsAt;
    int endTime = nextKeyFrame_.startsAt;
    BOOL lastFrame = frameIdx_+1 == [curAnimation_.mainline count];
    if (prevAnimation_) {
        endTime = MAX(0, prevAnimation_.duration - curKeyFrame_.startsAt);
    } else if (nextKeyFrame_.startsAt == 0) {
        endTime = curAnimation_.duration;
    }
    // swap the key frames if we passed the duration
    if (milliseconds > endTime) {
        if (prevAnimation_) {
            prevAnimation_ = nil; // transition has occured
            frameIdx_ = -1;
            duration_ = dt;
            milliseconds = duration_ * 1000 * playbackSpeed_;
        }
        if (!lastFrame || (lastFrame && [self animationEnded])) {
            curKeyFrame_ = nextKeyFrame_;
            frameIdx_ = (frameIdx_+1)%[curAnimation_.mainline count];
            nextKeyFrame_ = [curAnimation_.mainline objectAtIndex:(frameIdx_+1)%[curAnimation_.mainline count]];
            startTime = curKeyFrame_.startsAt;
            endTime = nextKeyFrame_.startsAt;
            if (nextKeyFrame_.startsAt == 0) {
                endTime = curAnimation_.duration;
            }
            [self animationFrameChanged];
        } else {
            return; // early exit
        }
        if (milliseconds > curAnimation_.duration && frameIdx_ == 0) {
            duration_ -= curAnimation_.duration * (0.001/playbackSpeed_);
            milliseconds -= curAnimation_.duration * playbackSpeed_;
        }
    }
    
    // hide existing nodes (this is more important later when we have temp objects)
    for (TGSpriterSprite * n in spriterNodes_) {
        [n setVisible:FALSE];
        n.folder = -1;
        n.file = -1;
    }
    
    // interpolation
    double interpolationFactor = ((milliseconds - startTime)/(1.0*(endTime-startTime)));
    
    if (interpolationFactor == INFINITY) { interpolationFactor = 0.0; }
    if (interpolationFactor < 0) { interpolationFactor = 0.0; }
    if (interpolationFactor > 1) { interpolationFactor = 1.0; }
    if (interpolationFactor == NAN) { interpolationFactor = 1.0; }
    
    // walk through mainline objects
    for (int keyIdx = 0; keyIdx < [curKeyFrame_.objectRefs count]; keyIdx++) {
        // look up the current and next timeline keys
        TGSpriterObjectRef * curObjectRef = [curKeyFrame_.objectRefs objectAtIndex:keyIdx];
        TGSpriterObjectRef * nextObjectRef = [nextKeyFrame_.objectRefs objectAtIndex:keyIdx];
        
        TGSpriterTimeline * objectTimeline = [curAnimation_.timelines objectAtIndex:[curObjectRef timelineId]];
        
        TGSpriterTimelineKey * curTimelineKey;
        if (smoothTransitions && prevAnimation_) {
            TGSpriterTimeline * curObjectTimeline = [prevAnimation_.timelines objectAtIndex:[curObjectRef timelineId]];
            curTimelineKey = [curObjectTimeline.keys objectAtIndex:[curObjectRef timelineKey]];
        } else {
            curTimelineKey = [objectTimeline.keys objectAtIndex:[curObjectRef timelineKey]];
        }
        TGSpriterTimelineKey * nextTimelineKey = [objectTimeline.keys objectAtIndex:[nextObjectRef timelineKey]];
        
        // Get the display frame
        NSString * displayFrameName = [[files_ objectAtIndex:[curTimelineKey folder]] objectAtIndex:[curTimelineKey file]];
        
        TGSpriterSprite * sprite;
        // set this data to the first available spriterNode, create a new one if this animation has more objects
        if (keyIdx >= [spriterNodes_ count]) {
            sprite = [TGSpriterSprite spriteWithSpriteFrameName:displayFrameName];
            sprite.displayFrameName = displayFrameName;
            [batchNode_ addChild:sprite];
            [spriterNodes_ addObject:sprite];
        } else {
            sprite = [spriterNodes_ objectAtIndex:keyIdx];
            if (![sprite.displayFrameName isEqualToString:displayFrameName]) {
                sprite.displayFrameName = displayFrameName;
                [sprite setDisplayFrame:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:displayFrameName]];
            }
        }
        sprite.visible = TRUE;
        sprite.folder = [curTimelineKey folder];
        sprite.file = [curTimelineKey file];
        
        sprite.position = ccp([self interpolate:curTimelineKey.position.x b:nextTimelineKey.position.x f:interpolationFactor],
                              [self interpolate:curTimelineKey.position.y b:nextTimelineKey.position.y f:interpolationFactor]);
        sprite.anchorPoint = ccp([self interpolate:curTimelineKey.anchorPoint.x b:nextTimelineKey.anchorPoint.x f:interpolationFactor],
                                 [self interpolate:curTimelineKey.anchorPoint.y b:nextTimelineKey.anchorPoint.y f:interpolationFactor]);
        sprite.scaleX = [self interpolate:curTimelineKey.scaleX b:nextTimelineKey.scaleX f:interpolationFactor];
        sprite.scaleY = [self interpolate:curTimelineKey.scaleY b:nextTimelineKey.scaleY f:interpolationFactor];
        
        double nextRotation = nextTimelineKey.rotation;
        double curRotation = curTimelineKey.rotation;
        if (fabs(curRotation-nextRotation) <= 0.001) { // There appears to be a spriter bug related to close FP numbers outputting the wrong spin. This solves that.
            nextRotation = curRotation;
        } else if (curTimelineKey.spin == 1 && (nextRotation-curRotation) < 0) {
            nextRotation += 360;
        } else if (curTimelineKey.spin == -1 && (nextRotation-curRotation) > 0) {
            nextRotation -= 360;
        }
        sprite.rotation = -[self interpolate:curRotation b:nextRotation f:interpolationFactor];
    }
}

-(double) interpolate:(double)a b:(double)b f:(double)f {
    if (a == b) { return a; }
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
        //CCLOG(@"%@", c.name);
        
        if ([[c name] isEqualToString:@"folder"]) {
            NSMutableArray * folder = [[NSMutableArray alloc] init];
            for (TGSpriterConfigNode * file in c.children) {
                //CCLOG(@"%@: %d-%d => %@", c.name, [[c.properties objectForKey:@"id"] intValue], [[file.properties objectForKey:@"id"] intValue], [[file.properties objectForKey:@"name"] lastPathComponent]);
                [folder addObject:[[file.properties objectForKey:@"name"] lastPathComponent]];
            }
            [files_ addObject:folder];
        } else if ([[c name] isEqualToString:@"entity"]) {
            // SpriterNode->[TGSpriterAnimation]->[TGSpriterFrame]->[TGSpriteObjectKey]
            for (TGSpriterConfigNode * animation in c.children) {
                // animation
                
                TGSpriterAnimation * spriterAnimation = [TGSpriterAnimation spriterAnimation];
                spriterAnimation.name = [animation.properties objectForKey:@"name"];
                spriterAnimation.duration = [[animation.properties objectForKey:@"length"] intValue];
                
                //CCLOG(@"Parsing Animation: %@ (%d ms.)", spriterAnimation.name, (int)spriterAnimation.duration);
                
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
                            mainlineKey.startsAt = [[key.properties objectForKey:@"time"] intValue];
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
                                
                                timelineKey.position = ccpMult(ccpAdd(ccp([[object.properties objectForKey:@"x"] doubleValue],
                                                                          [[object.properties objectForKey:@"y"] doubleValue]), offset_), sdScale_);
                                if ([object.properties objectForKey:@"pivot_x"]) {
                                    timelineKey.anchorPoint = ccp([[object.properties objectForKey:@"pivot_x"] doubleValue],
                                                                  [[object.properties objectForKey:@"pivot_y"] doubleValue]);
                                } else {
                                    timelineKey.anchorPoint = ccp(0,1);
                                }
                                if ([object.properties objectForKey:@"scale_x"]) {
                                    timelineKey.scaleX = [[object.properties objectForKey:@"scale_x"] doubleValue];
                                } else {
                                    timelineKey.scaleX = 1.0;
                                }
                                if ([object.properties objectForKey:@"scale_y"]) {
                                    timelineKey.scaleY = [[object.properties objectForKey:@"scale_y"] doubleValue];
                                } else {
                                    timelineKey.scaleY = 1.0;
                                }
                                
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

-(BOOL) animationEnded { return TRUE;}
-(void)animationFrameChanged {}

@end
