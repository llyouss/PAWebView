//
//  PAWebView.m
//  Pkit
//
//  Created by llyouss on 2017/12/15.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import "PAWebView.h"
#import <AVFoundation/AVFoundation.h>
#import "WKWebView+PAWebCookie.h"
#import "WKWebView+PAWebCache.h"
#import "WKWebView+LongPress.h"

#import "NSURL+PATool.h"
#import "PAWebView+UIDelegate.h"
#import "registerURLSchemes.h"
#import "PAWebViewMenu.h"
#import "TYSnapshot.h"
#import "NSURLProtocol+WKWebVIew.h"

//原生组件高度
#define WKSTATUS_BAR_HEIGHT 0
#define WKSEGMENT_HEIGHT 49
#define WKNAVIGATION_BAR_HEIGHT 44
#define WKTAB_BAR_HEIGHT 49
#define WKTOOL_BAR_HEIGHT 49

#define APPSTATUS_BAR_HEIGHT 20
#define WKSCREEN_WIDTH        [UIScreen mainScreen].bounds.size.width
#define WKSCREEN_HEIGHT       [UIScreen mainScreen].bounds.size.height

NSString *const NotiName_LoadRequest = @"notiLoadRequest"; //通知跳转的通知名
NSString *const Key_LoadQRCodeUrl = @"Key_LoadQRCodeUrl"; //二维码识别（包括扫码和长按识别等）

static BOOL isReload = NO;
static BOOL isloadSuccess = NO;
static MessageBlock messageCallback = nil;

@interface PAWebView ()<WKScriptMessageHandler,WKUIDelegate,WKNavigationDelegate,UIScrollViewDelegate>

@property (nonatomic, retain) PAWebViewMenu *menu;
@property (nonatomic,   copy) MenuBlock menuBlock;
@property (nonatomic,   copy) QRCodeInfoBlock qrcodeBlock;
@property (nonatomic, retain) NSArray<NSString *> *buttonTitle;
@property (nonatomic, retain) WKWebViewConfiguration *config;
@property (nonatomic, retain) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, retain) UIProgressView *wkProgressView;   //进度条
@property (nonatomic, retain) NSArray *messageHandlerName;
@property (nonatomic, assign) BOOL longpress;

@end

@implementation PAWebView

+ (instancetype)shareInstance
{
    static PAWebView *baseWebview = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseWebview = [[self alloc]init];
        baseWebview.longpress = NO;
    });

    return baseWebview;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.menu = [PAWebViewMenu shareInstance];
        self.menu.defaultType = YES;
        self.showLog = NO;
        [self loadRequestURL:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];  //初始化，提前加载。
        
        //重写 NSURLProtocol
//        [NSURLProtocol wk_registerScheme:@"http"];
//        [NSURLProtocol wk_registerScheme:@"https"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    __weak typeof(self)weekSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weekSelf.view addSubview:weekSelf.webView];
        [weekSelf configMenuItem];
    });
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    [self addBackButton];
}

#pragma mark -
#pragma mark webView实例

-(WKWebView *)webView
{
    if (_webView == nil) {
        if (self.navigationController.navigationBar.hidden) {
             _webView = [[WKWebView alloc] initWithFrame:CGRectMake( 0, 0, WKSCREEN_WIDTH, WKSCREEN_HEIGHT - WKSTATUS_BAR_HEIGHT - WKNAVIGATION_BAR_HEIGHT) configuration:self.config];
        }else{
            _webView = [[WKWebView alloc] initWithFrame:CGRectMake( 0, 0, WKSCREEN_WIDTH, WKSCREEN_HEIGHT - WKSTATUS_BAR_HEIGHT - WKNAVIGATION_BAR_HEIGHT - APPSTATUS_BAR_HEIGHT) configuration:self.config];
        }
        
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.UIDelegate = self;
        _webView.scrollView.delegate = self;
        _webView.navigationDelegate = self;
        _webView.scrollView.bounces = YES;
        _webView.multipleTouchEnabled = YES;
        _webView.userInteractionEnabled = YES;
        _webView.allowsBackForwardNavigationGestures = YES;
        _webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        _webView.scrollView.showsVerticalScrollIndicator = YES;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
   
        if (@available(iOS 11.0, *)) {
            WKHTTPCookieStore *cookieStore = _webView.configuration.websiteDataStore.httpCookieStore;
            [_webView syncCookiesToWKHTTPCookieStore:cookieStore];
        }
       
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
        [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
        //添加页面跳转通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadRequestFromNotification:) name:NotiName_LoadRequest object:nil];
        //添加长按手势
        __weak typeof(self)weakSelf = self;
        [_webView  addGestureRecognizerObserverWebElements:^(BOOL longpress) {
            weakSelf.longpress = longpress;
        }];
    }

    return _webView;
}

- (void)clearBackForwardList{
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.webView.backForwardList performSelector:NSSelectorFromString(@"_removeAllItems")];
#pragma clang diagnostic pop
    
}

