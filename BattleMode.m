/*
 *  BattleMode.m
 *  FortNitta
 *  ECS160 OSX Team
 *  Copyright (c) 2015 OSX Team. All rights reserved.
 */

#import <SpriteKit/SpriteKit.h>
#import <Foundation/Foundation.h>
#import "BattleMode.h"
#import "GameScene.h"
#import "CastleHighLight.h"
#import "AI Controller.h"

#define tileEdge 24
#define tileScale 2
#define animateSet 36
#define noWind 0
#define windN 1
#define windNE 2
#define windE 3
#define windSE 4
#define windS 5
#define windSW 6
#define windW 7
#define windNW 8
#define windStrength 50


@implementation SKView (Right_Mouse)
-(void) mouseMoved:(NSEvent *)theEvent {
    
    [self.scene mouseMoved:theEvent];
}
@end

@implementation BattleMode

SKSpriteNode *cannon; //cannon to add
NSArray *cannonMove; //movable cannon array
NSMutableArray *breakWall;

int shootCount = 0;
BOOL playerShoot = 1;
int currentCannon = 0;
int wind;
int selectedCannonCount;
int player;
int selectedAICastleCount;
int aiColor;
int WallColor = 0;
char playerCharColor;
char aiCharColor;
AI_Controller *AI;
NSTimer *shootTimer;
NSTimer *shootTimer2;
int aiCannon;
int playerCannon;
char checkCharColor;
SKSpriteNode *aiShootCursor;
static int cannonShots = 0;

int smokeDirection; //direction of smoke from player/host cannons
int opponentSmoke; //direction of smoke from ai/opponent cannons

