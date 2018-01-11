//
//  PAWebNavigationController.h
//  Pkit
//
//  Created by llyouss on 2017/12/19.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PAWebNavigationController : UINavigationController

@property (readonly, nonatomic) UIPanGestureRecognizer *panGestureRecognizer; //侧滑手势
@property (nonatomic, assign) BOOL isEnableScroll;


@end

@protocol LCPanBackProtocol <NSObject>

/**
 能否侧滑
 
 @param panNavigationController panNavigationController
 @return BooL
 */
- (BOOL)enablePanBack:(PAWebNavigationController *)panNavigationController;

/**
 开始侧滑手势
 
 @param panNavigationController panNavigationController
 */
- (void)startPanBack:(PAWebNavigationController *)panNavigationController;

/**
 完成侧滑
 
 @param panNavigationController panNavigationController
 */
- (void)finshPanBack:(PAWebNavigationController *)panNavigationController;

/**
 重置侧滑手势
 
 @param panNavigationController panNavigationController
 */
- (void)resetPanBack:(PAWebNavigationController *)panNavigationController;

@end