- (void)registerURLSchemes:(NSDictionary *)URLSchemes
{
    [registerURLSchemes registerURLSchemes:URLSchemes];
}

#pragma mark -
#pragma mark -   网络请求

/**
 *  重新加载网页
 */
- (void)reload{
    isReload = YES;
    [self.webView reload];
}

/**
 *  重新加载网页,忽略缓存
 */
- (void)reloadFromOrigin{
    isReload = YES;
    [self.webView reloadFromOrigin];
}

/**
 *  请求网络资源 post
 *  @param request  请求的具体地址和设置
 *  @param params   参数
 */
- (void)loadRequestURL:(NSMutableURLRequest *)request params:(NSDictionary*)params
{
    NSURL *URLString = [NSURL generateURL:request.URL.absoluteString params:params];
    request.URL = URLString;
    [self loadRequestURL:request];
}

/**
 *  请求网络资源
 *  @param  request 请求的具体地址和设置
 */
- (void)loadRequestURL:(NSMutableURLRequest *)request
{
    _webView = _webView ? _webView : self.webView;
    NSString *Domain = request.URL.host;

    /** 插入cookies JS */
    if (Domain)[self.config.userContentController addUserScript:[_webView searchCookieForUserScriptWithDomain:Domain]];
    /** 插入cookies PHP */
    if (Domain)[request setValue:[_webView phpCookieStringWithDomain:Domain] forHTTPHeaderField:@"Cookie"];
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];//重置空白界面
    [_webView loadRequest:request];
}

/**
 *  加载本地HTML页面
 *  @param htmlName html页面文件名称
 */
