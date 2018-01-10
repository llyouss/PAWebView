//
//  PAWebNavigationController.m
//  Pkit
//
//  Created by llyouss on 2017/12/19.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import "PAWebNavigationController.h"
#import "PAWKPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface PAWebNavigationController ()<UIGestureRecognizerDelegate>

@property (nonatomic,retain)PAWKPanGestureRecognizer *pan;

@property (assign, nonatomic) BOOL animatedFlag;

@end

@implementation PAWebNavigationController

- (void)setViewControllers:(NSArray *)viewControllers {
    [super setViewControllers:viewControllers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.interactivePopGestureRecognizer.enabled = NO; //禁用系统侧滑
    self.view.backgroundColor = [UIColor whiteColor];
    
    _pan = [[PAWKPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
    _pan.delegate = self;
    
    _pan.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:_pan];
    self.isEnableScroll = YES; //默认开启侧滑
    
}

#pragma mark Pan
- (void)pan:(UIPanGestureRecognizer *)pan
{
    UIGestureRecognizerState state = pan.state;
    switch (state){
            
        case UIGestureRecognizerStatePossible:
            
            break;
        case UIGestureRecognizerStateBegan:
            
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translationPoint = [self.pan translationInView:self.view];
            self.visibleViewController.view.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, translationPoint.x, 0);
            
            break;
        }
        case UIGestureRecognizerStateEnded:
            
            break;
        case UIGestureRecognizerStateCancelled:
            
            break;
        default:
            break;
    }
}

#pragma mark GestureRecognizer Delegate
#define MIN_TAN_VALUE tan(M_PI / 6)

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    
    if (self.viewControllers.count < 2) return NO;
    if (self.animatedFlag) return NO;
    if (![self enablePanBack]) return NO; // 询问当前viewconroller 是否允许右滑返回
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.visibleViewController.view.superview];
    if (touchPoint.x < 0 || touchPoint.y < 10 || touchPoint.x > 220) return NO;
    
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    if (translation.x <= 0) return NO;
    
    // 是否是右滑
    BOOL succeed = fabs(translation.y / translation.x) < MIN_TAN_VALUE;
    if (!self.isEnableScroll) { //个别页面不允许侧滑
        succeed = NO;
    }
    
    return succeed;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer != self.pan) return NO;
    if (self.pan.state != UIGestureRecognizerStateBegan) return NO;
    
    if (otherGestureRecognizer.state != UIGestureRecognizerStateBegan) {
        
        return YES;
    }
    
    CGPoint touchPoint = [_pan startPointWithView:self.visibleViewController.view.superview];
    
    // 点击区域判断 如果在左边 30 以内, 强制手势后退
    if (touchPoint.x < 30) {
        
        [self cancelOtherGestureRecognizer:otherGestureRecognizer];
        return YES;
    }
    
    // 如果是scrollview 判断scrollview contentOffset 是否为0，是 cancel scrollview 的手势，否cancel自己
    if ([[otherGestureRecognizer view] isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)[otherGestureRecognizer view];
        if (scrollView.contentOffset.x <= 0) {
            
            [self cancelOtherGestureRecognizer:otherGestureRecognizer];
            return YES;
        }
    }
    
    return NO;
}

- (void)cancelOtherGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    NSSet *touchs = [self.pan.event touchesForGestureRecognizer:otherGestureRecognizer];
    [otherGestureRecognizer touchesCancelled:touchs withEvent:self.pan.event];
}


#pragma mark - push
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    UIViewController *previousViewController = [self.viewControllers lastObject];
    if (previousViewController) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    // 动画标识，在动画的情况下，禁掉右滑手势
    [self startAnimated:animated];
    [super pushViewController:viewController animated:animated];
}

- (void)startAnimated:(BOOL)animated {
    
    _animatedFlag = YES;
    NSTimeInterval delay = animated ? 0.8 : 0.1;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finishedAnimated) object:nil];
    [self performSelector:@selector(finishedAnimated) withObject:nil afterDelay:delay];
}
- (void)finishedAnimated {
    _animatedFlag = NO;
}


#pragma mark - pop
- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    
    [self startAnimated:animated];
    return [super popViewControllerAnimated:animated];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // TODO: shotStack handle
    return [super popToViewController:viewController animated:animated];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    return [super popToRootViewControllerAnimated:animated];
}


#pragma mark LCPanBackProtocol

- (BOOL)enablePanBack {
    BOOL enable = YES;
    if ([self.visibleViewController respondsToSelector:@selector(enablePanBack:)]) {
        UIViewController<LCPanBackProtocol> *viewController = (UIViewController<LCPanBackProtocol> *)self.visibleViewController;
        enable = [viewController enablePanBack:self];
    }
    if ([self.visibleViewController isKindOfClass:[UITabBarController class]]) {
        enable = NO;
    }
    return enable;
}


- (void)startPanBack {
    if ([self.visibleViewController respondsToSelector:@selector(startPanBack:)]) {
        UIViewController<LCPanBackProtocol> *viewController = (UIViewController<LCPanBackProtocol> *)self.visibleViewController;
        [viewController startPanBack:self];
    }
}

- (void)finshPanBackWithReset:(BOOL)reset {
    if (reset) {
        [self resetPanBack];
    } else {
        [self finshPanBack];
    }
}

- (void)finshPanBack {
    if ([self.visibleViewController respondsToSelector:@selector(finshPanBack:)]) {
        UIViewController<LCPanBackProtocol> *viewController = (UIViewController<LCPanBackProtocol> *)self.visibleViewController;
        [viewController finshPanBack:self];
    }
}

- (void)resetPanBack {
    if ([self.visibleViewController respondsToSelector:@selector(resetPanBack:)]) {
        UIViewController<LCPanBackProtocol> *viewController = (UIViewController<LCPanBackProtocol> *)self.visibleViewController;
        [viewController resetPanBack:self];
    }
}


#pragma mark - ChildViewController

- (UIViewController *)currentViewController {
    UIViewController *result = nil;
    if ([self.viewControllers count] > 0) {
        result = [self.viewControllers lastObject];
    }
    return result;
}

#pragma mark - ParentViewController

- (UIViewController *)previousViewController {
    UIViewController *result = nil;
    if ([self.viewControllers count] > 1) {
        result = [self.viewControllers objectAtIndex:self.viewControllers.count - 2];
    }
    return result;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 删除系统自带的tabBarButton
    for (UIView *tabBar in self.tabBarController.tabBar.subviews) {
        if ([tabBar isKindOfClass:[UIControl class]]) {
            [tabBar removeFromSuperview];
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
