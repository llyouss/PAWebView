//
//  WKWebView+PAWebCache.h
//  Pkit
//
//  Created by llyouss on 2017/12/28.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView (PAWebCache)

/** 清除webView缓存 */
- (void)deleteAllWebCache;

/** 清理缓存的方法，这个方法会清除缓存类型为HTML类型的文件*/
- (void)clearHTMLCache;

@end
