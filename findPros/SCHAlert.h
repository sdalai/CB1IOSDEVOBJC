//
//  SCHAlert.h
//  CounterBean
//
//  Created by Sujit Dalai on 1/16/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface SCHAlert : NSObject

+(void) internetOutageAlert;
+(void)selectServiceTypeAlert;
+(void)logoutAlert;

@end
