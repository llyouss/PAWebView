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
#import "WKScanQRCode.h"

#import "NSURL+PATool.h"
#import "UIAlertController+WKWebAlert.h"
#import "PAWebView+UIDelegate.h"
#import "registerURLSchemes.h"

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

@property (nonatomic, strong) WKWebViewConfiguration *config;
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, strong) UIProgressView *wkProgressView;   //进度条
@property (nonatomic, retain) NSArray *messageHandlerName;

@end

@implementation PAWebView

+ (instancetype)shareInstance
{
    static PAWebView *baseWebview = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseWebview = [[self alloc]init];
    });
    
    return baseWebview;
}

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:self.webView];
        [self addBackButton];
        [self configMenuItem];
    });
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
        _webView.UIDelegate =self;
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
            WKHTTPCookieStore *cookieStroe = _webView.configuration.websiteDataStore.httpCookieStore;
            [_webView syncCookiesToWKHTTPCookieStore:cookieStroe];
        }
       
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
        [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
        //添加页面跳转通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadRequestFromNotification:) name:NotiName_LoadRequest object:nil];
        //添加长按手势
        [[WKScanQRCode shareInstance] addGestureRecognizerObserverWebElementsWithWebView:_webView];
    }

    return _webView;
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
 *  @param url      网络地址
 *  @param params   参数
 */
- (void)loadRequestURL:(NSURL *)url params:(NSDictionary*)params
{
    NSURL *URLString = [NSURL generateURL:url.absoluteString params:params];
    [self loadRequestURL:URLString];
}

/**
 *  请求网络资源
 *  @param  url 网络地址
 */
- (void)loadRequestURL:(NSURL *)url
{
    _webView = _webView?_webView:self.webView;
    
    NSString *Domain = url.host;
    NSMutableURLRequest* request;
    if (self.openCache) {
       request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:20.0f];
    }else{
       request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0f];
    }
   
    if (@available(iOS 11.0, *)) {
       //iOS 11.0 使用WKHTTPCookieStore 代替
    }else{
        /** 插入cookies JS */
        if (Domain)[self.config.userContentController addUserScript:[_webView addCookieWithDomain:Domain]];
        /** 插入cookies PHP */
        if (Domain)[request setValue:[_webView phpCookieStringWithDomain:Domain] forHTTPHeaderField:@"Cookie"];
    }
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
    NSLog(@"noti.userInfo %@ ",noti.userInfo);
    NSString * urlStr = [NSString string];
    for (NSString * key in [noti userInfo]){
        if ([key isEqualToString:Key_LoadQRCodeUrl]) {
            urlStr = [noti userInfo][key];
        }
    }
    NSLog(@"urlStr = %@ ",urlStr);
    
    _qrcodeBlock?_qrcodeBlock(urlStr):NULL;
    
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
        _config.allowsInlineMediaPlayback = YES;        // 允许在线播放
        _config.preferences = [[WKPreferences alloc] init];
        _config.preferences.minimumFontSize = 10;
        _config.preferences.javaScriptEnabled = YES; //是否支持 JavaScript
        _config.processPool = [[WKProcessPool alloc] init];
        NSMutableString *javascript = [NSMutableString string];
        [javascript appendString:@"document.documentElement.style.webkitTouchCallout='none';"];//禁止长按
        //[javascript appendString:@"document.documentElement.style.webkitUserSelect='none';"];//禁止选择
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
        handler?handler(response,error):NULL;
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
        [_config.userContentController addScriptMessageHandler:self name:objStr];
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
    if (_messageHandlerdelegate && [_messageHandlerdelegate respondsToSelector:@selector(PAUserContentController:didReceiveScriptMessage:)]) {
        [_messageHandlerdelegate PAUserContentController:userContentController didReceiveScriptMessage:message];
    }
    messageCallback?messageCallback(userContentController,message):NULL;
}

#pragma mark -
#pragma mark - WKWebview 缓存 cookie／cache

- (void)setcookie:(NSHTTPCookie *)cookie
{
    [self.webView insertCookie:cookie];
}

