//
//  GameScene.m
//  DoodleDrop
//
//  Created by Max Gu on 5/10/12.
//  Copyright 2012 guxinchi2000@gmail.com. All rights reserved.
//

#import "GameScene.h"


@implementation GameScene

+(id) scene{
    CCScene *scene = [CCScene node];
    CCLayer *layer = [GameScene node];
    [scene addChild:layer];
    return scene;
}

-(id) init{
    if((self = [super init]))
    {
        [self scheduleUpdate];
        [self initSpiders];
        CCLOG(@"%@: %@", NSStringFromSelector(_cmd),self);
        
        self.isAccelerometerEnabled = YES;
        player = [CCSprite spriteWithFile:@"alien.png"];
        [self addChild:player z:0 tag:1];
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        float imageHeight = [player texture].contentSize.height;
        player.position = CGPointMake(screenSize.width/2, imageHeight/2);
    }
    return self;
}

-(void) initSpiders
{
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    CCSprite* tempSpider = [CCSprite spriteWithFile:@""];
    
}

-(void) dealloc
{
    CCLOG(@"%@: %@", NSStringFromSelector(_cmd),self);
    
    //never forget to call [super dealloc]
    [super dealloc];
}

-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    float deceleration = 0.4f;
    float sensitivity = 60.0f;
    float maxVelocity = 100;
    playerVelocity.x = playerVelocity.x*deceleration+acceleration.x*sensitivity;
    if(playerVelocity.x>maxVelocity)
    {
        playerVelocity.x = maxVelocity;
    }
    else if(playerVelocity.x<-maxVelocity)
    {
        playerVelocity.x = -maxVelocity;
    }
}

-(void)update:(ccTime)delta
{
    //keep adding up the playerVelocity to the player's position
    CGPoint pos = player.position;
    pos.x +=playerVelocity.x;
    
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    float imageWidthHalved = [player texture].contentSize.width * 0.5f;
    float leftBorderLimit = imageWidthHalved;
    float rightBorderLimit = screenSize.width - imageWidthHalved;
    
    //preventing the player sprite from moving outside the screen
    if(pos.x<leftBorderLimit)
    {
        pos.x = leftBorderLimit;
        playerVelocity = CGPointZero;
    }
    else if(pos.x>rightBorderLimit)
    {
        pos.x = rightBorderLimit;
        playerVelocity = CGPointZero;
    }
    player.position = pos;
}


@end
