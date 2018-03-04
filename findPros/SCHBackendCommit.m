//
//  SCHBackendCommit.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 8/20/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHBackendCommit.h"
#import "SCHConstants.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"

@interface SCHBackendCommit()
@property (nonatomic, strong) NSMutableArray *pinningQueue;
@property (nonatomic, strong) NSMutableArray *unpinningqueue;
@property (nonatomic, strong) NSMutableArray *commitQueue;
@property (nonatomic, strong) NSMutableArray *rollbackQueue;

@end

@implementation SCHBackendCommit
static SCHBackendCommit *sharedBackendCommit = nil;
+ (instancetype)sharedManager
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBackendCommit = [[SCHBackendCommit alloc] init];
        sharedBackendCommit->_commitQueue = [[NSMutableArray alloc] init];
        sharedBackendCommit->_rollbackQueue = [[NSMutableArray alloc] init];
        sharedBackendCommit->_pinningQueue = [[NSMutableArray alloc] init];
        sharedBackendCommit->_unpinningqueue = [[NSMutableArray alloc] init];
        sharedBackendCommit->_objectsStagedForSave = [[NSMutableArray alloc] init];
        sharedBackendCommit ->_objectsStagedForPinning = [[NSMutableArray alloc] init];
        sharedBackendCommit ->_objectsStagedForDelete = [[NSMutableArray alloc] init];
        sharedBackendCommit->_objectsStagedForUnpin = [[NSMutableArray alloc] init];
        
        
    });
    
    return sharedBackendCommit;
}



-(void) addObjectsoPinningQueue:(NSArray *) objects{
    
    [self.pinningQueue addObjectsFromArray:objects];
    
}

-(void) addObjectToPinningQueue:(id) object{
    [self.pinningQueue addObject:object];
}

-(void) remveObjectsFromPinningQueue:(NSArray *) objects{
    [self.pinningQueue removeObjectsInArray:objects];
}

-(void) remveObjectFromPinningQueue:(id) object{
    [self.pinningQueue removeObject:object];
}
-(void) removeAllObjectsFromPinningQueue{
    [self.pinningQueue removeAllObjects];
}

-(void) addObjectsoUnpinningQueue:(NSArray *) objects{
    [self.unpinningqueue addObjectsFromArray:objects];
}
-(void) addObjectToUnpinningQueue:(id) object{
    [self.unpinningqueue addObject:object];
}
-(void) remveObjectsFromUnpinningQueue:(NSArray *) objects{
    [self.unpinningqueue removeObjectsInArray:objects];
}
-(void) remveObjectFromUnpinningQueue:(id) object{
    [self.unpinningqueue removeObject:object];
}
-(void) removeAllObjectsFromUnpinningQueue{
    [self.unpinningqueue removeAllObjects];
}

-(BOOL)pinObjects{
    
    NSSet *pinningSet = [[NSSet alloc] initWithArray:self.pinningQueue];
    BOOL success = [PFObject pinAll:[pinningSet allObjects]];
    if (success){
        [self removeAllObjectsFromPinningQueue];
    }
    return success;
}
-(BOOL)unPinObjects{
    NSSet *unpinningSet = [[NSSet alloc] initWithArray:self.unpinningqueue];
    BOOL success = [PFObject unpinAll:[unpinningSet allObjects]];
    if (success){
        [self removeAllObjectsFromUnpinningQueue];
    }
    
    return success;
}

-(BOOL)addObjectToCommitQueue:(id) object commitAction:(NSString *) action commitMode:(NSString *) commitMode{

    
    if (([action isEqualToString:SCHServerCommitSave] || [action isEqualToString:SCHServerCommitDelete] || [action isEqualToString:SCHServerCommitUpdate]) && ([commitMode isEqualToString:SCHServerCommitModeAsynchronous]|| [commitMode isEqualToString:SCHserverCommitModeEventually]|| [commitMode isEqualToString:SCHServerCommitModeSynchronous])){
        
        NSDictionary *commitDict = @{SCHserverCommitObject: @[object],
                                     SCHServerCommitAction: action,
                                     SCHServerCommitMode : commitMode};
        [self.commitQueue addObject:commitDict];
        
        return YES;
        
    } else return NO;
    
    
    
}
-(BOOL)addObjectsToCommitQueue:(NSArray *) objects commitAction:(NSString *) action commitMode:(NSString *) commitMode{
    if (([action isEqualToString:SCHServerCommitSave] || [action isEqualToString:SCHServerCommitDelete] || [action isEqualToString:SCHServerCommitUpdate]) && ([commitMode isEqualToString:SCHServerCommitModeAsynchronous]|| [commitMode isEqualToString:SCHserverCommitModeEventually]|| [commitMode isEqualToString:SCHServerCommitModeSynchronous])){
        
        NSDictionary *commitDict = @{SCHserverCommitObject: objects,
                                     SCHServerCommitAction: action,
                                     SCHServerCommitMode : commitMode};
        [self.commitQueue addObject:commitDict];
        
        return YES;
        
    } else return NO;
    
}

