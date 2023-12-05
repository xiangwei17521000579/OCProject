//
//  TPHomeViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/5.
//

#import "TPHomeViewController.h"
#import "TPNetworkManager.h"
@interface TPHomeViewController ()

@end

@implementation TPHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [TPNetworkManager post:@"fxtpplatform/information/app/live/anonymous/queryDailyLiveStatus" params:nil success:^(id  _Nonnull responseObject) {
        
    } failure:^(TPNetworkError * _Nonnull error) {
        
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [TPMediator performTarget:TPRouterModel.routerClass action:TPRouterModel.routerJumpUrl object:@"url=test"];
}

@end