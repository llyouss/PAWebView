//
//  WKWebView+LongPress.m
//  Pkit
//
//  Created by llyouss on 2018/2/7.
//  Copyright © 2018年 llyouss. All rights reserved.
//

#import "WKWebView+LongPress.h"
#import <Photos/Photos.h>
#import "UIAlertController+WKWebAlert.h"
#import "PAPhotoBrowser.h"
#import <objc/message.h>

FOUNDATION_EXPORT NSString* const NotiName_LoadRequest;
FOUNDATION_EXPORT NSString* const Key_LoadQRCodeUrl;
FOUNDATION_EXPORT NSString* const JSSearchHrefFromHtml;  //抓取链接的JS方法
FOUNDATION_EXPORT NSString* const JSSearchImageFromHtml; //抓取图片
FOUNDATION_EXPORT NSString* const JSSearchAllImageFromHtml;

FOUNDATION_EXPORT NSString* const JSFunctionAddEventCanal; //添加忽略事件响应
FOUNDATION_EXPORT NSString* const JSFunctionRemoveEventCanal; //移除添加的事件
FOUNDATION_EXPORT NSString* const JSFunctionEventIgnore;  //忽略事件响应的方法

typedef void(^LONGPRESS)(BOOL longpress);
static LONGPRESS longPress = nil;

@implementation WKWebView (LongPress)

CGPoint touchPoint;

/**
 添加长按手势
 */
- (void)addGestureRecognizerObserverWebElements:(void(^)(BOOL longpress))Event;
{
    longPress = (LONGPRESS)Event;
    //长按识别图中的二维码，类似于微信里面的功能,前提是当前页面必须有二维码
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startLongPress:)];
    longPress.delegate = self;
    
    longPress.minimumPressDuration = 0.4f;
    longPress.numberOfTouchesRequired = 1;
    longPress.cancelsTouchesInView = YES;
    [self addGestureRecognizer:longPress];
}

/** 手势精确识别，防止误操作 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    NSLog(@"%@",otherGestureRecognizer.class);
    
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        
        return YES;
    }else{
        return NO;
    }
}

/** 长按识别代理 */
- (void)startLongPress:(UILongPressGestureRecognizer *)pressSender
{
    if(pressSender.state == UIGestureRecognizerStateBegan){
       
        //获取位置
        touchPoint = [pressSender locationInView:self];
        //识别/抓取html元素
        [self detectQRCodeInWebView:pressSender];
        NSLog(@"1. 开始长按手势");
        
    }else if(pressSender.state == UIGestureRecognizerStateEnded){
        
        //可以添加你长按手势执行的方法,不过是在手指松开后执行
        NSLog(@"2. 结束长按手势");
        
    }else if(pressSender.state == UIGestureRecognizerStateChanged){
        
        //在手指点下去一直不松开的状态执行
        NSLog(@"3. 长按手势改变");
    }
}

#pragma mark -

#pragma mark - 响应间隔禁止

-(void)userInteractionDisableWithTime:(double)interval {
    if(time <= 0 && !self.userInteractionEnabled) {
        return;
    }

    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.userInteractionEnabled = YES;
    });
}

#pragma mark -

#pragma mark - JS注入

/** 抓取链接 */
- (void)hrefFromJSPointX:(float)x ppintY:(float)y callBack:(void(^)(NSString *hre))callback
{
    //注入JS方法
    NSString *hrefJS = JSSearchHrefFromHtml;
    [self evaluateJavaScript:hrefJS completionHandler:nil];
    
    //调用JS方法
    NSString *hrefFunc = [NSString stringWithFormat:@"JSSearchHref(%f,%f);",x,y];
    [self evaluateJavaScript:hrefFunc completionHandler:^(id _Nullable href, NSError * _Nullable error)
     {
         callback ? callback(href) : NULL;
     }];
}

/** 抓取所有图片 */
- (void)showAllImageFromHtmIndex:(NSString *)ImageUrlString
{
    //注入JS方法
    NSString *hrefJS = JSSearchAllImageFromHtml;
    [self evaluateJavaScript:hrefJS completionHandler:nil];
    
    //调用JS方法
    NSString *hrefFunc = [NSString stringWithFormat:@"JSSearchAllImage();"];
    [self evaluateJavaScript:hrefFunc completionHandler:^(id _Nullable image, NSError * _Nullable error)
     {
         NSArray *imageArray = [self sortImageFromArray:image];
         NSLog(@"%@",imageArray);
         
         
#pragma clang diagnostic push
#pragma clang diagnostic  ignored "-Wundeclared-selector"
         
         Class cls = NSClassFromString(@"PAPhotoBrowser");
         
         id photos;
         SEL fun = NSSelectorFromString(@"shareInstance");
         if ([cls respondsToSelector:fun]) {
            photos = [cls performSelector:fun];
         }else{
             NSLog(@"请使用PAPhotoBrowser扩展！");
             return ;
         }
         
         [photos setValue:imageArray forKey:@"photos"];
         
         NSInteger index =  [imageArray indexOfObject:ImageUrlString];
         if (index == NSNotFound){
             
             NSMutableArray *array = [photos objectForKey:@"photos"];
             [array insertObject:ImageUrlString atIndex:0];
             
             ((void (*)(id, SEL, NSInteger))
              objc_msgSend)(photos,
                            @selector(loadPhotoBrowserShowIndex:),
                            0
                            );
             
         }
         else {
             ((void (*)(id, SEL, NSInteger))
              objc_msgSend)(photos,
                            @selector(loadPhotoBrowserShowIndex:),
                            index
                           );
         }
         
#pragma clang diagnostic pop
         

     }];
}


