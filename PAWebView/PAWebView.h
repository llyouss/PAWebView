//
//  PAWebView.h
//  Pkit
//
//  Created by llyouss on 2017/12/15.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import "WKBaseWebView.h"
#import <WebKit/WebKit.h>

@class registerURLSchemes;

@protocol PAWKScriptMessageHandler <NSObject>

@optional

/** JS 调用OC回调 */
- (void)PAUserContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end

typedef void (^QRCodeInfoBlock)(NSString *info);
typedef void (^MessageBlock)(WKUserContentController *userContentController,WKScriptMessage *message);
typedef void (^MenuBlock)(UIAlertController *  alertController, UIAlertAction *  action, NSInteger buttonIndex);

@interface PAWebView : WKBaseWebView

@property (nonatomic, retain) WKWebView *webView;
@property (nonatomic,   copy) NSString *currentURLString;  //当前页面的URL
@property (nonatomic,   weak) id<PAWKScriptMessageHandler> messageHandlerDelegate;
@property (nonatomic, retain) UIColor *paprogressTintColor;  //进度条颜色
@property (nonatomic, retain) UIColor *paprogressTrackTintColor;
@property (nonatomic, assign) BOOL openCache;   //缓存
@property (nonatomic, assign) BOOL showLog;     //执行日志

+ (instancetype)shareInstance;

/** 加载网页 加载网页时注入 cookies 把链接更改为 NSMutableURLRequest ，自定义缓存的方式和其他的一些具体的设置*/
- (void)loadRequestURL:(NSMutableURLRequest *)request;
- (void)loadRequestURL:(NSMutableURLRequest *)request params:(NSDictionary*)params;
- (void)loadLocalHTMLWithFileName:(NSString *)htmlName;

/** 重新加载webview */
- (void)reload;
/** 重新加载网页,忽略缓存 */
- (void)reloadFromOrigin;

/** 返回上一级 */
- (void)goback;
/** 下一级 */
- (void)goForward;

/**
 添加自定义的菜单栏

 @param buttonTitle 菜单按钮的标题
 @param block 反馈点击信息
 */
- (void)addMenuWithButtonTitle:(NSArray<NSString *> *)buttonTitle block:(MenuBlock)block;

/**
 *  接收QRCode 的内容通知作相关处理
 *  @param block QRCode的内容(包括手势长按或扫码)
 */
- (void)notificationInfoFromQRCode:(QRCodeInfoBlock)block;

/** JS 调用OC 添加 messageHandler
 添加 js 调用 OC，addScriptMessageHandler:name:有两个参数，第一个参数是 userContentController的代理对象，第二个参数是 JS 里发送 postMessage 的对象。添加一个脚本消息的处理器,同时需要在 JS 中添加，window.webkit.messageHandlers.<name>.postMessage(<messageBody>)才能起作用。
 @param nameArr JS 里发送 postMessage 的对象数组，可同时添加多个对象
 */
- (void)addScriptMessageHandlerWithName:(NSArray<NSString *> *)nameArr;
- (void)addScriptMessageHandlerWithName:(NSArray<NSString *> *)nameArr observeValue:(MessageBlock)callback;
- (void)removeScriptMessageHandlerForName:(NSString *)name;

/** OC调用JS方法 */
- (void)callJS:(NSString *)jsMethod;
- (void)callJS:(NSString *)jsMethod handler:(void (^)(id response, NSError *error))handler;

/*清除backForwardList 列表*/
- (void)clearBackForwardList;

/**
  读取本地磁盘的cookies，包括WKWebview的cookies和sharedHTTPCookieStorage存储的cookies

 @return 返回包含所有的cookies的数组；
 当系统低于 iOS11 时，cookies 将同步NSHTTPCookieStorage的cookies，当系统大于iOS11时，cookies 将同步
 */
- (NSMutableArray *)WKSharedHTTPCookieStorage;

/**
  提供cookies插入，用于loadRequest 网页之前

 @param cookie NSHTTPCookie 类型
  cookie 需要设置 cookie 的name，value，domain，expiresDate（过期时间，当不设置过期时间，cookie将不会自动清除）；
  cookie 设置expiresDate时使用 [cookieProperties setObject:expiresDate forKey:NSHTTPCookieExpires];将不起作用，原因不明；使用 cookieProperties[expiresDate] = expiresDate; 设置cookies 设置时间。
 */
- (void)setCookie:(NSHTTPCookie *)cookie;

/** 删除单个cookie */
- (void)deleteWKCookie:(NSHTTPCookie *)cookie completionHandler:(nullable void (^)(void))completionHandler;
/** 删除域名下的所有的cookie */
- (void)deleteWKCookiesByHost:(NSURL *)host completionHandler:(nullable void (^)(void))completionHandler;

/** 清除所有的cookies */
- (void)clearWKCookies;

/** 清除所有缓存（cookie除外） */
- (void)clearWebCacheFinish:(void(^)(BOOL finish,NSError *error))block;

/**
 存储URLSchemes主要用于识别urlschemes的来源名字和appstore的下载链接。系统默认输入一部分url，如需额外自定义添加或覆盖，请到registerURLSchemes查看样板
 @params URLSchemes URLSchemes 信息
 */
- (void)registerURLSchemes:(NSDictionary *)URLSchemes;

@end

