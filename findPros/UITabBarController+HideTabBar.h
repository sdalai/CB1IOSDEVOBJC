//
//  UITabBarController+HideTabBar.h
//  CounterBean
//
//  Created by Pratap Yadav on 1/8/16.
//  Copyright © 2016 SujitDalai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITabBarController (HideTabBar)

@property (nonatomic, getter=isTabBarHidden) BOOL tabBarHidden;

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;


@end