-(instancetype) initWithSize:(CGSize) size{
    if(self = [super initWithSize: size]) {
        
        NSMutableArray *tileTerrainArray = [BattleMode fillTileSet:@"2DTerrain copy"];
        NSMutableArray *tileGridArray = [BattleMode fillTileSet:@"3DFloor copy"];
        NSMutableArray *tileWallArray = [BattleMode fillCastleSet:@"3DWallsAll copy" withTileNumber:189];
        breakWall = [[NSMutableArray alloc]init];
        AI = [[AI_Controller alloc] init:difficulty];
        
        //Information from GameScene
        NSUserDefaults *sceneInfo = [NSUserDefaults standardUserDefaults];
        wind = (int)[sceneInfo integerForKey:@"wind"];
        selectedCannonCount = (int)[sceneInfo integerForKey:@"cannonCount"];
        player = (int)[sceneInfo integerForKey:@"player"];
        //selectedCastleCount = 0;
        selectedAICastleCount = 0;
        aiCannon = 0;
        playerCannon = 0;
        cannonShots = 0;
        shootCount = 0;
        playerShoot = 1;
        
        if (player == 4){
            playerCharColor = 'B';
            aiCharColor = 'R';
            aiColor = 3;
            aiControllerColor = 3;
        } else {
            aiColor = 4;
            aiCharColor = 'B';
            playerCharColor = 'R';
            aiControllerColor = 4;
        }
        //Load 3DMap
        float y = 12 + 24 * tileEdge;
        for (int j = 1; j < 25; j++){
            float x = 12 + tileEdge;
            for (int i = 1; i < 41; i++){
                /**Build 3D Wall**/
                int WallType = 0xF;
                int WallOffset = 0x0;
                
                SKSpriteNode *wall = [[SKSpriteNode alloc] init];
                SKSpriteNode *grid = [[SKSpriteNode alloc] init];
                
                //3D Floor
                if(mapTiles[j][i] == player){
                    grid = [SKSpriteNode spriteNodeWithTexture:[tileGridArray objectAtIndex:-2+player]];
                    grid.position = CGPointMake(x,y);
                    grid.zPosition = 1.4;
                    grid.scale = tileScale;
                    grid.name = @"grid";
                    [self addChild:grid];
                }
                
                //AI 3D Floor
                if(mapTiles[j][i] == aiColor){
                    grid = [SKSpriteNode spriteNodeWithTexture:[tileGridArray objectAtIndex:-2+aiColor]];
                    grid.position = CGPointMake(x,y);
                    grid.zPosition = 1.4;
                    grid.scale = tileScale;
                    grid.name = @"grid";
                    [self addChild:grid];
                }
                
                //Decide wall color
                if (mapArray[j][i] == 'R') {
                    WallColor = 3;
                } else if (mapArray[j][i] == 'B'){
                    WallColor = 4;
                } else if (mapArray[j][i] == 'Y'){
                    WallColor = 2;
                }
                
                //Check sides
                if(mapTiles[j][i] == 1){
                    //north
                    if(mapTiles[j-1][i] == 1){
                        WallType &= 0xE;
                    }
                    //east
                    if(mapTiles[j][i+1] == 1){
                        WallType &= 0xD;
                    }
                    //south
                    if(mapTiles[j+1][i] == 1){
                        WallType &= 0xB;
                    }
                    //west
                    if(mapTiles[j][i-1] == 1){
                        WallType &= 0x7;
                    }
                    //Check corners
                    switch(WallType){
                        case 0: WallOffset = 0xF;
                            if(mapTiles[j-1][i+1] == 1){
                                WallOffset &= 0xE;
                            }
                            if(mapTiles[j-1][i-1] == 1){
                                WallOffset &= 0x7;
                            }
                            if(mapTiles[j+1][i+1] == 1){
                                WallOffset &= 0xD;
                            }
                            if(mapTiles[j+1][i-1] == 1){
                                WallOffset &= 0xB;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        case 1: WallOffset = 0x3;
                            if(mapTiles[j+1][i+1] == 1){
                                WallOffset &= 0x2;
                            }
                            if(mapTiles[j+1][i-1] == 1){
                                WallOffset &= 0x1;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-16-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        case 2: WallOffset = 0x3;
                            if(mapTiles[j+1][i-1] == 1){
                                WallOffset &= 0x2;
                            }
                            if(mapTiles[j-1][i-1] == 1){
                                WallOffset &= 0x1;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-20-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        case 3: WallOffset = 1;
                            if(mapTiles[j+1][i-1] == 1){
                                WallOffset = 0;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-24-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        case 4: WallOffset = 0x3;
                            if(mapTiles[j-1][i+1] == 1){
                                WallOffset &= 0x2;
                            }
                            if(mapTiles[j-1][i-1] == 1){
                                WallOffset &= 0x1;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-26-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        case 6: WallOffset = 1;
                            if(mapTiles[j-1][i-1] == 1){
                                WallOffset = 0;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-31-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        case 8: WallOffset = 0x3;
                            if(mapTiles[j-1][i+1] == 1){
                                WallOffset &= 0x2;
                            }
                            if(mapTiles[j+1][i+1] == 1){
                                WallOffset &= 0x1;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-34-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        case 9: WallOffset = 1;
                            if(mapTiles[j+1][i+1] == 1){
                                WallOffset = 0;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-38-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        case 12:WallOffset = 1;
                            if(mapTiles[j-1][i+1] == 1){
                                WallOffset = 0;
                            }
                            wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-42-WallOffset]];
                            wall.position = CGPointMake(x,y);
                            if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                wall.zPosition = 1.4;
                            } else {
                                wall.zPosition = 1.6;
                            }
                            wall.scale = tileScale;
                            wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                            [self addChild:wall];
                            [breakWall addObject:wall];
                            break;
                        default:WallOffset = 0;
                            if (WallType == 5) {
                                wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-30]];
                                wall.position = CGPointMake(x,y);
                                if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                    wall.zPosition = 1.4;
                                } else {
                                    wall.zPosition = 1.6;
                                }
                                wall.scale = tileScale;
                                wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                                [self addChild:wall];
                                [breakWall addObject:wall];
                            } else if (WallType == 7){
                                wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-33]];
                                wall.position = CGPointMake(x,y);
                                if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                    wall.zPosition = 1.4;
                                } else {
                                    wall.zPosition = 1.6;
                                }
                                wall.scale = tileScale;
                                wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                                [self addChild:wall];
                                [breakWall addObject:wall];
                            } else if (WallType == 10){
                                wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-40]];
                                wall.position = CGPointMake(x,y);
                                if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                    wall.zPosition = 1.4;
                                } else {
                                    wall.zPosition = 1.6;
                                }
                                wall.scale = tileScale;
                                wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                                [self addChild:wall];
                                [breakWall addObject:wall];
                            } else if (WallType == 11){
                                wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-41]];
                                wall.position = CGPointMake(x,y);
                                if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                    wall.zPosition = 1.4;
                                } else {
                                    wall.zPosition = 1.6;
                                }
                                wall.scale = tileScale;
                                wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                                [self addChild:wall];
                                [breakWall addObject:wall];
                            } else if (WallType == 13){
                                wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-44]];
                                wall.position = CGPointMake(x,y);
                                if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                    wall.zPosition = 1.4;
                                } else {
                                    wall.zPosition = 1.6;
                                }
                                wall.scale = tileScale;
                                wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                                [self addChild:wall];
                                [breakWall addObject:wall];
                            } else if (WallType == 14){
                                wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-45]];
                                wall.position = CGPointMake(x,y);
                                if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                    wall.zPosition = 1.4;
                                } else {
                                    wall.zPosition = 1.6;
                                }
                                wall.scale = tileScale;
                                wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                                [self addChild:wall];
                                [breakWall addObject:wall];
                            } else if (WallType == 15){
                                wall = [SKSpriteNode spriteNodeWithTexture:[tileWallArray objectAtIndex:47*WallColor-46]];
                                wall.position = CGPointMake(x,y);
                                if (mapTiles[j+1][i] > 1 && mapTiles[j+1][i] < 5 && mapTiles[j-1][i] == 0){
                                    wall.zPosition = 1.4;
                                } else {
                                    wall.zPosition = 1.6;
                                }
                                wall.scale = tileScale;
                                wall.name = [NSString stringWithFormat:@"wall-%i%i%i",j,i,WallColor];
                                [self addChild:wall];
                                [breakWall addObject:wall];
                            }
                            break;
                    }
                }
                if (mapTiles[j][i] == 0) {
                    SKSpriteNode *grass = [SKSpriteNode spriteNodeWithTexture:[tileTerrainArray objectAtIndex:28]];
                    grass.position = CGPointMake(x,y);
                    grass.scale = tileScale;
                    SKAction * terrainAnimation = [SKAction animateWithTextures:[self createMapTextures: (int)mapTiles[j][i]+(4*wind)] timePerFrame:0.05];
                    [grass runAction:[SKAction repeatActionForever:terrainAnimation]];
                    [self addChild:grass];
                }
                
                int tileSpot = 27, animateBy = 1;
                while ( tileSpot > 11 ){
                    
                    if (mapTiles[j][i] == tileSpot || mapTiles[j][i] == tileSpot-1){
                        SKSpriteNode *river = [SKSpriteNode spriteNodeWithTexture:[tileTerrainArray objectAtIndex:tileSpot]];
                        river.position = CGPointMake(x,y);
                        river.scale = tileScale;
                        SKAction * terrainAnimation = [SKAction animateWithTextures:[self createMapTextures: animateSet*animateBy+(4*wind)] timePerFrame:0.05];
                        [river runAction:[SKAction repeatActionForever:terrainAnimation]];
                        [self addChild:river];
                    }
                    animateBy++;
                    tileSpot -= 2;
                }
                
                int tileSpotTwo = 11, animateByTwo = 9;
                while (tileSpotTwo > 4){
                    
                    if (mapTiles[j][i] == tileSpotTwo){
                        SKSpriteNode *river = [SKSpriteNode spriteNodeWithTexture:[tileTerrainArray objectAtIndex:tileSpotTwo]];
                        river.position = CGPointMake(x,y);
                        river.scale = tileScale;
                        SKAction * terrainAnimation = [SKAction animateWithTextures:[self createMapTextures: animateSet*animateByTwo+(4*wind)] timePerFrame:0.05];
                        [river runAction:[SKAction repeatActionForever:terrainAnimation]];
                        [self addChild:river];
                    }
                    animateByTwo++;
                    tileSpotTwo -= 1;
                }
                x = x + tileEdge;
            }
            y = y - tileEdge;
        }
        
        
        /*Place initial castles*/
        for (int i = 0; i < 10; i++) {
            [self addChild: [self createCastles:i]];
        }
        
        // Placing the cannons
        NSMutableArray *tileCannonArray = [BattleMode fillTileSet:@"3DCannon copy"];
        for (int i = 0; cannonPosX[i] != 0; i++) {
            if (mapTiles[26-(int)round(cannonPosY[i]/24)][(int)round(cannonPosX[i]/24)-1] == aiColor) {
                aiCannon++;
            }
            if (mapTiles[26-(int)round(cannonPosY[i]/24)][(int)round(cannonPosX[i]/24)-1] == player) {
                playerCannon++;
            }
            SKSpriteNode *cannon = [SKSpriteNode spriteNodeWithTexture:[tileCannonArray objectAtIndex:3]];
            cannon.position = CGPointMake(cannonPosX[i], cannonPosY[i]);
            cannon.zPosition = 1.5;
            cannon.name = @"cannon";
            cannon.scale = tileScale;
            [self addChild:cannon];
        }
        SKAction *sound = [SKAction playSoundFileNamed:@"ready2.wav" waitForCompletion:YES];
        SKAction *sound2 = [SKAction playSoundFileNamed:@"fire2.wav" waitForCompletion:NO];
        SKAction *sequence = [SKAction sequence:@[sound, sound, sound2]];
        [self runAction: sequence];
        [self goToRebuildMode];
    }
    
    //Initialize CurrentCannon to 0
    currentCannon = 0;
    if(aiCannon){
        [shootTimer invalidate];
        
        //Unsure if this is actually needed
        shootTimer = [NSTimer scheduledTimerWithTimeInterval:2 invocation:0 repeats:true];
        [self shootTest];
        //        shootTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(shootTest) userInfo:nil repeats:YES];
    }
    
    return self;
}

-(void)playerShot{
    playerShoot = 1;
}

-(void)shootTest{
    int xShoot, yShoot;
    NSMutableArray *aiTarget = [GameScene fillTileSet:@"Target copy"];
    
    CGPoint aiShoot;
    int target = 0;
    
    //Choose a target color
    if(aiColor == 2){
        //Yellow
        target = 0;
    }
    if(aiColor == 3){
        //Red
        target = 1;
    }
    else if(aiColor == 4){
        //Blue
        target = 2;
    }
    
    //Get coordinates for AI
    [AI battle_mode:&xShoot :&yShoot];
    aiShoot = CGPointMake(xShoot*tileEdge+12, (25-yShoot)*tileEdge+12);
    aiShootCursor = [SKSpriteNode spriteNodeWithTexture:[aiTarget objectAtIndex:target]];
    
    //Store Previous cursor position
    aiShootCursor.position = oldCursorPosition;
    
    aiShootCursor.scale = 1.5;
    aiShootCursor.zPosition = 3;
    aiShootCursor.name = @"aiCannonCursor";
    SKAction *followTargetLine = [SKAction moveTo:aiShoot duration:2];
    [self addChild:aiShootCursor];
    
    
    
    //Runs cursor animation until completion,
    [aiShootCursor runAction:followTargetLine completion:^{
        
        //Move the Ai Cursors
        [self checkAiCannonMove: aiShoot];
        //Shoot the cannon
        [self shootCannon:aiShoot color:aiColor player:0];
        
        //Store Old Position
        oldCursorPosition = aiShoot;
        [aiShootCursor removeFromParent];
        
        //Keep Shooting
        if(aiCannon && shootTimer && cannonShots < 5){
            cannonShots++;
            [self shootTest];
            
        }
    }];
    
}

