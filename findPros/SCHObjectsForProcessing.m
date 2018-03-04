//
//  SCHObjectsForProcessing.m
//  CounterBean Inc.
//
//  Created by Sujit Dalai on 8/16/15.
//  Copyright (c) 2015 SujitDalai. All rights reserved.
//

#import "SCHObjectsForProcessing.h"

@implementation SCHObjectsForProcessing

static SCHObjectsForProcessing *processingManager = nil;
+ (instancetype)sharedManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        processingManager = [[[self class] alloc] init];
        processingManager->_objectsForProcessing = [[NSMutableSet alloc] init];
        
        
    });
    
    return processingManager;
}


-(void) reset{
    [self.objectsForProcessing removeAllObjects];
    
}


-(void) addObjectsToProcessingQueue:(id)objects{
    if ([objects isKindOfClass:[SCHAppointment class]]){
        [self.objectsForProcessing addObject:objects];
    } else if ([objects isKindOfClass:[SCHAppointmentSeries class]]){
        NSPredicate *appointmentsPredicate = [NSPredicate predicateWithFormat:@"appointmentSeries = %@", objects];
        PFQuery *appointmentsQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:appointmentsPredicate];
        [appointmentsQuery fromLocalDatastore];
        [self.objectsForProcessing addObjectsFromArray:[appointmentsQuery findObjects]];
        
    }
}

-(void)removeObjectsFromProcessingQueue:(id)objects{
    
    if ([objects isKindOfClass:[SCHAppointment class]]){
        [self.objectsForProcessing removeObject:objects];
    } else if ([objects isKindOfClass:[SCHAppointmentSeries class]]){
        NSPredicate *appointmentsPredicate = [NSPredicate predicateWithFormat:@"appointmentSeries = %@", objects];
        PFQuery *appointmentsQuery = [PFQuery queryWithClassName:SCHAppointmentClass predicate:appointmentsPredicate];
        [appointmentsQuery fromLocalDatastore];
        for (SCHAppointment *appointment in [appointmentsQuery findObjects]){
            [self.objectsForProcessing removeObject:appointment];
        }
        
    }

}



@end