/** 过滤从网页中抓取的图片 */
- (NSArray *)sortImageFromArray:(NSArray *)array
{
    NSMutableArray *imageArray = [NSMutableArray array];
    for (NSString *urlString in array) {
        
        if (!urlString || [urlString isEqual:[NSNull null]] || [urlString isKindOfClass:[NSNull class]] ) continue ;
        NSString *lowString = urlString.lowercaseString;
        if ([lowString hasPrefix:@"http"]
            &&([lowString.lowercaseString containsString:@".jpg"] ||
               [lowString.lowercaseString containsString:@".jpeg"]||
               [lowString.lowercaseString containsString:@".png"] ||
               [lowString.lowercaseString containsString:@".gif"])) {
            
            [imageArray addObject:urlString];
        }
    }
    return (NSArray *)imageArray;
}

/** 注入忽略event的方法 */
- (void)addJSFuntionIgnoreEvent
{
    //注入JS方法
    NSString *hrefJS = JSFunctionEventIgnore;
    [self evaluateJavaScript:hrefJS completionHandler:nil];
}

/** 注入添加忽略事件 */
- (void)addJSFunctionAddEventCanalWithObject:(CGPoint)point
{
    //注入JS方法
    NSString *hrefJS = JSFunctionAddEventCanal;
    [self evaluateJavaScript:hrefJS completionHandler:nil];
    
    //调用JS方法
    NSString *hrefFunc = [NSString stringWithFormat:@"JSAddEventCanal(%lf,%lf)",point.x,point.y];
    [self evaluateJavaScript:hrefFunc completionHandler:^(id _Nullable image, NSError * _Nullable error)
     {
         NSLog(@"%@",image);
     }];
}

/** 注入添加忽略事件 */
- (void)addJSFunctionRemoveEventCanalWithObject:(CGPoint)point
{
    //注入JS方法
    NSString *hrefJS = JSFunctionRemoveEventCanal;
    [self evaluateJavaScript:hrefJS completionHandler:nil];
    
    //调用JS方法
    NSString *hrefFunc = [NSString stringWithFormat:@"JSRemoveEventCanal(%lf,%lf)",point.x,point.y];
    [self evaluateJavaScript:hrefFunc completionHandler:^(id _Nullable image, NSError * _Nullable error)
     {
         NSLog(@"%@",image);
     }];
}

#pragma mark -

#pragma mark - 检测获取的网页元素

/** 检测图片 */
- (void)detectQRCodeInWebView:(UILongPressGestureRecognizer *)pressSender
{
    //获取长按位置对应的图片url的JS代码
    NSString *imgJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
    NSString *titleJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).innerText", touchPoint.x, touchPoint.y];
    
    //判断是否是标题还是文章
    NSString * typeJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).tagName", touchPoint.x, touchPoint.y];
    
    // 执行对应的JS代码 获取url
    __block NSString *imgUrlString;
    __weak typeof(self)weekSelf = self;
    
    //抓取image
    [self evaluateJavaScript:imgJS completionHandler:^(id _Nullable imgUrl, NSError * _Nullable error)
     {
         __strong typeof(self)strongSelf = weekSelf;
         imgUrlString = imgUrl;
         
         //抓取title
         [strongSelf evaluateJavaScript:titleJS completionHandler:^(id _Nullable title, NSError * _Nullable error)
          {
              //抓取title的类型
              [strongSelf evaluateJavaScript:typeJS completionHandler:^(id _Nullable t, NSError * _Nullable error) {
                  
                  //抓取href
                  [self hrefFromJSPointX:touchPoint.x ppintY:touchPoint.y callBack:^(NSString *hre) {
                      
                      [self showActionWithImage:imgUrlString href:hre title:title type:t];
                  }];
              }];
          }];
     }];
}