+(void)cannonPosX:(NSInteger)x value:(float)value{
    cannonPosX[x] = value;
}

+(float)cannonPosX:(NSInteger)x{
    return cannonPosX[x];
}

+(void)cannonPosY:(NSInteger)y value:(float)value{
    cannonPosY[y] = value;
}

+(float)cannonPosY:(NSInteger)y{
    return cannonPosY[y];
}


-(void)letter:(NSUInteger)y X:(NSUInteger)x alpha:(NSUInteger)alpha file:(NSMutableArray*)file{
    SKSpriteNode* A;
    A = [SKSpriteNode spriteNodeWithTexture:[file objectAtIndex:alpha]];
    A.scale = 2;
    A.position = CGPointMake(x,y);
    A.zPosition = 1000;
    [self addChild:A];
}

-(void)phraseRebuild{
    NSMutableArray *alphabet = [BattleMode fillCastleSet:@"FontKingthingsWhite copy" withTileNumber:95];
    //set up alphabet
    //Spells "REBUILD WALLS TO STAY ALIVE"
    SKNode *rebuildPhrase= [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:44]];//R
    SKSpriteNode* E1 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:57]];
    [E1 setPosition:CGPointMake(10,0)];//E
    SKSpriteNode* B = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:60]];
    [B setPosition:CGPointMake(20,0)];//B
    SKSpriteNode* U = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:41]];
    [U setPosition:CGPointMake(30,0)];//U
    SKSpriteNode* I1 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:53]];
    [I1 setPosition:CGPointMake(40,0)];//I
    SKSpriteNode* L0 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:50]];
    [L0 setPosition:CGPointMake(45,0)];//L
    SKSpriteNode* D = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:58]];
    [D setPosition:CGPointMake(55,0)];//D
    SKSpriteNode* W = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:39]];
    [W setPosition:CGPointMake(75,0)];//W
    SKSpriteNode* A1 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:61]];
    [A1 setPosition:CGPointMake(85,0)];//A
    SKSpriteNode* L1 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:50]];
    [L1 setPosition:CGPointMake(95,0)];//L
    SKSpriteNode* L2 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:50]];
    [L2 setPosition:CGPointMake(105,0)];//L
    SKSpriteNode* S1 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:43]];
    [S1 setPosition:CGPointMake(115,0)];//S
    SKSpriteNode* T1 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:42]];
    [T1 setPosition:CGPointMake(135,0)];//T
    SKSpriteNode* O = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:47]];
    [O setPosition:CGPointMake(145,0)];//O
    SKSpriteNode* S2 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:43]];
    [S2 setPosition:CGPointMake(165,0)];//S
    SKSpriteNode* T2 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:42]];
    [T2 setPosition:CGPointMake(175,0)];//T
    SKSpriteNode* A2 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:61]];
    [A2 setPosition:CGPointMake(185,0)];//A
    SKSpriteNode* Y = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:37]];
    [Y setPosition:CGPointMake(195,0)];//Y
    SKSpriteNode* A3 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:61]];
    [A3 setPosition:CGPointMake(215,0)];//A
    SKSpriteNode* L3 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:50]];
    [L3 setPosition:CGPointMake(225,0)];//L
    SKSpriteNode* I2 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:53]];
    [I2 setPosition:CGPointMake(235,0)];//I
    SKSpriteNode* V = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:40]];
    [V setPosition:CGPointMake(240,0)];//V
    SKSpriteNode* E2 = [SKSpriteNode spriteNodeWithTexture:[alphabet objectAtIndex:57]];
    [E2 setPosition:CGPointMake(250,0)];//E
    
    [rebuildPhrase addChild:E1];
    [rebuildPhrase addChild:B];
    [rebuildPhrase addChild:U];
    [rebuildPhrase addChild:I1];
    [rebuildPhrase addChild:L0];
    [rebuildPhrase addChild:D];
    [rebuildPhrase addChild:W];
    [rebuildPhrase addChild:A1];
    [rebuildPhrase addChild:L1];
    [rebuildPhrase addChild:L2];
    [rebuildPhrase addChild:S1];
    [rebuildPhrase addChild:T1];
    [rebuildPhrase addChild:O];
    [rebuildPhrase addChild:S2];
    [rebuildPhrase addChild:T2];
    [rebuildPhrase addChild:A2];
    [rebuildPhrase addChild:Y];
    [rebuildPhrase addChild:A3];
    [rebuildPhrase addChild:L3];
    [rebuildPhrase addChild:I2];
    [rebuildPhrase addChild:V];
    [rebuildPhrase addChild:E2];
    
    rebuildPhrase.scale = 2;
    rebuildPhrase.position = CGPointMake(275,525);
    rebuildPhrase.zPosition = 1001;
    [self addChild:rebuildPhrase];
}