/** 获取本地磁盘的cookies */
- (NSMutableArray *)WKSharedHTTPCookieStorage
{
   return [self.webView sharedHTTPCookieStorage];
}

/** 删除所有的cookies */
- (void)deleteAllWKCookies
{
    [self.webView deleteAllWKCookies];
}

/** 删除所有缓存不包括cookies */
- (void)deleteAllWebCache
{
    [self.webView deleteAllWebCache];
    [_config.userContentController removeAllUserScripts];
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
    NSString *scheme = navigationAction.request.URL.scheme.lowercaseString;
   
    if (![scheme containsString:@"https"] && ![scheme containsString:@"http"] && ![scheme containsString:@"about"]) {
        // 对于跨域，需要手动跳转， 用系统浏览器（Safari）打开
        if ([navigationAction.request.URL.absoluteString.lowercaseString containsString:@"ituns.apple.com"] ||
            [navigationAction.request.URL.absoluteString containsString:@"itms-appss"])
        {
            [UIAlertController PAlertWithTitle:@"提示" message:@"是否打开appstore？" action1Title:@"返回" action2Title:@"去下载" action1:^{
                [webView goBack];
            } action2:^{
                [NSURL openURL:navigationAction.request.URL];
            }];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        
        [NSURL openURL:navigationAction.request.URL];
        // 不允许web内跳转
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        
        if ([navigationAction.request.URL.absoluteString.lowercaseString containsString:@"itunes.apple"] ||
            [navigationAction.request.URL.absoluteString.lowercaseString containsString:@"itms-appss"])
        {
            [NSURL openURL:navigationAction.request.URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        decisionHandler(WKNavigationActionPolicyAllow);
    }
}


/** 存储cookies */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
        NSArray *cookies =[NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
        //存储cookies
        for (NSHTTPCookie *cookie in cookies) {
            [_webView insertCookie:cookie];
        }
    });
    
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    isloadSuccess = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //获取当前 URLString
        [webView evaluateJavaScript:@"window.location.href" completionHandler:^(id _Nullable urlStr, NSError * _Nullable error) {
            if (error == nil) {
                _currentURLString = urlStr;
                //NSLog(@"currentURLStr : %@ ",_currentURLString);
            }
        }];
        
        NSString *heightString4 = @"document.body.scrollHeight";
            // webView 高度自适应
            [webView evaluateJavaScript:heightString4 completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                // 获取页面高度，并重置 webview 的 frame
                NSLog(@"html 的高度：%@", result);
            }];
    });
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
    [self.webView canGoForward]?[_webView goForward]:NULL;
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
- (void)menuBtnAction:(UIButton *)sender
{
    NSArray *buttonTitleArray = @[@"safari打开", @"复制链接", @"分享", @"刷新"];
    [UIAlertController ba_actionSheetShowInViewController:self title:@"更多" message:nil buttonTitleArray:buttonTitleArray buttonTitleColorArray:nil popoverPresentationControllerBlock:^(UIPopoverPresentationController * _Nonnull popover) {
        
    } block:^(UIAlertController * _Nonnull alertController, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
     
        if (buttonIndex == 0)
        {
            if (_currentURLString.length > 0)
            {
                /*! safari打开 */
                [NSURL SafariOpenURL:[NSURL URLWithString:_currentURLString]];
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
            if (_currentURLString.length > 0)
            {
                [UIPasteboard generalPasteboard].string = _currentURLString;
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
            /*! 刷新 */
            [_webView reloadFromOrigin];
        }
        
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
    NSLog(@"%@",keyPath);
    if ([keyPath isEqualToString:@"estimatedProgress"])
    {
        if (object == _webView)
        {
            [self.wkProgressView setAlpha:1.0f];
            float progressValue = fabsf([change[@"new"] floatValue]);
            [_wkProgressView setProgress:progressValue animated:YES];
            
            if(progressValue >= 1.0f)
            {
                [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [_wkProgressView setAlpha:0.0f];
                } completion:^(BOOL finished) {
                    [_wkProgressView setProgress:0.0f animated:NO];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

