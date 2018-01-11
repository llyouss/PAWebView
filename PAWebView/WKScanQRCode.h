//
//  WKScanQRCode.h
//  Pkit
//
//  Created by llyouss on 2017/12/20.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class WKWebView;

@interface WKScanQRCode : NSObject<UIGestureRecognizerDelegate>

@property (nonatomic, strong) WKWebView *observerView;

/** 单例 */
+ (instancetype)shareInstance;

/**
 对象添加长按识别手势
 @param fview WKWebView 监听对象
 */
- (void)addGestureRecognizerObserverWebElementsWithWebView:(WKWebView *)fview;

@end