-(void)transitionBricks:(NSUInteger)upperLeftX :(NSUInteger)upperLeftY :(NSUInteger)lowerRightX :(NSUInteger)lowerRightY{
    NSMutableArray *bricks = [BattleMode fillCastleSet:@"Bricks copy" withTileNumber:11];
    NSMutableArray *mortar = [BattleMode fillCastleSet:@"Mortar copy" withTileNumber:28];
    NSMutableArray *blue = [BattleMode fillCastleSet:@"2DTerrain copy" withTileNumber:30];
    // NSMutableArray *alphabet = [BattleMode fillCastleSet:@"FontKingthingsWhite copy" withTileNumber:95];
    
    
    
    //[self letter:level X:(horizon + 200) alpha:2 file:bricks];
    //[self letter:(100) X:(700) alpha:8 file:bricks];
    for (unsigned long int ycount = upperLeftY; ycount >= lowerRightY ; ycount -= 20) {
        
        for (unsigned long int xcount = upperLeftX; xcount <= lowerRightX; xcount+=20) {
            [self letter:(ycount) X:(xcount) alpha:3 file:blue];
        }
        
    }
    
    //[self letter:(100) X:(700) alpha:1 file:bricks];
    //[self letter:(90) X:(680) alpha:27 file:mortar];
    for (unsigned long int xcount = upperLeftX +40; xcount <= lowerRightX; xcount+=40) {
        [self letter:(upperLeftY) X:(xcount) alpha:10 file:bricks];//top
        [self letter:lowerRightY X:(xcount) alpha:5 file:bricks];//bottom
        if(xcount >= (lowerRightX + upperLeftX)/2){
            [self letter:(upperLeftY -10) X:(xcount - 20) alpha:24 file:mortar];
            [self letter:(lowerRightY +10) X:(xcount - 20) alpha:16 file:mortar];
        }
        else{
            [self letter:(upperLeftY -10) X:(xcount - 20) alpha:2 file:mortar];
            [self letter:(lowerRightY +10) X:(xcount - 20) alpha:10 file:mortar];
        }
    }
    
    
    
    
    
    for (unsigned long int ycount = lowerRightY+20; ycount <= upperLeftY; ycount += 20) {
        [self letter:(ycount) X:(lowerRightX) alpha:7 file:bricks];//right
        [self letter:ycount X:(upperLeftX) alpha:3 file:bricks];//left
        if ((upperLeftY+2 + lowerRightY)/2 > ycount) {
            [self letter:(ycount) X:(lowerRightX ) alpha:17 file:mortar];
            [self letter:(ycount) X:(upperLeftX ) alpha:9 file:mortar];
        }
        else if ((upperLeftY-2+ lowerRightY)/2 < ycount){
            [self letter:(ycount) X:(lowerRightX ) alpha:23 file:mortar];
            [self letter:(ycount) X:(upperLeftX ) alpha:3 file:mortar];
        }
        else{
            [self letter:(ycount) X:(lowerRightX ) alpha:20 file:mortar];
            [self letter:(ycount) X:(upperLeftX ) alpha:20 file:mortar];
            
        }
        [self letter:(ycount) X:(upperLeftX -10) alpha:13 file:mortar];
        [self letter:(ycount) X:(upperLeftX -23) alpha:13 file:mortar];
        [self letter:(ycount) X:(upperLeftX -25) alpha:13 file:mortar];
        [self letter:(ycount) X:(upperLeftX -27) alpha:13 file:mortar];
        [self letter:(ycount) X:(lowerRightX +25) alpha:13 file:mortar];
        [self letter:(ycount) X:(lowerRightX +27) alpha:13 file:mortar];
        [self letter:(ycount) X:(lowerRightX +29) alpha:13 file:mortar];
        
    }
    
    
    [self letter:upperLeftY X:(upperLeftX) alpha:1 file:bricks];//top right
    [self letter:lowerRightY X:upperLeftX alpha:4 file:bricks];//bottom left
    [self letter:(upperLeftY) X:(lowerRightX) alpha:9 file:bricks];//top right
    [self letter:lowerRightY X:(lowerRightX) alpha:6 file:bricks];//bottom right
    [self letter:(upperLeftY -10) X:(upperLeftX) alpha:2 file:mortar];
    [self letter:(upperLeftY -10) X:(lowerRightX) alpha:24 file:mortar];
    [self letter:(lowerRightY +10) X:(upperLeftX) alpha:10 file:mortar];
    [self letter:(lowerRightY +10) X:(lowerRightX) alpha:16 file:mortar];
    [self letter:(lowerRightY +10) X:(lowerRightX ) alpha:17 file:mortar];
    [self letter:(upperLeftY - 5) X:(lowerRightX ) alpha:23 file:mortar];
    [self letter:(lowerRightY) X:(upperLeftX ) alpha:9 file:mortar];
    [self letter:(upperLeftY - 10) X:(upperLeftX ) alpha:10 file:mortar];
    [self letter:(upperLeftY) X:(upperLeftX -25) alpha:13 file:mortar];
    [self letter:(upperLeftY) X:(upperLeftX -27) alpha:13 file:mortar];
    [self letter:(upperLeftY) X:(upperLeftX -23) alpha:13 file:mortar];
    [self letter:(lowerRightY) X:(upperLeftX -27) alpha:13 file:mortar];
    [self letter:(lowerRightY) X:(upperLeftX -25) alpha:13 file:mortar];
    [self letter:(lowerRightY) X:(upperLeftX -23) alpha:13 file:mortar];
    [self letter:(upperLeftY +10) X:(upperLeftX -25) alpha:13 file:mortar];
    [self letter:(upperLeftY +10) X:(upperLeftX -27) alpha:13 file:mortar];
    [self letter:(upperLeftY +10) X:(upperLeftX -23) alpha:13 file:mortar];
    [self letter:(upperLeftY) X:(lowerRightX +25) alpha:13 file:mortar];
    [self letter:(upperLeftY) X:(lowerRightX +27) alpha:13 file:mortar];
    [self letter:(upperLeftY) X:(lowerRightX +23) alpha:13 file:mortar];
    [self letter:(lowerRightY) X:(lowerRightX +27) alpha:13 file:mortar];
    [self letter:(lowerRightY) X:(lowerRightX +25) alpha:13 file:mortar];
    [self letter:(lowerRightY) X:(lowerRightX +23) alpha:13 file:mortar];
    [self letter:(upperLeftY +10) X:(lowerRightX +25) alpha:13 file:mortar];
    [self letter:(upperLeftY +10) X:(lowerRightX +27) alpha:13 file:mortar];
    [self letter:(upperLeftY +10) X:(lowerRightX +23) alpha:13 file:mortar];
    
    
    for (unsigned long int xcount = upperLeftX - 25; xcount < lowerRightX+15; xcount +=10) {
        [self letter:(lowerRightY -15) X:(xcount ) alpha:20 file:mortar];
        [self letter:(lowerRightY -17) X:(xcount ) alpha:20 file:mortar];
        [self letter:(lowerRightY -19) X:(xcount ) alpha:20 file:mortar];
        [self letter:(upperLeftY +13) X:(xcount ) alpha:20 file:mortar];
        [self letter:(upperLeftY +15) X:(xcount ) alpha:20 file:mortar];
        [self letter:(upperLeftY +17) X:(xcount ) alpha:20 file:mortar];
    }
    //[self phrasePlaceCannons];
    [self phraseRebuild];
    
}

//end test

-(void) goToRebuildMode{
    NSUserDefaults *battleInfo = [NSUserDefaults standardUserDefaults];
    [battleInfo setInteger:selectedCannonCount forKey:@"cannonCount"];
    //[battleInfo setInteger:selectedCastleCount forKey:@"castleCount"];
    [battleInfo setInteger:selectedAICastleCount forKey:@"aiCastleCount"];
    // Goes to rebuild mode after 15 seconds,  3 seconds added for transition to battlemode
    double delayInSeconds = 18;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        /***Enter rebuild mode****/
        battleMode = false;
        GameScene *rebuild = [GameScene sceneWithSize:self.size];
        CGSize s;
        s.width = 1008;
        s.height = 624;
        rebuild.size = s;
        rebuild.scaleMode = SKSceneScaleModeAspectFit;
        [self transitionBricks:50 :600 :960 :470];
        SKTransition* nextScene =[SKTransition revealWithDirection:SKTransitionDirectionDown duration:3 ];
        nextScene.pausesOutgoingScene = FALSE;
        nextScene.pausesIncomingScene = FALSE;
        [self.view presentScene:rebuild transition:nextScene];
    });
    
    //Halt shooting before transition
    double delayInSeconds2 = 11.5;
    dispatch_time_t popTime2 = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds2 * NSEC_PER_SEC));
    dispatch_after(popTime2, dispatch_get_main_queue(), ^(void){
        [shootTimer invalidate];
        [shootTimer2 invalidate];
    });
    
}

