//
//  SecondViewController.m
//  RACDemo
//
//  Created by zys on 2017/2/16.
//  Copyright © 2017年 XiYiChangXiang. All rights reserved.
//

#import "SecondViewController.h"
#import "ReactiveObjC/ReactiveObjC.h"

@interface SecondViewController ()

@end

@implementation SecondViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - event response
- (IBAction)dismissBtnClicked:(id)sender {
    if (self.delegateSignal) {
        [self.delegateSignal sendNext:@"data"];
    }
}

@end
