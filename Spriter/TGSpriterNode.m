//
//  TGSpriterNode.m
//  Spriter
//
//  Created by Salvatore Gionfriddo on 4/17/12.
//  Copyright 2012 Taco Graveyard. All rights reserved.
//

#import "TGSpriterNode.h"

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

@implementation TGSpriterNode


+(id) spriterNodeWithFiles:(NSString*)scmlFile {
    TGSpriterNode * node;
    
    if ( (node = [[[super alloc] initNodeWithFiles:scmlFile] autorelease]) ) {
        
    }
    
    return node;
}

-(id) initNodeWithFiles:(NSString*)scmlFile {
    if ( (self = [super init]) ) {
        NSString * path = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:scmlFile];
        NSData * scmlData = [NSData dataWithContentsOfFile:path];
        parser_ = [[[NSXMLParser alloc] initWithData:scmlData] retain];
        parser_.delegate = self;
        [parser_ parse];
        
        frames_ = [[[NSMutableArray alloc] init] retain];
        frameDurations_ = [[[NSMutableArray alloc] init] retain];
    }
    
    return self;
}

-(void) dealloc {
    if (parser_)
        [parser_ release];
    
    if (configRoot_)
        [configRoot_ release];
    
    if (frames_)
        [frames_ release];
    
    [super dealloc];
}

#pragma mark Animation

-(void) runAnimation:(NSString*)animation {
    [self unschedule:@selector(update:)];
    
    animation_ = animation;
    
    [frames_ removeAllObjects];
    [frameDurations_ removeAllObjects];
    frameIdx_ = 0;
    frameDuration_ = 0;
    
    for (TGSpriterConfigNode * c in [[configRoot_.children objectAtIndex:0] children]) {
        if (![[c name] isEqualToString:@"char"])
            continue;
        
        for (TGSpriterConfigNode * charNodes in c.children) {
            if ([charNodes.name isEqualToString:@"name"]) {
                CCLOG(@"Character Name: %@", charNodes.value);
                continue;
            } else if ([charNodes.name isEqualToString:@"anim"]) {
                BOOL showThese = FALSE;
                for (TGSpriterConfigNode * frames in charNodes.children) {
                    if ([frames.name isEqualToString:@"name"] && [frames.value isEqualToString:animation_]) { // animation name
                        showThese = TRUE;
                    } else if ([frames.name isEqualToString:@"frame"] && showThese) { // this is incorrectly assuming that name is the first node
                        for (TGSpriterConfigNode * frameProp in frames.children) {
                            if ([frameProp.name isEqualToString:@"name"]) {
                                [frames_ addObject:frameProp.value];
                            } else if ([frameProp.name isEqualToString:@"duration"]) {
                                [frameDurations_ addObject:[NSNumber numberWithDouble:[frameProp.value doubleValue]]];
                            }
                        }
                    }
                }
            }
        }
    }
    
    CCLOG(@"frames: %d", [frames_ count]);
    
    [self schedule:@selector(update:)];
}

-(void) update:(ccTime)dt {
    frameDuration_ += dt;
    
    if (frameDuration_ > ([[frameDurations_ objectAtIndex:frameIdx_] doubleValue] / 100.0)) {
        [self showFrame:[frames_ objectAtIndex:frameIdx_]];
        frameIdx_ = (frameIdx_ + 1) % [frames_ count];
        frameDuration_ = 0;
    }
}

-(void) showFrame:(NSString*)frame {
    [self removeAllChildrenWithCleanup:YES]; // this is hugely inefficient
    
    for (TGSpriterConfigNode * c in [[configRoot_.children objectAtIndex:0] children]) {
        if (![[c name] isEqualToString:@"frame"])
            continue;
        
        for (TGSpriterConfigNode * frameNodes in c.children) {
            if ([frameNodes.name isEqualToString:@"name"]) {
                if (![frameNodes.value isEqualToString:frame]) {
                    break;
                }
                //CCLOG(@"Frame Name: %@", frameNodes.value);
            } else if ([frameNodes.name isEqualToString:@"sprite"]) {
                NSString * img;
                double x = 0, y = 0, angle=0;
                int opacity = 255;
                BOOL flipX = FALSE, flipY = FALSE;
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
                    }
                    // color
                    // xflip
                    // yflip
                    // width
                    // height
                }
                CCSprite * sprite = [CCSprite spriteWithFile:img];
                sprite.anchorPoint = ccp(0,1);
                sprite.position = ccp(x,y);
                sprite.rotation = angle;
                sprite.flipX = flipX;
                sprite.flipY = flipY;
                [self addChild:sprite];
            }
        }
    }
}

#pragma mark NSXMLParserDelegate

-(void)parserDidStartDocument:(NSXMLParser *)parser {
    configRoot_ = [[TGSpriterConfigNode configNode:@"root"] retain];
    curConfigNode_ = configRoot_;
}

-(void)parserDidEndDocument:(NSXMLParser *)parser {
    CCLOG(@"finished parsing: %d", totalNodes_);
    
    
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    //CCLOG(@"Element Start: %@", elementName);
    
    TGSpriterConfigNode * newNode = [TGSpriterConfigNode configNode:elementName];
    newNode.parent = curConfigNode_;
    [curConfigNode_.children addObject:newNode];
    curConfigNode_ = newNode;
    
    totalNodes_++;
}

-(void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    curConfigNode_ = curConfigNode_.parent;
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (curConfigNode_.value == nil) {
        curConfigNode_.value = string;
    } else {
        // ignore??
        //curConfigNode_.value = [curConfigNode_.value stringByAppendingString:string];
        //CCLOG(@"appending data");
    }
}

@end