-(void)shootCannon:(CGPoint)location color:(int)color player: (int)player1{
    
    
    /******Change cannon balls distance based on wind strength******/
    if(player1 == 1){
        switch (wind) {
            case windN:
                location = CGPointMake(location.x, location.y+windStrength);
                break;
            case windS:
                location = CGPointMake(location.x, location.y-windStrength);
                break;
            case windE:
                location = CGPointMake(location.x+windStrength, location.y);
                break;
            case windW:
                location = CGPointMake(location.x-windStrength, location.y);
                break;
            case windNE:
                location = CGPointMake(location.x+windStrength, location.y+windStrength);
                break;
            case windSE:
                location = CGPointMake(location.x+windStrength, location.y-windStrength);
                break;
            case windNW:
                location = CGPointMake(location.x-windStrength, location.y+windStrength);
                break;
            case windSW:
                location = CGPointMake(location.x-windStrength, location.y-windStrength);
                break;
            default:
                break;
        }
    }
    
    /*****Check if river or wall is hit******/
    bool hitRiver = 0;
    bool hitWall = 0;
    float y = 12 + 24 * tileEdge;
    for (int j = 1; j < 25; j++){
        float x = 12 + tileEdge;
        for (int i = 1; i < 41; i++){
            if (mapTiles[j][i] != 0 && mapTiles[j][i] != 1 && mapTiles[j][i] != 2
                && mapTiles[j][i] != 3 && mapTiles[j][i] != 4 &&
                ( mapTiles[j][i] > 21 || mapTiles[j][i] < 16 )
                && location.x <= x + 12 && location.x >= x - 12
                && location.y >= y - 12 && location.y <= y + 12) {
                hitRiver = 1;
            } else if(mapTiles[j][i] == 1
                      && location.x <= x + 12 && location.x >= x - 12
                      && location.y >= y - 12 && location.y <= y + 12){ // hit a wall
                hitWall = 1;
            }
            x = x + tileEdge;
        }
        y = y - tileEdge;
    }
    
    //checkCharColor = 0;
    if (color == player) {
        checkCharColor = aiCharColor;
    } else if(color == aiColor){
        checkCharColor = playerCharColor;
    }
    
    
    
    /**Skip cannons that arn't on grid from shooting**/
    while (mapTiles[26-(int)round(cannonPosY[currentCannon]/24)][(int)round(cannonPosX[currentCannon]/24)-1] == 0 ||
           mapArray[26-(int)round(cannonPosY[currentCannon]/24)][(int)round(cannonPosX[currentCannon]/24)-1] == checkCharColor
           ){
        if (cannonPosX[currentCannon + 1] == 0){
            currentCannon = 0;
        } else
            currentCannon++;
        
    }
    
    //THIS WORKS FOR AI SHOOTING
    //    while (mapTiles[26-(int)round(cannonPosY[currentCannon]/24)][(int)round(cannonPosX[currentCannon]/24)-1] == player||
    //           mapArray[26-(int)round(cannonPosY[currentCannon]/24)][(int)round(cannonPosX[currentCannon]/24)-1] == playerCharColor
    //           ){
    //        currentCannon++;
    //    }
    
    //Check if out of total cannons
    //if(currentCannon >= selectedCannonCount) currentCannon = 0;
    
    CGPoint posPoint = CGPointMake(cannonPosX[currentCannon], cannonPosY[currentCannon]);
    float distance = sqrt(pow((location.x-cannonPosX[currentCannon]),2)+pow((location.y-cannonPosY[currentCannon]),2));
    
    [self fireBaseCannon:posPoint Destination:location Distance: distance Player:player1];
    double delayInSeconds;
    delayInSeconds = 2.9;
    if (distance > 600) {
        delayInSeconds = 4.9;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (hitRiver) {
            [self waterExplosion:location];
        } else if (hitWall) {
            [self wallExplosion:location];
        } else {
            [self fireExplosion:location];
        }
    });
    
    /*Iterate between cannons to shoot*/
    if (cannonPosX[currentCannon + 1] == 0){
        currentCannon = 0;
    } else
        currentCannon++;
}

-(void)mouseDown:(NSEvent *)theEvent {
    CGPoint location = [theEvent locationInNode:self];
    
    if (shootCount == playerCannon){
        //NSLog(@"player cannon %d", playerCannon);
        playerShoot = 0;
        shootCount = 0;
        [shootTimer2 invalidate];
        shootTimer2 = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(playerShot) userInfo:nil repeats:YES];
    }
    
    if (playerCannon && playerShoot) {
        [self shootCannon:location color:player player:1];
        shootCount++;
    }
    
}

-(SKSpriteNode *) createCastles: (int) pos{
    
    NSMutableArray *tileCastleArray = [BattleMode fillCastleSet:@"3DCastles copy" withTileNumber:109];
    SKSpriteNode *castle = [[SKSpriteNode alloc]init];
    
    int castleXCoordinate[] = {5, 8, 6, 15, 25, 37, 36, 36, 26, 18};
    int castleYCoordinate[] = {7, 13, 19, 19, 18, 20, 12, 6, 7, 6};
    
    if (mapTiles[26-castleYCoordinate[pos]][castleXCoordinate[pos]-1] == player) {
        castle = [SKSpriteNode spriteNodeWithTexture:[tileCastleArray objectAtIndex:-36+36*player]];
        castle.position = CGPointMake(castleXCoordinate[pos]*tileEdge,castleYCoordinate[pos]*tileEdge);
        castle.zPosition = 1.5;
        castle.scale = tileScale;
        SKAction * terrainAnimation = [SKAction animateWithTextures:[self createCastleTextures: 1+(4*wind) color:player] timePerFrame:0.2];
        [castle runAction:[SKAction repeatActionForever:terrainAnimation]];
        //selectedCastleCount++;
    } else if (mapTiles[26-castleYCoordinate[pos]][castleXCoordinate[pos]-1] == aiColor) {
        castle = [SKSpriteNode spriteNodeWithTexture:[tileCastleArray objectAtIndex:-36+36*aiColor]];
        castle.position = CGPointMake(castleXCoordinate[pos]*tileEdge,castleYCoordinate[pos]*tileEdge);
        castle.zPosition = 1.5;
        castle.scale = tileScale;
        SKAction * terrainAnimation = [SKAction animateWithTextures:[self createCastleTextures: 1+(4*wind) color:aiColor] timePerFrame:0.2];
        [castle runAction:[SKAction repeatActionForever:terrainAnimation]];
        selectedAICastleCount++;
    } else {
        castle = [SKSpriteNode spriteNodeWithTexture:[tileCastleArray objectAtIndex:108]];
        castle.position = CGPointMake(castleXCoordinate[pos]*tileEdge,castleYCoordinate[pos]*tileEdge);
        castle.zPosition = 1.5;
        castle.scale = tileScale;
        [castle setName:(NSString *)@"castle"];
    }
    return castle;
}

-(NSArray *) createMapTextures: (int) i {
    NSMutableArray *tileGrassArray = [BattleMode fillTileSet:@"3DTerrain copy"];
    
    SKTexture *tex_1 = [tileGrassArray objectAtIndex:[tileGrassArray count]-i-1];
    SKTexture *tex_2 = [tileGrassArray objectAtIndex:[tileGrassArray count]-i-2];
    SKTexture *tex_3 = [tileGrassArray objectAtIndex:[tileGrassArray count]-i-3];
    SKTexture *tex_4 = [tileGrassArray objectAtIndex:[tileGrassArray count]-i-4];
    
    NSArray *grassTextures = @[tex_1, tex_2, tex_3, tex_4];
    
    return grassTextures;
}


-(NSArray *) createCastleTextures: (int) i color: (int) type {
    NSMutableArray *tileCastleArray = [BattleMode fillCastleSet:@"3DCastles copy" withTileNumber:109];
    
    SKTexture *tex_1 = [tileCastleArray objectAtIndex:-35+36*type-i-1];
    SKTexture *tex_2 = [tileCastleArray objectAtIndex:-35+36*type-i-2];
    SKTexture *tex_3 = [tileCastleArray objectAtIndex:-35+36*type-i-3];
    SKTexture *tex_4 = [tileCastleArray objectAtIndex:-35+36*type-i-4];
    
    NSArray *castleTextures = @[tex_1, tex_2, tex_3, tex_4];
    
    return castleTextures;
}

-(SKSpriteNode *) createCannonBall {
    NSMutableArray *tileBallArray = [GameScene fillTileSet:@"3DCannonball copy"];
    SKSpriteNode * cannonBall = [SKSpriteNode spriteNodeWithTexture:[tileBallArray objectAtIndex:0]];
    cannonBall.name = @"cannonball";
    cannonBall.scale = tileScale;
    cannonBall.zPosition = 2;
    return cannonBall;
}


-(NSArray *) createCannonBallTextures:(float) dist{
    NSMutableArray *tileBallArray = [GameScene fillTileSet:@"3DCannonball copy"];
    
    SKTexture *tex_1 = [tileBallArray objectAtIndex:11];
    SKTexture *tex_2 = [tileBallArray objectAtIndex:10];
    SKTexture *tex_3 = [tileBallArray objectAtIndex:9];
    SKTexture *tex_4 = [tileBallArray objectAtIndex:8];
    SKTexture *tex_5 = [tileBallArray objectAtIndex:7];
    SKTexture *tex_6 = [tileBallArray objectAtIndex:6];
    SKTexture *tex_7 = [tileBallArray objectAtIndex:5];
    SKTexture *tex_8 = [tileBallArray objectAtIndex:4];
    SKTexture *tex_9 = [tileBallArray objectAtIndex:3];
    SKTexture *tex_10 = [tileBallArray objectAtIndex:2];
    SKTexture *tex_11 = [tileBallArray objectAtIndex:1];
    SKTexture *tex_12 = [tileBallArray objectAtIndex:0];
    
    NSArray *cannonBallFarTextures = @[tex_1, tex_2, tex_3, tex_4, tex_5, tex_6, tex_7, tex_8, tex_9, tex_10, tex_11, tex_12,
                                       tex_11, tex_10, tex_9, tex_8, tex_7, tex_6, tex_5, tex_4, tex_3, tex_2, tex_1];
    
    NSArray *cannonBallTextures = @[tex_1, tex_2, tex_3, tex_4, tex_5, tex_6, tex_5, tex_4, tex_3, tex_2, tex_1];
    
    if (dist > 600) {
        return cannonBallFarTextures;
    }
    return cannonBallTextures;
}