/** 弹出检测出来的信息 */
- (void)showActionWithImage:(NSString *)imageUrl href:(NSString *)href title:(NSString *)title type:(NSString *)t
{
    NSString *type = t;
    NSString *innerTitle = title;
    NSString *imgUrlString = imageUrl;
    if ((!imageUrl || [imageUrl isEqualToString:@""] ||
         !([imgUrlString.lowercaseString containsString:@".jpg"] ||
           [imgUrlString.lowercaseString containsString:@".jpeg"]||
           [imgUrlString.lowercaseString containsString:@".png"] ||
           [imgUrlString.lowercaseString containsString:@".gif"]))
        && (innerTitle.length <= 0))
    {
        return;
    }
    
    //长按操作
    UIAlertController *showActionTip =
    [UIAlertController alertControllerWithTitle:nil
                                        message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    //识别二维码
    NSURL *url = [self detectQRCode:self];
    
#pragma mark -
#pragma mark - 创建按钮
    
    UIAlertAction *ActionSacn = [UIAlertAction actionWithTitle:@"识别二维码"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action)
                                 {
                                     longPress ? longPress(NO) : NULL;
                                     //返回二维码信息
                                     [[NSNotificationCenter defaultCenter] postNotificationName:NotiName_LoadRequest object:nil userInfo:@{Key_LoadQRCodeUrl:url.absoluteString}];
                                 }];
    
    
    //看图模式
    UIAlertAction *ActionIntoImageMode = [UIAlertAction actionWithTitle:@"进入看图模式" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        longPress ? longPress(NO) : NULL;
        [self showAllImageFromHtmIndex:imgUrlString];
    }];
     
    
    //下载图片
    UIAlertAction *ActionloadImage = [UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        longPress ? longPress(NO) : NULL;
        [self LoadImageFromURL:[NSURL URLWithString:imgUrlString]];
    }];
    
    //复制图片地址
    UIAlertAction *ActionCopyImageLink = [UIAlertAction actionWithTitle:@"复制图片地址" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        longPress ? longPress(NO) : NULL;
        [UIPasteboard generalPasteboard].string = imgUrlString;
        
    }];
    
    //分享图片
    UIAlertAction *ActionShareImage = [UIAlertAction actionWithTitle:@"分享图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        longPress ? longPress(NO) : NULL;
    }];
    
    //复制标题
    UIAlertAction *ActionCopyInnerTitle = [UIAlertAction actionWithTitle:@"复制链接文字" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        longPress ? longPress(NO) : NULL;
        [UIPasteboard generalPasteboard].string = innerTitle;
        
    }];
    
    //复制链接地址
    UIAlertAction *ActionCopyHref = [UIAlertAction actionWithTitle:@"复制链接地址" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        longPress ? longPress(NO) : NULL;
        [UIPasteboard generalPasteboard].string = href;
        
    }];
    
    
    //取消
    UIAlertAction *Canel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        longPress ? longPress(NO) : NULL;
        
    }];
    
    
#pragma mark -
#pragma mark - 显示按钮

    //添加图片相关的操作
    if ([imgUrlString.lowercaseString hasSuffix:@"jpg"] ||
        [imgUrlString.lowercaseString hasSuffix:@"jpeg"]||
        [imgUrlString.lowercaseString hasSuffix:@"png"] ||
        [imgUrlString.lowercaseString hasSuffix:@"gif"])
    {
        [showActionTip addAction:ActionIntoImageMode];
        [showActionTip addAction:ActionloadImage];
        [showActionTip addAction:ActionShareImage];
        if (url) {
            [showActionTip addAction:ActionSacn];
        }
        [showActionTip addAction:ActionCopyImageLink];
    }
    
    //添加链接复制操作
    if (href) {
        [showActionTip addAction:ActionCopyHref];
    }
    
    //添加标题相关的操作
    if (innerTitle.length > 0 && [type.lowercaseString containsString:@"h"]) {
        [showActionTip addAction:ActionCopyInnerTitle];
    }
    
    //添加取消操作
    [showActionTip addAction:Canel];
    if (showActionTip.actions.count == 1) {
        return;
    }
    
    //响应长长按
    longPress ? longPress(YES) : NULL;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:showActionTip animated:YES completion:nil];
    });
    
}

/** 识别二维码 */
- (NSURL *)detectQRCode:(UIView *)fview
{
    //截图 再读取
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [fview.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:image.CGImage options:nil];
    
    //渲染
    CIContext *ciContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:ciContext options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];// 二维码识别
    NSArray *features = [detector featuresInImage:ciImage];
    
    for (CIQRCodeFeature *feature in features) {
        
        NSURL * url = [NSURL URLWithString: feature.messageString];
        if (url) return url;
    }
    return nil;
}

/** 下载图片 */
- (void)LoadImageFromURL:(NSURL *)URLString
{
    NSData *data = [NSData dataWithContentsOfURL:URLString];
    UIImage *image = [UIImage imageWithData:data];
    if (!image) {
        [UIAlertController PAlertWithTitle:@"提示" message:@"下载失败" completion:nil];
        return;
    }
    [self saveImageFinished:image];
}

/** 保存图片到相册 */
- (void)saveImageFinished:(UIImage *)image
{
    if (!image) {
        [UIAlertController PAlertWithTitle:@"提示" message:@"下载失败" completion:nil];
        return;
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        //写入图片到相册
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success)
        {
            [UIAlertController PAlertWithTitle:@"提示" message:@"已经保存到相册" completion:nil];
        }else
        {
            [UIAlertController PAlertWithTitle:@"提示" message:@"保存失败" completion:nil];
        }
    }];
}


@end
