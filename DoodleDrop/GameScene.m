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
    //using a temporary spider sprite is the easiest way to get the image's size
    CCSprite* tempSpider = [CCSprite spriteWithFile:@"spider.png"];
    float imageWidth = [tempSpider texture].contentSize.width;
    //use as many spiders as can fit next to each other over the whole screen width.
    int numSpiders = screenSize.width/imageWidth;
    //initialize the spiders array using alloc.
    spiders = [[CCArray alloc] initWithCapacity:numSpiders];
    for(int i=0;i<numSpiders;i++)
    {
        CCSprite* spider = [CCSprite spriteWithFile:@"spider.png"];
        [self addChild:spider z:0 tag:2];
//        also add the spider to the spiders array.
        [spiders addObject:spider];
//        call the method to reposition all the spiders;
        [self resetSpiders];
    }
}

-(void) resetSpiders
{
    CGSize screeSize = [[CCDirector sharedDirector] winSize];
//    get any spider to get its image width
    CCSprite* tempSpider = [spiders lastObject];
    CGSize size = [tempSpider texture].contentSize;
    int numSpiders = [spiders count];
    for(int i=0;i<numSpiders;i++)
    {
        CCSprite* spider = [spiders objectAtIndex:i];
        spider.position = CGPointMake(size.width * i + size.width * 0.5f, screeSize.height + size.height);
        [spider stopAllActions];
    }
    
//    Unschedule the selector just in case. If it isn't scheduled it won't do anything.
    [self unschedule:@selector(spidersUpdate:)];
//    Scehdule the spider update logic to run at the given interval.
    [self schedule:@selector(spidersUpdate:) interval:0.7f];
//    reset the moved spiders counter and spider move duration (affects speed)
    numSpidersMoved = 0;
    spiderMoveDuration = 4.0f;
}

-(void) spidersUpdate:(ccTime)delta
  {
//      Try to find a spider which isn't currently moving.
      for(int i=0;i<10;i++)
      {
          int randomSpiderIndex = CCRANDOM_0_1()* [spiders count];
          CCSprite* spider = [spiders objectAtIndex:randomSpiderIndex];
//          If the spider isn't moving it won't have any running actions.
          if([spider numberOfRunningActions]==0)
          {
//              This is the sequence which controls the spiders' movement
              [self runSpiderMoveSequence:spider];
//              Only one spider should start moving at a time.
              break;
          }
      }
  }

-(void) runSpiderMoveSequence:(CCSprite*)spider
{
//    Slowly increase the spider speed over time.
    numSpidersMoved++;
    if(numSpidersMoved %8 ==0 && spiderMoveDuration > 2.0f)
    {
        spiderMoveDuration -= 0.1f;
    }
    
//    This is the sequence which controls the spider's movement
    CGPoint belowScreenPosition = CGPointMake(spider.position.x, -[spider texture].contentSize.height);
    CCMoveTo* move = [CCMoveTo actionWithDuration:spiderMoveDuration position:belowScreenPosition];
    CCCallFuncN* callDidDrop = [CCCallFuncN actionWithTarget:self selector:@selector(spiderDidDrop:)];
    CCSequence* sequence = [CCSequence actions:move,callDidDrop, nil];
    [spider runAction:sequence];
}

-(void) spiderDidDrop:(id)sender
{
//    Make sure sender is actually of the right class.
    NSAssert([sender isKindOfClass:[CCSprite class]],@"sender is not a CCSprite!");
    CCSprite* spider = (CCSprite*)sender;
//    move the spider back up outside the top of the screen
    CGPoint pos = spider.position;
    CGSize screeSize = [[CCDirector sharedDirector] winSize];
    pos.y = screeSize.height + [spider texture].contentSize.height;
    spider.position = pos;
}

-(void) dealloc
{
    CCLOG(@"%@: %@", NSStringFromSelector(_cmd),self);
//    The spiders array must be released, it was created using [CCArray alloc]
    [spiders release];
    spiders = nil;
    
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
    [self checkForCollision];
}

-(void) checkForCollision
{
//    Assumption: both player and spideer images are squares.
    float playerImageSize = [player texture].contentSize.width;
    float spiderImageSize = [[spiders lastObject] texture].contentSize.width;
    float playerCollisionRadius = playerImageSize * 0.4f;
    float spiderCollisionRadius = spiderImageSize * 0.4f;
//    This collision distance will roughly equal the image shapes.
    float maxCollisionDistance = playerCollisionRadius + spiderCollisionRadius;
    
    int numSpiders = [spiders count];
    for (int i=0;i<numSpiders;i++)
    {
        CCSprite* spider = [spiders objectAtIndex:i];
        if([spider numberOfRunningActions]==0)
        {
//            This spider isn't even moving so we can skip checking it.
            continue;
        }
//        Get the idstance between players and spiders.
        float actualDistance = ccpDistance(player.position, spider.position);
        
//        Are the two objects closer than allowed?
        if(actualDistance<maxCollisionDistance)
        {
//            Game over ( just restart the game for now)
            [self resetSpiders];
            break;
        }
    }
    
}


@end
