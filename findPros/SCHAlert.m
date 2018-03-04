//
//  SCHAlert.m
//  CounterBean
//
//  Created by Sujit Dalai on 1/16/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import "SCHAlert.h"

@implementation SCHAlert

+(void) internetOutageAlert{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:@"Sorry. No internet! PLease reonnect and try again."
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        
    });
    
}

+(void)selectServiceTypeAlert{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"CounterBean"
                                                           message:@"Select service and type before selecting time."
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [theAlert show];
        
    });
    
    
    
}
+(void)logoutAlert{
    
}

@end
