//
//  TPRouter.m
//  OCProject
//
//  Created by 王祥伟 on 2023/11/29.
//

#import "TPRouter.h"
#import <UIKit/UIKit.h>

NSString *const kTPRouterPathURLName = @"native/";
NSString *const kTPRouterPathJumpStyle = @"present";
NSString *const kTPRouterPathNoAnimation = @"noanimation";
NSString *const kTPRouterPathTabbarIndex = @"index_";
NSString *const kTPRouterPathPresentStyle = @"modalPresentationStyle";

@implementation TPRouter

+ (__kindof UIViewController *)jumpUrl:(NSString *)url{
    return [self jumpUrl:url params:nil];
}

+ (__kindof UIViewController *)jumpUrl:(NSString *)url params:(NSDictionary * _Nullable )params{
    if (![url isKindOfClass:[NSString class]]) return nil;
    ///处理一些业务逻辑
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:url];
    NSString *path = urlComponents.path;
    
    if ([path hasPrefix:@"/"]){
        path = [path stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    
    if ([path hasPrefix:kTPRouterPathURLName]) {
        path = [path stringByReplacingOccurrencesOfString:kTPRouterPathURLName withString:@""];
    }
    
    if ([path hasPrefix:kTPRouterPathTabbarIndex]){
        [self backUrl:path];
        return nil;
    }
    
    NSArray <NSString *>*dataComponent = [path componentsSeparatedByString:@"/"];
    if (dataComponent.count == 0) return nil;
    
    NSString *classString = [self classValue][dataComponent.firstObject];
    if (!classString) classString = dataComponent.firstObject;
    Class class = NSClassFromString(classString);
    if (!class) return nil;
    
    NSMutableDictionary *propertys = [NSMutableDictionary dictionaryWithDictionary:params];
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.value&&obj.name) {
            [propertys setObject:obj.value forKey:obj.name];
        }
    }];
    
    __kindof UIViewController *vc = [class yy_modelWithDictionary:propertys];
    if (!vc) return nil;
    __kindof UIViewController *currentVC = UIViewController.currentViewController;
    if (!currentVC) return nil;
    
    ///处理页面重复出现问题
    SEL sel = NSSelectorFromString(@"controllerOverlap");
    if ([currentVC respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        BOOL repeat = [currentVC performSelector:sel];
#pragma clang diagnostic pop
        if (!repeat && [currentVC.class isEqual:vc.class]) {
            return nil;
        }
    };
    
    ///设置动画和跳转方式
    BOOL push = ![dataComponent containsObject:kTPRouterPathJumpStyle];
    BOOL animation = ![dataComponent containsObject:kTPRouterPathNoAnimation];
    
    if (push) {
        vc.hidesBottomBarWhenPushed = YES;
        [currentVC.navigationController pushViewController:vc animated:animation];
    }else{
        ///自定义nav
        Class navClass = NSClassFromString([propertys valueForKey:@"navigationClass"]);
        __kindof UINavigationController *nav = [navClass alloc];
        if (nav && [nav isKindOfClass:[UINavigationController class]]) {
            vc = [nav initWithRootViewController:vc];
        }
        
        ///自定义model
        UIModalPresentationStyle modalStyle;
        switch ([[NSString stringWithFormat:@"%@",propertys[kTPRouterPathPresentStyle]] intValue]) {
            case 0:  modalStyle = UIModalPresentationFullScreen; break;
            case 1:  modalStyle = UIModalPresentationPageSheet; break;
            case 2:  modalStyle = UIModalPresentationFormSheet; break;
            case 3:  modalStyle = UIModalPresentationCurrentContext; break;
            case 4:  modalStyle = UIModalPresentationCustom; break;
            case 5:  modalStyle = UIModalPresentationOverFullScreen; break;
            case 6:  modalStyle = UIModalPresentationOverCurrentContext; break;
            case 7:  modalStyle = UIModalPresentationPopover; break;
            case -2: modalStyle = UIModalPresentationAutomatic; break;
            default: modalStyle = UIModalPresentationFullScreen; break;
        }
        vc.modalPresentationStyle = modalStyle;
        [currentVC presentViewController:vc animated:animation completion:nil];
    }
    
    return vc;
}

+ (void)back{
    [self backUrl:nil];
}

+ (void)backUrl:(NSString * _Nullable)url{
    NSArray <NSString *>*dataComponent = [url componentsSeparatedByString:@"/"];
    
    BOOL animation = ![dataComponent containsObject:kTPRouterPathNoAnimation];
    __kindof UIViewController *currentVC = UIViewController.currentViewController;
    if (!currentVC) return;
    
    NSString *obj = dataComponent.lastObject;
    if ([obj hasPrefix:kTPRouterPathTabbarIndex]) {
        if (currentVC.presentingViewController) {
            [currentVC dismissViewControllerAnimated:animation completion:^{
                [self backUrl:url];
            }];
        }else{
            [[UIViewController currentViewController].navigationController popToRootViewControllerAnimated:animation];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([UIViewController.rootViewController isKindOfClass:[UITabBarController class]]) {
                    __kindof UITabBarController *tabbarController = (UITabBarController *)UIViewController.rootViewController;
                    NSUInteger selectedIndex = [obj stringByReplacingOccurrencesOfString:kTPRouterPathTabbarIndex withString:@""].integerValue;
                    if (selectedIndex < tabbarController.viewControllers.count) tabbarController.selectedIndex = selectedIndex;
                }
            });
        }
    }else{
        if (currentVC.navigationController.viewControllers.count > 1){
            __kindof UINavigationController *nav = currentVC.navigationController;
            Class class = NSClassFromString([self classValue][dataComponent.firstObject]);
            if (!class) class = NSClassFromString(dataComponent.firstObject);
            if (!class){
                [nav popViewControllerAnimated:animation];
                return;
            }
            __kindof UIViewController *toVc;
            for (UIViewController *controller in nav.viewControllers) {
                if ([controller isMemberOfClass:class]) {
                    toVc = controller;
                    break;
                }
            }
            
            toVc ? [nav popToViewController:toVc animated:animation] : [nav popToRootViewControllerAnimated:animation];
         }else if (currentVC.presentingViewController) {
             [currentVC dismissViewControllerAnimated:animation completion:^{
                 [self backUrl:url];
             }];
         }
    }
}

+ (NSDictionary *)classValue {
    return @{};
}

@end
