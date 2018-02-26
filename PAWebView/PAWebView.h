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

/** JS 调用OC */
- (void)PAUserContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end

typedef void (^MessageBlock)(WKUserContentController *userContentController,WKScriptMessage *message);
typedef void (^QRCodeInfoBlock)(NSString *info);

@interface PAWebView : WKBaseWebView

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) BOOL openCache;   //缓存
@property (nonatomic,   copy) NSString *currentURLString;  //当前页面的URL
@property (nonatomic,   copy) QRCodeInfoBlock qrcodeBlock;

@property (nonatomic, strong) UIColor *paprogressTintColor;  //进度条颜色
@property (nonatomic, strong) UIColor *paprogressTrackTintColor;

+ (instancetype)shareInstance;

/** 加载网页 加载网页时注入 cookies */
- (void)loadRequestURL:(NSURL *)url;
- (void)loadRequestURL:(NSURL *)url params:(NSDictionary*)params;
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
 *  接收QRCOde 的内容通知作相关处理
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

/** 读取本地磁盘的cookies，包括WKWebview的cookies和sharedHTTPCookieStorage存储的cookies */
- (NSMutableArray *)WKSharedHTTPCookieStorage;

/** 提供cookies插入，用于loadRequest 网页之前*/
- (void)setcookie:(NSHTTPCookie *)cookie;

/** 清除所有的cookies */
- (void)deleteAllWKCookies;

/** 清除所有缓存（cookie除外） */
- (void)deleteAllWebCache;

/**
 存储URLSchemes主要用于识别urlschemes的来源名字和appstore的下载链接。系统默认输入一部分url，如需额外自定义添加或覆盖，请到registerURLSchemes查看样板
 @params URLSchemes URLSchemes 信息
 */
- (void)registerURLSchemes:(NSDictionary *)URLSchemes;

@end

