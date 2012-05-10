//
//  GameScene.h
//  DoodleDrop
//
//  Created by Max Gu on 5/10/12.
//  Copyright 2012 guxinchi2000@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameScene : CCLayer {
    CCSprite * player;
    CGPoint playerVelocity;
    
    CCArray* spiders;
    float spiderMoveDuration;
    int numSpidersMoved;
    
}

+(id) scene;

@end