- (void)loadLocalHTMLWithFileName:(nonnull NSString *)htmlName {
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    NSString * htmlPath = [[NSBundle mainBundle] pathForResource:htmlName
                                                          ofType:@"html"];
    NSString * htmlCont = [NSString stringWithContentsOfFile:htmlPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    [self.webView loadHTMLString:htmlCont baseURL:baseURL];
}

/**
 *  接收通知进行网页跳转
 *  @param noti 通知内容
 */
-(void)loadRequestFromNotification:(NSNotification *)noti
{
    NSString * urlStr = [NSString string];
    for (NSString * key in [noti userInfo]){
        if ([key isEqualToString:Key_LoadQRCodeUrl]) {
            urlStr = [noti userInfo][key];
        }
    }
    NSLog(@"urlStr = %@ ",urlStr);
    
    _qrcodeBlock ? _qrcodeBlock(urlStr) : NULL;
    
    NSURL * url = [NSURL URLWithString:urlStr];
    if ([urlStr containsString:@"http"] || [[UIApplication sharedApplication]canOpenURL:url]) {
     [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (void)notificationInfoFromQRCode:(QRCodeInfoBlock)block
{
    _qrcodeBlock = block;
}

#pragma mark -
#pragma mark 配置webView

-(WKWebViewConfiguration *)config
{
    if (_config == nil) {
        _config = [[WKWebViewConfiguration alloc] init];
        _config.userContentController = [[WKUserContentController alloc] init];
        _config.preferences = [[WKPreferences alloc] init];
        _config.preferences.minimumFontSize = 8;
        _config.preferences.javaScriptEnabled = YES; //是否支持 JavaScript
        _config.preferences.javaScriptCanOpenWindowsAutomatically = YES;
        _config.processPool = [[WKProcessPool alloc] init];
        
        _config.allowsInlineMediaPlayback = YES;        // 允许在线播放
        if (@available(iOS 9.0, *)) {
            _config.allowsAirPlayForMediaPlayback = YES;  //允许视频播放
        }
        
        NSMutableString *javascript = [NSMutableString string];
        [javascript appendString:@"document.documentElement.style.webkitTouchCallout='none';"];//禁止长按
//        [javascript appendString:@"document.documentElement.style.webkitUserSelect='none';"];//禁止选择
        WKUserScript *noneSelectScript = [[WKUserScript alloc] initWithSource:javascript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [_config.userContentController addUserScript:noneSelectScript];
    }
    return _config;
}

#pragma mark -
#pragma mark - JS交互 messageHandler

/**
 *  OC 调用 JS
 *  @param jsMethod JS方法
 */
- (void)callJS:(NSString *)jsMethod {
    
    [self callJS:jsMethod handler:nil];
}

- (void)callJS:(NSString *)jsMethod handler:(void (^)(id response, NSError *error))handler {
    
    NSLog(@"call js:%@",jsMethod);
    [self evaluateJavaScript:jsMethod completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        handler ? handler(response,error) : NULL;
    }];
}

/**
 *  注入 meaasgeHandler
 *  @param nameArr 脚本
 */
- (void)addScriptMessageHandlerWithName:(NSArray<NSString *> *)nameArr
{
    /* removeScriptMessageHandlerForName 同时使用，否则内存泄漏 */
    for (NSString * objStr in nameArr) {
        @try{
            [self.config.userContentController addScriptMessageHandler:self name:objStr];
        }@catch (NSException *e){
            NSLog(@"异常信息：%@",e);
        }@finally{
            
        }
    }
    self.messageHandlerName = nameArr;
}

- (void)addScriptMessageHandlerWithName:(NSArray<NSString *> *)nameArr observeValue:(MessageBlock)callback
{
    messageCallback = callback;
    [self addScriptMessageHandlerWithName:nameArr];
}

/**
 *  注销 注册过的js回调oc通知方式，适用于 iOS8 之后
 */
- (void)removeScriptMessageHandlerForName:(NSString *)name
{
    [_config.userContentController removeScriptMessageHandlerForName:name];
}

/** 调用JS */
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler
{
    NSString *promptCode =javaScriptString;
    [_webView evaluateJavaScript:promptCode completionHandler:completionHandler];
}

/** messageHandler 代理 - js调用oc */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    NSLog(@" message.body =   %@ ",message.body);
    NSLog(@" message.name =   %@ ",message.name);
    NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    if (_messageHandlerDelegate && [_messageHandlerDelegate respondsToSelector:@selector(PAUserContentController:didReceiveScriptMessage:)]) {
        [_messageHandlerDelegate PAUserContentController:userContentController didReceiveScriptMessage:message];
    }
    messageCallback ? messageCallback(userContentController,message) : NULL;
}

#pragma mark -
#pragma mark - WKWebview 缓存 cookie／cache

- (void)setCookie:(NSHTTPCookie *)cookie
{
    [self.webView insertCookie:cookie];
}

/** 获取本地磁盘的cookies */
- (NSMutableArray *)WKSharedHTTPCookieStorage
{
   return [self.webView sharedHTTPCookieStorage];
}

/** 删除某一个cookies */
- (void)deleteWKCookie:(NSHTTPCookie *)cookie completionHandler:(nullable void (^)(void))completionHandler
{
    [self.webView deleteWKCookie:cookie completionHandler:completionHandler];
}

/** 删除所有的cookies */
- (void)clearWKCookies{
    
    [self.webView clearWKCookies];
}

/** 删除所有缓存不包括cookies */
- (void)clearWebCacheFinish:(void(^)(BOOL finish,NSError *error))block{
    
    [self.webView clearWebCacheFinish:block];
}

- (void)deleteWKCookiesByHost:(NSURL *)host completionHandler:(nullable void (^)(void))completionHandler{
    
    [self.webView deleteWKCookiesByHost:host completionHandler:completionHandler];
}

#pragma mark -
#pragma mark -- navigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    isloadSuccess = NO;
}

/** 跳转处理 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:
(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (_longpress) {
        _longpress = NO;
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    NSString *scheme = navigationAction.request.URL.scheme.lowercaseString;
    if (![scheme containsString:@"http"] && ![scheme containsString:@"about"] && ![scheme containsString:@"file"]) {
        // 对于跨域，需要手动跳转， 用系统浏览器（Safari）打开
        if ([navigationAction.request.URL.host.lowercaseString isEqualToString:@"itunes.apple.com"])
        {
            [UIAlertController PAlertWithTitle:@"提示" message:@"是否打开appstore？" action1Title:@"返回" action2Title:@"去下载" action1:^{
                [webView goBack];
            } action2:^{
                [NSURL safariOpenURL:navigationAction.request.URL];
            }];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        
        [NSURL openURL:navigationAction.request.URL];
        // 不允许web内跳转
        decisionHandler(WKNavigationActionPolicyCancel);
        
    } else {
        
        if ([navigationAction.request.URL.host.lowercaseString isEqualToString:@"itunes.apple.com"])
        {
            [NSURL openURL:navigationAction.request.URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    
    __weak typeof(self)weakSelf = self;
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
    if ([response.URL.scheme.lowercaseString containsString:@"http"]) {
        NSArray *cookies =[NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
        if (@available(iOS 11.0, *)) {
            //浏览器自动存储cookie
        }else
        {
            //存储cookies
            dispatch_sync(dispatch_get_global_queue(0, 0), ^{
                
                @try{
                    //存储cookies
                    for (NSHTTPCookie *cookie in cookies) {
                        [weakSelf.webView insertCookie:cookie];
                    }
                }@catch (NSException *e) {
                    NSLog(@"failed: %@", e);
                } @finally {
                    
                }
            });
        }
        
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    
        NSLog(@"%@",webView.URL.absoluteString);
    
    if ([webView.URL.absoluteString.lowercaseString isEqualToString:@"about:blank"]) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [webView.backForwardList performSelector:NSSelectorFromString(@"_removeAllItems")];
#pragma clang diagnostic pop

    }
    
        isloadSuccess = YES;
        //获取当前 URLString
        __weak typeof(self)weekSelf = self;
        [webView evaluateJavaScript:@"window.location.href" completionHandler:^(id _Nullable urlStr, NSError * _Nullable error) {
            if (error == nil) {
                weekSelf.currentURLString = urlStr;
            }
        }];
        
        NSString *heightString4 = @"document.body.scrollHeight";
        // webView 高度自适应
        [webView evaluateJavaScript:heightString4 completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            // 获取页面高度，并重置 webview 的 frame
            NSLog(@"html 的高度：%@", result);
        }];

}

/** 接收到重定向时会回调 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    
}

/** 导航失败时会回调 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self.activityIndicator stopAnimating];
    
}

/** 页面内容到达main frame时回调 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    
}

/** 失败回调 */
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
}


- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    NSLog(@"%@",challenge.protectionSpace.authenticationMethod.lowercaseString);
    
    NSString *hostName = webView.URL.host;
    NSString *authenticationMethod = [[challenge protectionSpace] authenticationMethod];
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault]
        || [authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]
        || [authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
        
        NSString *title = @"Authentication Challenge";
        NSString *message = [NSString stringWithFormat:@"%@ requires user name and password", hostName];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"User";
            //textField.secureTextEntry = YES;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Password";
            textField.secureTextEntry = YES;
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            NSString *userName = ((UITextField *)alertController.textFields[0]).text;
            NSString *password = ((UITextField *)alertController.textFields[1]).text;
            
            NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:userName password:password persistence:NSURLCredentialPersistenceNone];
            
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertController animated:YES completion:^{}];
        });
        
    }
    else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // needs this handling on iOS 9
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        challenge.sender ? completionHandler(NSURLSessionAuthChallengeUseCredential,card) : NULL;
    }
    else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}