// main method to fire cannonball
// creates cannonball SKSpriteNode and specifies starting point and destination
-(void)fireBaseCannon: (CGPoint) origin
          Destination:(CGPoint) dest
             Distance:(float) dist
               Player: (int) player1 {
    
    float durTime = 3.0;
    SKSpriteNode * cannonBall = [self createCannonBall];
    cannonBall.position = origin;               // arbitrary starting point for now
    CGPoint cannonBallDestination = dest; // arbitrary destination for now
    
    if (dist > 600) {
        durTime = 5.0;
    }
    
    [self fireCannonBall:cannonBall Destination:cannonBallDestination Distance:dist Duration:durTime soundFileName:@"cannon0.wav"];
    [self smokeAnimation:origin player:player1];
}


// utility method for fireBaseCannon
// specifies SKAction of cannonball
-(void)fireCannonBall:(SKNode*)cannonBall
          Destination:(CGPoint)dest
             Distance:(float) dist
             Duration:(NSTimeInterval)dur
        soundFileName:(NSString*)soundFile {
    
    float distTime = 0.3;
    SKAction * cannonBallAction = [SKAction sequence:@[[SKAction moveTo:dest duration:dur],
                                                       [SKAction waitForDuration:1],
                                                       [SKAction removeFromParent]]];
    SKAction * soundAction  = [SKAction playSoundFileNamed:soundFile waitForCompletion:YES];
    
    if (dist > 600) {
        distTime = 0.225;
    }
    
    SKAction * cannonBallAnimation = [SKAction animateWithTextures:[self createCannonBallTextures:dist] timePerFrame:distTime];
    [cannonBall runAction:[SKAction group:@[cannonBallAction, soundAction, cannonBallAnimation]]];
    [self addChild:cannonBall];
}

//commentsssss

/** CANNON SMOKE ANIMATIONS **/

//create textures for smoke animations from cannons
-(NSArray *) createSmokeTextures: (int) player1{
    
    NSMutableArray *smokeArray = [BattleMode fillCastleSet:@"3DCannonPlume copy" withTileNumber:64 ];
    
    int direction;
    
    if(player1 == 1) {
        direction = smokeDirection;
    }
    else {
        direction = opponentSmoke;
    }
    
    SKTexture *tex_0 = [smokeArray objectAtIndex:direction];
    SKTexture *tex_1 = [smokeArray objectAtIndex:direction - 1];
    SKTexture *tex_2 = [smokeArray objectAtIndex:direction - 2];
    SKTexture *tex_3 = [smokeArray objectAtIndex:direction - 3];
    SKTexture *tex_4 = [smokeArray objectAtIndex:direction - 4];
    SKTexture *tex_5 = [smokeArray objectAtIndex:direction - 5];
    SKTexture *tex_6 = [smokeArray objectAtIndex:direction - 6];
    SKTexture *tex_7 = [smokeArray objectAtIndex:direction - 7];
    
    NSArray *smokeTextures = @[tex_0, tex_1, tex_2, tex_3, tex_4, tex_5, tex_6, tex_7];
    
    return smokeTextures;
}

//produce smoke animation (call from fireBaseCannon)
-(void) smokeAnimation:(CGPoint) cannon player:(int) player1 {
    
    //direction depends if player 1 or oppenent fired
    int direction;
    if(player1 == 1) {
        direction = smokeDirection;
    }
    else{
        direction = opponentSmoke;
    }
    
    NSMutableArray *smokeArray = [BattleMode fillCastleSet:@"3DCannonPlume copy" withTileNumber:64 ];
    SKSpriteNode *smoke = [SKSpriteNode spriteNodeWithTexture:[smokeArray objectAtIndex:direction]];
    
    cannon.y = cannon.y + 10;
    
    smoke.position = cannon;
    smoke.scale = 1.5;
    smoke.zPosition = 2;
    
    SKAction *smokePlume = [SKAction sequence:@[[SKAction animateWithTextures:[self createSmokeTextures: player1] timePerFrame:0.1],[SKAction removeFromParent]]];
    
    [self addChild:smoke];
    [smoke runAction:smokePlume];
}


-(NSArray *) createExplosionTextures:(bool) wall {
    NSMutableArray *tileExplosionArray = [BattleMode fillCastleSet:@"3DExplosions copy.png" withTileNumber:54];
    
    SKTexture *tex_6 = [tileExplosionArray objectAtIndex:8];
    SKTexture *tex_7 = [tileExplosionArray objectAtIndex:7];
    SKTexture *tex_8 = [tileExplosionArray objectAtIndex:6];
    SKTexture *tex_9 = [tileExplosionArray objectAtIndex:5];
    SKTexture *tex_10 = [tileExplosionArray objectAtIndex:4];
    SKTexture *tex_11 = [tileExplosionArray objectAtIndex:3];
    SKTexture *tex_12 = [tileExplosionArray objectAtIndex:2];
    SKTexture *tex_13 = [tileExplosionArray objectAtIndex:1];
    SKTexture *tex_14 = [tileExplosionArray objectAtIndex:0];
    
    if(wall == 1) {
        tex_6 = [tileExplosionArray objectAtIndex:53];
        tex_7 = [tileExplosionArray objectAtIndex:52];
        tex_8 = [tileExplosionArray objectAtIndex:51];
        tex_9 = [tileExplosionArray objectAtIndex:50];
        tex_10 = [tileExplosionArray objectAtIndex:49];
        tex_11 = [tileExplosionArray objectAtIndex:48];
        tex_12 = [tileExplosionArray objectAtIndex:47];
        tex_13 = [tileExplosionArray objectAtIndex:46];
        tex_14 = [tileExplosionArray objectAtIndex:45];
    }
    
    NSArray *explosionTextures = @[tex_6, tex_7, tex_8, tex_9, tex_10, tex_11, tex_12, tex_13, tex_14];
    return explosionTextures;
}

-(SKSpriteNode *) createExplosion {
    NSMutableArray *tileBallArray = [GameScene fillTileSet:@"3DExplosions copy"];
    SKSpriteNode * explosion = [SKSpriteNode spriteNodeWithTexture:[tileBallArray objectAtIndex:[tileBallArray count]-1]];
    explosion.name = @"explosion";
    explosion.zPosition = 2;
    return explosion;
}

-(void) explode:(SKNode*)explosion
    Destination:(CGPoint)dest
       Duration:(NSTimeInterval)dur
  soundFileName:(NSString*)soundFile
        inWater:(bool)splash
           wall:(bool)hit{
    
    SKAction * explosionAction = [SKAction sequence:@[[SKAction moveTo:dest duration:dur],
                                                      [SKAction waitForDuration:60.0/60.0],
                                                      [SKAction removeFromParent]]];
    SKAction * explosionAnimation = [[SKAction alloc]init];
    
    if (splash == 0) {
        explosionAnimation = [SKAction animateWithTextures:[self createExplosionTextures:hit] timePerFrame:0.05];
    } else {
        explosionAnimation = [SKAction animateWithTextures:[self createWaterExplosionTextures] timePerFrame:0.05];
    }
    
    SKAction * soundAction  = [SKAction playSoundFileNamed:soundFile waitForCompletion:YES];
    [explosion runAction:[SKAction group:@[explosionAction, explosionAnimation, soundAction]]];
    [self addChild:explosion];
}