-(void)removeFromCommitQueue:(NSDictionary *)commitObject{
    
    [self.commitQueue removeObject:commitObject];
    
}



-(void)removeAllobjectsFromCommitQueue{
    [self.commitQueue removeAllObjects];
}

-(BOOL)serverCommit{
    
    
    BOOL success = NO;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (self.commitQueue.count > 0){
        NSArray *commitArray = [[NSArray alloc] initWithArray:self.commitQueue];
        for (NSDictionary *commitDict in commitArray){
            NSString *action = [commitDict valueForKey:SCHServerCommitAction];
            

                if ([action isEqualToString:SCHServerCommitSave]||[action isEqualToString:SCHServerCommitUpdate]){
                    
                    if ([[commitDict valueForKey:SCHServerCommitMode]isEqualToString:SCHServerCommitModeSynchronous]){
                        if (![PFObject saveAll:[commitDict valueForKey:SCHserverCommitObject]]){
                            success = NO;
                            break;
                        }
                        
                        
                    } else if ([[commitDict valueForKey:SCHServerCommitMode]isEqualToString:SCHServerCommitModeAsynchronous]){
                        
                        if (appDelegate.serverReachable){
                            [PFObject saveAllInBackground:[commitDict valueForKey:SCHserverCommitObject]];
                        } else{
                            success = NO;
                            break;
                        }

                        
                    }else if ([[commitDict valueForKey:SCHServerCommitMode]isEqualToString:SCHserverCommitModeEventually]){
                        
                        NSArray *commitObjects = [commitDict valueForKey:SCHserverCommitObject];
                        for (PFObject *commitObject in commitObjects){
                            [commitObject saveEventually];
                        }
                        
                    }
                    [self removeFromCommitQueue:commitDict];
                    success = YES;
                    
                } else if ([action isEqualToString:SCHServerCommitDelete]){
                    if ([[commitDict valueForKey:SCHServerCommitMode]isEqualToString:SCHServerCommitModeSynchronous]){
                        
                        NSArray *objects = [commitDict valueForKey:SCHserverCommitObject];
                        if (objects.count > 0){
                            if (![PFObject deleteAll:[commitDict valueForKey:SCHserverCommitObject]]){
                                
                                success = NO;
                                break;
                            }

                            
                        }
                        
                        
                        
                    } else if ([[commitDict valueForKey:SCHServerCommitMode]isEqualToString:SCHServerCommitModeAsynchronous]){
                        
                        if (appDelegate.serverReachable){
                            
                            [PFObject deleteAllInBackground:[commitDict valueForKey:SCHserverCommitObject]];
                            
                        } else{
                            success = NO;
                            break;
                        }
                        
                        
                    }else if ([[commitDict valueForKey:SCHServerCommitMode]isEqualToString:SCHserverCommitModeEventually]){
                        
                        NSArray *commitObjects = [commitDict valueForKey:SCHserverCommitObject];
                        for (PFObject *commitObject in commitObjects){
                            [commitObject deleteEventually];
                        }
                    }
                    
                    [self removeFromCommitQueue:commitDict];
                    success = YES;
                    
            
                }
            
        }
        
        
        
        
    }else success = YES;
    
    return success;
}

-(void)refreshQueues{
    
    [self removeAllobjectsFromCommitQueue];
    [self removeAllObjectsFromPinningQueue];
    [self removeAllObjectsFromUnpinningQueue];
}


- (NSArray *)reversedArray:(NSArray *) inputArray {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[inputArray count]];
    NSEnumerator *enumerator = [inputArray reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}


-(void)refrshStagedQueue{
    
    [self.objectsStagedForDelete removeAllObjects];
    [self.objectsStagedForPinning removeAllObjects];
    [self.objectsStagedForSave removeAllObjects];
    [self.objectsStagedForUnpin removeAllObjects];
}






@end
