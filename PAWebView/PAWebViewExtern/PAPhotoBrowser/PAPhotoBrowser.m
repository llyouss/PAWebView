//
//  PAPhotoBrowser.m
//  Pkit
//
//  Created by llyouss on 2018/5/11.
//  Copyright © 2018年 llyouss. All rights reserved.
//

#import "PAPhotoBrowser.h"
#import <objc/message.h>

@interface PAPhotoBrowser ()

@property (nonatomic, retain) NSMutableArray *thumbs;

@end

@implementation PAPhotoBrowser

+ (instancetype)shareInstance{
    
    static PAPhotoBrowser *photoBrowser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        photoBrowser = [[PAPhotoBrowser alloc]init];
    });
    
    return photoBrowser;
}

- (NSMutableArray *)thumbs{
    
    _thumbs = _thumbs ? _thumbs : [NSMutableArray array];
    return _thumbs;
}

- (void)setPhotos:(NSMutableArray *)photos
{
    _photos = photos;
}

- (void)loadPhotoBrowserShowIndex:(NSInteger)index{
   
#pragma clang diagnostic push
#pragma clang diagnostic  ignored "-Wundeclared-selector"
    
    id photo;
    Class photoClass = NSClassFromString(@"MWPhoto");
    __weak typeof(self)weakSelf = self;
    
    [self.thumbs removeAllObjects];
    
    //添加图片
    for (id imageOBJ in _photos) {
        if ([imageOBJ isKindOfClass:[NSString class]]) {
            

           photo = ((id (*)(id, SEL, NSURL *))
             objc_msgSend)(photoClass,
                           @selector(photoWithURL:),
                           [NSURL URLWithString:imageOBJ]
                           );
        }else if ([imageOBJ isKindOfClass:[NSURL class]]){
            photo = ((id (*)(id, SEL, NSURL *))
                     objc_msgSend)(photoClass,
                                   @selector(photoWithURL:),
                                   [NSURL URLWithString:imageOBJ]
                                   );
        }else if ([imageOBJ isKindOfClass:[UIImage class]]){
            
            photo = ((id (*)(id, SEL, NSString *))
                     objc_msgSend)(photoClass,
                                   @selector(photoWithImage:),
                                   imageOBJ
                                   );
            
        }
        [weakSelf.thumbs addObject:photo];
    }
    
    //添加视频
    for (NSString *videoURLString in _video) {
        
        __block id video;
        [self thumbnailImageWithUrl:[NSURL URLWithString:videoURLString] completion:^(UIImage *iamge) {

            video = ((id (*)(id, SEL, UIImage *))
                     objc_msgSend)(photoClass,
                                   @selector(photoWithImage:),
                                   iamge
                                   );
            [video setObject:[NSURL URLWithString:videoURLString] forKey:@"videoURL"];
            [weakSelf.thumbs addObject:video];
        }];
    }
    
    // Create browser
    UIViewController * browser = [NSClassFromString(@"MWPhotoBrowser") alloc];

    if (!browser) {
        NSLog(@"请使用拖入MWPhotoBrowser框架");
        return ;
    }
    
    SEL fun = NSSelectorFromString(@"initWithDelegate:");
    if ([browser respondsToSelector:fun]) {
        
#pragma clang diagnostic push
#pragma clang diagnostic "-Warc-performSelector-leaks"
        browser = [browser performSelector:fun withObject:self];
#pragma clang diagnostic pop
        
    }else{
        NSLog(@"请使用PAPhotoBrowser扩展！");
        return ;
    }
    
    [browser setValue:@YES forKey:@"displayActionButton"];
    [browser setValue:@YES forKey:@"displayNavArrows"];
    [browser setValue:@NO forKey:@"displaySelectionButtons"];
    [browser setValue:@NO forKey:@"alwaysShowControls"];
    [browser setValue:@YES forKey:@"zoomPhotosToFill"];
    [browser setValue:@NO forKey:@"enableGrid"];
    [browser setValue:@NO forKey:@"startOnGrid"];
    [browser setValue:@NO forKey:@"enableSwipeToDismiss"];
    [browser setValue:@NO forKey:@"autoPlayOnAppear"];

    //设置位置
    ((void (*)(id, SEL, NSInteger))
     objc_msgSend)(browser,
                   @selector(setCurrentPhotoIndex:),
                   index
                   );
    
    //监听
    ((void (*)(id, SEL, id, NSString *, unsigned long, void *))
     objc_msgSend)(browser.navigationItem,
                   @selector(addObserver:forKeyPath:options:context:),
                   self,
                   @"rightBarButtonItem",
                   1,
                   NULL
                   );

#pragma clang diagnostic pop

    // Present
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.getCurrentVC presentViewController:nc animated:YES completion:nil];
}

/** 替换 done */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"rightBarButtonItem"])
    {
        if ([object isKindOfClass:[UINavigationItem class]])
        {
            NSArray *array = [object valueForKey:@"_rightBarButtonItems"];
            for (UIBarButtonItem *doneButton in array) {
                if ([doneButton.title.lowercaseString isEqualToString:@"done"]) {
                    [doneButton setTitle:@"关闭"];
                    [object removeObserver:self forKeyPath:@"rightBarButtonItem"];
                }
            }
        }
    }
}

#pragma mark - MWPhotoBrowserDelegate

//实现MWPhotoBrowser 的代理方法
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
#pragma clang diagnostic push
#pragma clang diagnostic  ignored "-Wundeclared-selector"
    
    if (sel == @selector(numberOfPhotosInPhotoBrowser:))
    {
        //添加代理方法
        class_addMethod(self, @selector(numberOfPhotosInPhotoBrowser:), (IMP)numberOfPhotosInPhotoBrowser, "v@:");
        
    }
    
    if (sel == @selector(photoBrowser:photoAtIndex:))
    {
        //添加代理方法
        class_addMethod(self, @selector(photoBrowser:photoAtIndex:), (IMP)photoBrowserPhotoAtIndex, "v@:");
    }
    
    return [super resolveInstanceMethod:sel];
#pragma clang diagnostic pop
}

//实现代理方法 - (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
unsigned long numberOfPhotosInPhotoBrowser(id self,SEL sel,id object){
    
    return [self thumbs].count ;
}

//实现代理方法 - (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;
id photoBrowserPhotoAtIndex(id self, SEL sel, id obj, unsigned long index){
   
    if (index < [self thumbs].count)
        return [[self thumbs] objectAtIndex:index];
    return nil;
}

//获取视频的缩略图
- (void) thumbnailImageWithUrl:(NSURL *)videoURL completion:(void (^)(UIImage *iamge))block {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CMTime time = CMTimeMakeWithSeconds(0.0, 5);
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    UIImage*thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage: thumbnailImageRef] : nil;
    
    block ? block(thumbnailImage) : NULL;
}

//获取Window当前显示的ViewController
- (UIViewController*)getCurrentVC
{
    //获得当前活动窗口的根视图
    UIViewController* vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (1)
    {
        //根据不同的页面切换方式，逐步取得最上层的viewController
        if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = ((UITabBarController*)vc).selectedViewController;
        }
        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = ((UINavigationController*)vc).visibleViewController;
        }
        if (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }else{
            break;
        }
    }
    return vc;
}

@end
