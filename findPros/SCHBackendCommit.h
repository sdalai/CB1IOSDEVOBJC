//
//  SCHBackendCommit.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 8/20/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHBackendCommit : NSObject

+ (instancetype)sharedManager;


@property (nonatomic, strong) NSMutableArray *objectsStagedForSave;
@property (nonatomic, strong) NSMutableArray *objectsStagedForPinning;
@property (nonatomic, strong) NSMutableArray *objectsStagedForDelete;
@property (nonatomic, strong) NSMutableArray *objectsStagedForUnpin;

-(void) addObjectsoPinningQueue:(NSArray *) objects;
-(void) addObjectToPinningQueue:(id) object;
-(void) remveObjectsFromPinningQueue:(NSArray *) objects;
-(void) remveObjectFromPinningQueue:(id) object;
-(void) removeAllObjectsFromPinningQueue;

-(void) addObjectsoUnpinningQueue:(NSArray *) objects;
-(void) addObjectToUnpinningQueue:(id) object;
-(void) remveObjectsFromUnpinningQueue:(NSArray *) objects;
-(void) remveObjectFromUnpinningQueue:(id) object;
-(void) removeAllObjectsFromUnpinningQueue;
 

-(BOOL)pinObjects;
-(BOOL)unPinObjects;
 




-(BOOL)addObjectToCommitQueue:(id) object commitAction:(NSString *) action commitMode:(NSString *) commitMode;
-(BOOL)addObjectsToCommitQueue:(NSArray *) objects commitAction:(NSString *) action commitMode:(NSString *) commitMode;
-(void)removeAllobjectsFromCommitQueue;
-(void)removeFromCommitQueue:(NSDictionary *)commitObject;

-(BOOL)serverCommit;

-(void)refreshQueues;

-(void)refrshStagedQueue;








//-(void)addToCommitQueue:(NSDictionary *)commitObject;



//-(BOOL)createCommitPoint;

//-(BOOL)commit:(BOOL)backgroundMode;

//-(BOOL)rollback;

//-(BOOL)writeToSrver;


@end
