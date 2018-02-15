//
//  UIAlertController+WKWebAlert.h
//  Pkit
//
//  Created by llyouss on 2017/12/18.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/**
 按钮点击事件 block
 
 @param alertController alertController
 @param action UIAlertAction
 @param buttonIndex buttonIndex
 */
typedef void (^BAKit_AlertControllerButtonActionBlock) (UIAlertController * __nonnull alertController, UIAlertAction * __nonnull action, NSInteger buttonIndex);

#if TARGET_OS_IOS
typedef void (^UIAlertControllerPopoverPresentationControllerBlock) (UIPopoverPresentationController * __nonnull popover);
#endif

typedef void (^BAKit_AlertControllerTextFieldConfigurationActionBlock)(UITextField * _Nullable textField, NSInteger index);

@interface UIAlertController (WKWebAlert)

+ (BOOL)isAlert;
/**
 *  返回当前类的所有成员变量数组
 *
 *  @return 当前类的所有成员变量！
 *
 *  Tips：用于调试, 可以尝试查看所有不开源的类的ivar
 */
+ (NSArray *)ba_ivarList;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

+ (void)PAlertWithTitle:(NSString *)title message:(NSString *)message completion:(void (^)())completion;
+ (void)PAlertWithTitle:(NSString *)title
                message:(NSString *)message
           action1Title:(NSString *)action1Title
           action2Title:(NSString *)action2Title
                action1:(void (^)())action1
                action2:(void (^)())action2;



/**
 快速创建一个系统 普通 UIAlertController-ActionSheet
 
 @param viewController 显示的VC
 @param title title
 @param message message
 @param buttonTitleArray 按钮数组
 @param buttonTitleColorArray 按钮颜色数组，默认：系统蓝色，如果颜色数组个数小于title数组个数，则全部为默认蓝色
 @param popoverPresentationControllerBlock popoverPresentationControllerBlock description
 @param block block
 @return UIAlertController-ActionSheet
 */
+ (nonnull instancetype)ba_actionSheetShowInViewController:(nonnull UIViewController *)viewController
                                                     title:(nullable NSString *)title
                                                   message:(nullable NSString *)message
                                          buttonTitleArray:(nullable NSArray *)buttonTitleArray
                                     buttonTitleColorArray:(nullable NSArray <UIColor *>*)buttonTitleColorArray
#if TARGET_OS_IOS
                        popoverPresentationControllerBlock:(nullable UIAlertControllerPopoverPresentationControllerBlock)popoverPresentationControllerBlock
#endif
                                                     block:(nullable BAKit_AlertControllerButtonActionBlock)block;


#pragma clang diagnostic pop

@end
