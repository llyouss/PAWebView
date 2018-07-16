//
//  PAWebViewMenu.m
//  Pkit
//
//  Created by llyouss on 2018/5/10.
//  Copyright © 2018年 llyouss. All rights reserved.
//

#import "PAWebViewMenu.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PAWebViewMenu

+ (instancetype)shareInstance{
    
    static PAWebViewMenu *menu = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        menu = [[PAWebViewMenu alloc]init];
    });
    return menu;
}

- (void)defaultMenuShowInViewController:(nonnull UIViewController *)viewController
                                                  title:(nullable NSString *)title
                                                message:(nullable NSString *)message
                                       buttonTitleArray:(nullable NSArray *)buttonTitleArray
                                  buttonTitleColorArray:(nullable NSArray<UIColor *> *)buttonTitleColorArray
                     popoverPresentationControllerBlock:(nullable UIAlertControllerPopoverPresentationControllerBlock)popoverPresentationControllerBlock
                                                  block:(nullable BAKit_AlertControllerButtonActionBlock)block
{
    
    [UIAlertController ba_actionSheetShowInViewController:viewController
                                                    title:title
                                                  message:message
                                         buttonTitleArray:buttonTitleArray
                                    buttonTitleColorArray:buttonTitleColorArray
                       popoverPresentationControllerBlock:popoverPresentationControllerBlock
                                                    block:block];
    
}

- (void)customMenuShowInViewController:(UIViewController *)viewController
                                 title:(nullable NSString *)title
                               message:(nullable NSString *)message
                      buttonTitleArray:(nullable NSArray *)buttonTitleArray
                 buttonTitleColorArray:(nullable NSArray<UIColor *> *)buttonTitleColorArray
    popoverPresentationControllerBlock:(nullable UIAlertControllerPopoverPresentationControllerBlock)popoverPresentationControllerBlock
                                 block:(nullable BAKit_AlertControllerButtonActionBlock)block{
    [UIAlertController ba_actionSheetShowInViewController:viewController
                                                    title:title
                                                  message:message
                                         buttonTitleArray:buttonTitleArray
                                    buttonTitleColorArray:buttonTitleColorArray
                       popoverPresentationControllerBlock:popoverPresentationControllerBlock
                                                    block:block];
    
}


@end

NS_ASSUME_NONNULL_END