-(void) fireExplosion:(CGPoint) dest {
    SKSpriteNode * explosion = [self createExplosion];
    explosion.position = dest;
    explosion.scale = tileScale;
    [self explode:explosion Destination:dest Duration:0.05 soundFileName:@"explosion3.wav" inWater:0 wall:0];
}

-(void) waterExplosion:(CGPoint) dest {
    SKSpriteNode * explosion = [self createExplosion];
    explosion.position = dest;
    explosion.scale = 1.5;
    [self explode:explosion Destination:dest Duration:0.05 soundFileName:@"waterexplosion0.wav" inWater:1 wall:0];
}

-(void) wallExplosion:(CGPoint) dest {
    SKSpriteNode * explosion = [self createExplosion];
    explosion.position = dest;
    explosion.scale = 2.5;
    explosion.zPosition = 12;
    
    int player1Color = 0; //record the blue color walls
    int player2Color = 0; //record the red color walls
    int player3Color = 0; //record the yellow color walls
    
    [self explode:explosion Destination:dest Duration:0.05 soundFileName:@"explosion0.wav" inWater:0 wall:1];
    
    int j = dest.x/24 -1; //set the x position to be in mapBattle coordinates
    int i = 26- dest.y/24; //set the y position
    mapTiles[i][j+1] = 0; //set the index to zero, we want grass on the next scene not a wall
    int convertj = j+1; //convert our j to the i in wall ids
    int converti = 0;
    //our i is reversed in the IDs, we must convert
    switch (i) {
        case 0:
            converti=21;
            break;
        case 1:
            converti=20;
            break;
        case 2:
            converti=19;
            break;
        case 3:
            converti=18;
            break;
        case 4:
            converti=17;
            break;
        case 5:
            converti=16;
            break;
        case 6:
            converti=15;
            break;
        case 7:
            converti=14;
            break;
        case 8:
            converti=13;
            break;
        case 9:
            converti=12;
            break;
        case 10:
            converti=11;
            break;
        case 11:
            converti=10;
            break;
        case 12:
            converti=9;
            break;
        case 13:
            converti=8;
            break;
        case 14:
            converti=7;
            break;
        case 15:
            converti=6;
            break;
        case 16:
            converti=5;
            break;
        case 17:
            converti= 4;
            break;
        case 18:
            converti=3;
            break;
        case 19:
            converti=2;
            break;
        case 20:
            converti=1;
            break;
        case 21:
            converti=0;
            break;
        default:
            break;
    }
    
    
    SKNode *node = [self nodeAtPoint:dest];
    node.name = [NSString stringWithFormat:@"wall-%i%i%i", i,convertj, 4]; //name the node beginning with blue
    // NSLog(@"%@", node.name);
    
    for(SKSpriteNode *object in breakWall){
        if([object.name isEqualToString:node.name]){
            [object removeFromParent];
            player1Color = 64; //we hit a blue wall
        }
        else{
            node.name = [NSString stringWithFormat:@"wall-%i%i%i", i,convertj, 3];
            if([object.name isEqualToString:node.name]){
                [object removeFromParent];
                player2Color = 32; //We hit a red wall
            }
            else{
                node.name = [NSString stringWithFormat:@"wall-%i%i%i", i,convertj, 2];
                if([object.name isEqualToString:node.name]){
                    [object removeFromParent];
                    player3Color = 2; //we hit a yellow wall
                }
                else{
                    node.name = [NSString stringWithFormat:@"wall-%i%i%i", i,convertj, 4];
                    if([object.name isEqualToString:node.name]){
                        [object removeFromParent];
                        player1Color = 64; //we hit a blue, not sure why but this must be called 2x to work
                    }
                }
            }
        }
        
    }//finish checking if we hit a wall
    
    dest.x = (j+1)*24 +12; //fit rubble piles perfectly between walls
    dest.y = (26-i)*24 -12; //fit rubble piles perfectly between walls
    NSMutableArray *rubbleArray = [BattleMode fillTileSet:@"3DWallsAll copy"];
    
    
    SKSpriteNode *rubble = [SKSpriteNode spriteNodeWithTexture:[rubbleArray objectAtIndex:0]];
    rubble.position = dest;
    rubble.scale = tileScale;
    rubble.zPosition = 10;
    [self addChild:rubble];
    
    SKSpriteNode *debris = [SKSpriteNode spriteNodeWithTexture:[rubbleArray objectAtIndex:1]];
    debris.position = dest;
    debris.scale = tileScale;
    debris.zPosition = 11; //above rubble pile, debris animate
    [self addChild:debris];
    
    if (player1Color !=0){
        [rubble runAction: [SKAction setTexture:rubbleArray[player1Color]]];
        SKAction * rubbleAnimation = [SKAction animateWithTextures:[self createRubble: player1Color] timePerFrame:0.03];
        [debris runAction:rubbleAnimation];
    }
    if (player2Color !=0){
        [rubble runAction: [SKAction setTexture:rubbleArray[player2Color]]];
        SKAction * rubbleAnimation = [SKAction animateWithTextures:[self createRubble: player2Color] timePerFrame:0.03];
        [debris runAction:rubbleAnimation];
    }
    if (player3Color !=0){
        [rubble runAction: [SKAction setTexture:rubbleArray[player3Color]]];
        SKAction * rubbleAnimation = [SKAction animateWithTextures:[self createRubble: player3Color] timePerFrame:0.03];
        [debris runAction:rubbleAnimation];
    }
    
}



-(NSArray *) createRubble: (int) playerColor{
    NSMutableArray *rubbleArray = [BattleMode fillTileSet:@"3DWallsAll copy"];
    
    SKTexture *tex_1 = [rubbleArray objectAtIndex:playerColor + 1];
    SKTexture *tex_2 = [rubbleArray objectAtIndex:playerColor + 3];
    SKTexture *tex_3 = [rubbleArray objectAtIndex:playerColor + 5];
    SKTexture *tex_4 = [rubbleArray objectAtIndex:playerColor + 7];
    SKTexture *tex_5 = [rubbleArray objectAtIndex:playerColor + 9];
    SKTexture *tex_6 = [rubbleArray objectAtIndex:playerColor + 11];
    SKTexture *tex_7 = [rubbleArray objectAtIndex:playerColor + 13];
    SKTexture *tex_8 = [rubbleArray objectAtIndex:playerColor + 15];
    SKTexture *tex_9 = [rubbleArray objectAtIndex:playerColor + 17];
    SKTexture *tex_10 = [rubbleArray objectAtIndex:playerColor + 19];
    SKTexture *tex_11 = [rubbleArray objectAtIndex:playerColor + 21];
    SKTexture *tex_12 = [rubbleArray objectAtIndex:playerColor + 23];
    SKTexture *tex_13 = [rubbleArray objectAtIndex:playerColor + 25];
    SKTexture *tex_14 = [rubbleArray objectAtIndex:playerColor + 27];
    SKTexture *tex_15 = [rubbleArray objectAtIndex:playerColor + 29];
    SKTexture *tex_16 = [rubbleArray objectAtIndex:playerColor + 31];
    NSArray *rubbleExplosionTextures = @[tex_1, tex_2, tex_3, tex_4, tex_5, tex_6,tex_7, tex_8, tex_9, tex_10, tex_11, tex_12 ,tex_13, tex_14, tex_15, tex_16];
    
    return rubbleExplosionTextures;
}