#pragma mark -- navigationBar customUI
#pragma mark 导航栏的菜单按钮
/** 添加返回按钮 */
- (void)addBackButton
{
    self.navigationItem.leftBarButtonItem = self.backItem;
    [(UIButton *)self.backItem.customView addTarget:self action:@selector(backNative) forControlEvents:UIControlEventTouchUpInside];
}

- (void)goback{
    [self backNative];
}

/** 点击返回按钮的返回方法 */
- (void)backNative {
    //判断是否有上一层H5页面
    if ([self.webView canGoBack])
    {
        //如果有则返回
        [self.webView goBack];
        
        //同时设置返回按钮和关闭按钮为导航栏左边的按钮
        self.navigationItem.leftBarButtonItems = @[self.backItem];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)goForward{
    
    [self.webView canGoForward] ? [_webView goForward] : NULL;
}

/** 功能菜单按钮 */
- (void)configMenuItem
{
    UIImage *menuImage = [UIImage imageNamed:@"navigationbar_more"];
    menuImage = [menuImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *menuBtn = [[UIButton alloc] init];
    [menuBtn setImage:menuImage forState:UIControlStateNormal];
    [menuBtn addTarget:self action:@selector(menuBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [menuBtn sizeToFit];
    
    UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] initWithCustomView:menuBtn];
    self.navigationItem.rightBarButtonItem = menuItem;
}

#pragma mark 菜单按钮点击

- (void)addMenuWithButtonTitle:(NSArray<NSString *> *)buttonTitle block:(MenuBlock)block{
    
    _menu.defaultType = NO;
    _buttonTitle = buttonTitle;
    _menuBlock = block;
}

- (void)menuBtnAction:(UIButton *)sender
{
     __weak typeof(self)weekSelf = self;
    if (self.menu.defaultType) {
        NSMutableArray *buttonTitleArray = [NSMutableArray array];
        [buttonTitleArray addObjectsFromArray:@[@"safari打开", @"复制链接", @"分享", @"截图", @"刷新"]];
        if (self.showLog) [buttonTitleArray addObject:@"执行日志"];
        [self.menu defaultMenuShowInViewController:self title:@"更多" message:nil buttonTitleArray:buttonTitleArray buttonTitleColorArray:nil popoverPresentationControllerBlock:^(UIPopoverPresentationController * _Nonnull popover) {
            
        } block:^(UIAlertController * _Nonnull alertController, UIAlertAction * _Nonnull action, NSInteger buttonIndex)
         {
             if (buttonIndex == 0)
             {
                 if (weekSelf.currentURLString.length > 0)
                 {
                     /*! safari打开 */
                     [NSURL safariOpenURL:[NSURL URLWithString:weekSelf.currentURLString]];
                     return;
                 }
                 else
                 {
                     [UIAlertController PAlertWithTitle:@"提示" message:@"无法获取当前链接" completion:nil];
                 }
             }
             else if (buttonIndex == 1)
             {
                 /*! 复制链接 */
                 if (weekSelf.currentURLString.length > 0)
                 {
                     [UIPasteboard generalPasteboard].string = weekSelf.currentURLString;
                     return;
                 }
                 else
                 {
                     [UIAlertController PAlertWithTitle:@"提示" message:@"无法获取当前链接" completion:nil];
                 }
             }
             else if (buttonIndex == 2)
             {
                 
             }
             else if (buttonIndex == 3)
             {
                 [weekSelf snapshotBtn];
             }
             else if (buttonIndex == 4)
             {
                 /*! 刷新 */
                 [weekSelf.webView reloadFromOrigin];
             }
         }];
    }else
    {
        [weekSelf.menu customMenuShowInViewController:weekSelf
                                             title:@"更多"
                                           message:nil
                                  buttonTitleArray:weekSelf.buttonTitle
                             buttonTitleColorArray:nil popoverPresentationControllerBlock:^(UIPopoverPresentationController * _Nonnull popover) {
            
        } block:^(UIAlertController * _Nonnull alertController, UIAlertAction * _Nonnull action, NSInteger buttonIndex)
         {
             weekSelf.menuBlock ? weekSelf.menuBlock(alertController, action, buttonIndex) : NULL;
         }];
    }
}

//saveSnap
- (void)snapshotBtn{
    
    __weak typeof(self) weakSelf = self;
    [TYSnapshot screenSnapshot:self.webView finishBlock:^(UIImage *snapShotImage) {
        UIViewController *preVc = [[PreviewVc alloc] init:snapShotImage];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:preVc];
        nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [weakSelf presentViewController:nc animated:YES completion:nil];
    }];
}

#pragma mark 关闭按钮点击
- (void)colseBtnAction:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark --- 进度条
/** 进度条 */
- (UIProgressView *)wkProgressView {
    if (!_wkProgressView) {
        CGFloat progressBarHeight = 2.f;
        CGRect barFrame = CGRectMake(0,  0, WKSCREEN_WIDTH, progressBarHeight);
        _wkProgressView = [[UIProgressView alloc] initWithFrame:barFrame];
        _wkProgressView.tintColor = [UIColor colorWithRed:50.0/255 green:135.0/255 blue:255.0/255 alpha:1.0];
        _wkProgressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _wkProgressView.hidden = NO;
        [_wkProgressView setAlpha:0.0f];
        [self.webView addSubview:_wkProgressView];
    }
    return _wkProgressView;
}

- (void)setPAProgressTintColor:(UIColor *)paprogressTintColor
{
    _paprogressTintColor = paprogressTintColor;
    self.wkProgressView.progressTintColor = paprogressTintColor;
}

- (void)setPAProgressTrackTintColor:(UIColor *)paprogressTrackTintColor
{
    _paprogressTrackTintColor = paprogressTrackTintColor;
    self.wkProgressView.trackTintColor = paprogressTrackTintColor;
}

/** 监控html的title 和 进度 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"])
    {
        if (object == _webView)
        {
            [self.wkProgressView setAlpha:1.0f];
            float progressValue = fabsf([change[@"new"] floatValue]);
            if (progressValue > _wkProgressView.progress) {
                
                [_wkProgressView setProgress:progressValue animated:YES];
            }else{
                
                [_wkProgressView setProgress:progressValue animated:NO];
            }
            
            if(progressValue >= 1.0f)
            {
                __weak typeof(self)weekSelf = self;
                [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [weekSelf.wkProgressView setAlpha:0.0f];
                } completion:^(BOOL finished) {
                    [weekSelf.wkProgressView setProgress:0.0f animated:NO];
                }];
            }
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else if ([keyPath isEqualToString:@"title"])
    {
        if (object == _webView)
        {
            self.title = _webView.title;
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }else
    {
        NSLog(@"%@",keyPath);
    }
}

#pragma mark -
#pragma mark --- 加载动画
/** 加载动画 */
- (UIActivityIndicatorView *)activityIndicator
{
    if (_activityIndicator == nil) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_activityIndicator setCenter:self.webView.center];
    }
    return _activityIndicator;
}

- (void)dealloc
{
    [_webView clearHTMLCache];
    if(self.webView.scrollView.delegate) self.webView.scrollView.delegate = nil;
    if(self.webView.navigationDelegate) self.webView.navigationDelegate = nil;
    if(self.webView.UIDelegate) self.webView.UIDelegate = nil;
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    if(self.wkProgressView)[_wkProgressView removeFromSuperview];
     self.wkProgressView = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self PARemoveScriptMessageHandlerForName];
}

- (void)PARemoveScriptMessageHandlerForName{
    if ([_messageHandlerName count] > 0) {
        for (NSString *name in _messageHandlerName) {
            if (name) {
                [_config.userContentController removeScriptMessageHandlerForName:name];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


