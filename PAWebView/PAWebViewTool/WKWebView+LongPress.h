//
//  WKWebView+LongPress.h
//  Pkit
//
//  Created by llyouss on 2018/2/7.
//  Copyright © 2018年 llyouss. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView (LongPress)<UIGestureRecognizerDelegate>

/**
 添加长按手势
 */
- (void)addGestureRecognizerObserverWebElements:(void(^)(BOOL longpress))Event;

@end