-(NSArray *) createWaterExplosionTextures {
    NSMutableArray *tileWaterExplosionArray = [BattleMode fillCastleSet:@"3DExplosions copy.png" withTileNumber:54];
    
    SKTexture *tex_1 = [tileWaterExplosionArray objectAtIndex:[tileWaterExplosionArray count]-19];
    SKTexture *tex_2 = [tileWaterExplosionArray objectAtIndex:[tileWaterExplosionArray count]-20];
    SKTexture *tex_3 = [tileWaterExplosionArray objectAtIndex:[tileWaterExplosionArray count]-21];
    SKTexture *tex_4 = [tileWaterExplosionArray objectAtIndex:[tileWaterExplosionArray count]-22];
    SKTexture *tex_5 = [tileWaterExplosionArray objectAtIndex:[tileWaterExplosionArray count]-23];
    SKTexture *tex_6 = [tileWaterExplosionArray objectAtIndex:[tileWaterExplosionArray count]-24];
    
    NSArray *waterExplosionTextures = @[tex_1, tex_2, tex_3, tex_4, tex_5, tex_6];
    return waterExplosionTextures;
}

+(NSMutableArray*)fillTileSet: (NSString*)tileSet{
    int fillArray = 0;
    
    SKTexture *curTile = [SKTexture textureWithImageNamed:tileSet];
    curTile.filteringMode = SKTextureFilteringNearest;
    
    //Single target dimensions
    float tileHeight = curTile.size.height;
    float tileWidth = curTile.size.width;
    
    // Calculate number of tiles in the tile set
    NSUInteger tileCount = (tileHeight/tileWidth);
    NSMutableArray *tileArray = [NSMutableArray arrayWithCapacity:tileCount];
    
    //Fill tileArray with individual tiles
    while (fillArray < tileCount) {
        [tileArray addObject:[SKTexture textureWithRect:CGRectMake(0,((float)fillArray/tileCount), 1, (1.0/tileCount)) inTexture:curTile]];
        fillArray++;
    }
    return tileArray;
}

+(NSMutableArray*)fillCastleSet: (NSString*)tileSet withTileNumber: (int)tileCount{
    int fillArray = 0;
    
    SKTexture *curTile = [SKTexture textureWithImageNamed:tileSet];
    curTile.filteringMode = SKTextureFilteringNearest;
    
    NSMutableArray *tileArray = [NSMutableArray arrayWithCapacity:tileCount];
    
    //Fill tileArray with individual tiles
    while (fillArray < tileCount) {
        [tileArray addObject:[SKTexture textureWithRect:CGRectMake(0,((float)fillArray/tileCount), 1, (1.0/tileCount)) inTexture:curTile]];
        fillArray++;
    }
    return tileArray;
}


-(void)mouseMoved:(NSEvent *)theEvent{
    
    //CGPoint position
    for (int i = 0; cannonPosX[i] != 0; i++) {
        //Convert cannonPos coordinates to mapArray coordinates
        NSInteger setY = 26 - round(cannonPosY[i]/24);
        NSInteger setX = round(cannonPosX[i]/24) - 1;
        CGPoint position = CGPointMake(cannonPosX[i],cannonPosY[i]);
        NSArray *nodes = [self nodesAtPoint:position];
        SKTexture* temp;
        for(SKSpriteNode *object in nodes){
            if([object.name isEqual: @"cannon"] && mapArray[setY][setX] == playerCharColor && mapTiles[setY][setX] != 0){
                // pass in location of node to cannonMove because mouseLocation from scene is different from view coordinates
                CGPoint viewPos = [theEvent locationInNode:self];
                temp = [self cannonMove: i mouseLoc:viewPos];
                object.texture = temp;
            }
        }
    }
}


/* Ai Cannons follow cursor */
-(void)checkAiCannonMove: (CGPoint) aiPos{
    
    for (int i = 0; cannonPosX[i] != 0; i++) {
        //Convert cannonPos coordinates to mapArray coordinates
        NSInteger setY = 26 - round(cannonPosY[i]/24);
        NSInteger setX = round(cannonPosX[i]/24) - 1;
        CGPoint position = CGPointMake(cannonPosX[i],cannonPosY[i]);
        NSArray *nodes = [self nodesAtPoint:position];
        SKTexture* temp;
        for(SKSpriteNode *object in nodes){
            if([object.name isEqual: @"cannon"] && mapArray[setY][setX] == aiCharColor && mapTiles[setY][setX] != 0){
                // pass in location of node to cannonMove because mouseLocation from scene is different from view coordinates
                CGPoint viewPos = [self.view convertPoint:aiPos fromScene:self.scene];
                temp = [self cannonMove: i mouseLoc:viewPos];
                object.texture = temp;
            }
        }
    }
}

-(SKTexture *)cannonMove: (int) cPos mouseLoc: (CGPoint) temp{
    NSMutableArray *tileCannonArray = [BattleMode fillTileSet:@"3DCannon copy"];
    CGFloat canX = cannonPosX[cPos];
    CGFloat canY = cannonPosY[cPos];
    CGFloat mouseX = temp.x;
    CGFloat mouseY = temp.y;
    
    int index;
    
    // get the distance from mouse location to cannon
    double XDistance = mouseX - canX;
    double YDistance = mouseY - canY;
    
    // get the angle in radians
    double radAngle = atan2(YDistance, XDistance);
    // atan2 returns -PI to PI so add 2PI to get 0 to 2PI values
    if(radAngle < 0) {
        radAngle += (2 * M_PI);
    }
    
    // convert radians to degrees
    double degreeAngle = radAngle * (180.0/M_PI);
    
    // NESW are given 20 degrees of the circle each, rest are 70 degrees each
    if(degreeAngle < 10) { // E
        index = 5;
    }
    else if(degreeAngle > 350) {
        index = 5;
    }
    else if(degreeAngle < 80 && degreeAngle > 10) { // NE
        index = 6;
    }
    else if(degreeAngle < 100 && degreeAngle > 80) { // N
        index = 7;
    }
    else if(degreeAngle < 170 && degreeAngle > 100) { // NW
        index = 0;
    }
    else if(degreeAngle < 190 && degreeAngle > 170) { // W
        index = 1;
    }
    else if(degreeAngle < 260 && degreeAngle > 190) { // SW
        index = 2;
    }
    else if(degreeAngle < 280 && degreeAngle > 260) { // S
        index = 3;
    }
    else { //else if(degreeAngle < 345 && degreeAngle > 285) // SE
        index = 4;
    }
    
    smokeDirection = (index * 7) + index + 7;
    opponentSmoke = (index * 7) + index + 7;
    
    
    return [tileCannonArray objectAtIndex:index];
}

/* Changes cursor to the target icon. */
- (void) doChangeCursorTarget{
    //Initialize cursor Color to Yellow
    int cursorColor = 0;
    
    //If Cursor is red
    if(player == 2){
        cursorColor = 2;
    }
    //If Cursor is red
    else if(player == 4){
        cursorColor = 4;
    }
    //Initialize and creates and image of the Color Target
    NSImage * img = [NSImage imageNamed:@"Target copy"];
    NSImage* target = [[NSImage alloc] initWithSize:NSMakeSize(24, 24)];
    [target lockFocus];
    [img drawAtPoint:NSMakePoint(0, 0) fromRect:NSMakeRect(0, 12*cursorColor, 24, 24) operation:NSCompositeSourceOver fraction:1.0];
    [target setSize: CGSizeMake(tileEdge*1.5, tileEdge*1.5)];
    [target unlockFocus];
    
    //Places the cursor at the center point in the box.
    NSCursor *aimcursor = [[NSCursor alloc] initWithImage:target hotSpot: NSMakePoint(18,18)];
    [aimcursor set];
}

/* Calls everytime to handle cursor */
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    if(battleMode){
        //Calls ChangeCursor
        [self performSelector:@selector(doChangeCursorTarget) withObject:nil afterDelay:0];
    }
    else{
        [[NSCursor arrowCursor] set];
    }
}



@end