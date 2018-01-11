//
//  WKWebView+PAWebCookie.h
//  Pkit
//
//  Created by llyouss on 2017/12/28.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView (PAWebCookie)

/** ios11 同步cookies */
- (void)syncCookiesToWKHTTPCookieStore:(WKHTTPCookieStore *)cookieStroe API_AVAILABLE(macosx(10.13), ios(11.0));

/** 插入cookies存储于磁盘 */
- (void)insertCookie:(NSHTTPCookie *)cookie;

/** 获取本地磁盘的cookies */
- (NSMutableArray *)sharedHTTPCookieStorage;

/** 删除所有的cookies */
- (void)deleteAllWKCookies;

/** 删除某一个cookies */
- (void)deleteWKCookies:(NSHTTPCookie *)cookie;

/** js获取domain的cookie */
- (NSString *)jsCookieStringWithDomain:(NSString *)domain;
- (WKUserScript *)addCookieWithDomain:(NSString *)domain;

/** PHP 获取domain的cookie */
- (NSString *)phpCookieStringWithDomain:(NSString *)domain;


@end
