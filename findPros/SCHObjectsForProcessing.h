//
//  SCHObjectsForProcessing.h
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 8/16/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCHAppointment.h"
#import "SCHAppointmentSeries.h"



@interface SCHObjectsForProcessing : NSObject

@property (nonatomic, strong) NSMutableSet *objectsForProcessing;

+ (instancetype) sharedManager;

-(void) addObjectsToProcessingQueue:(id) objects;

-(void) removeObjectsFromProcessingQueue: (id)objects;

-(void) reset;



@end
