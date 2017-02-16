//
//  SecondViewController.h
//  RACDemo
//
//  Created by zys on 2017/2/16.
//  Copyright © 2017年 XiYiChangXiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACSubject;

@interface SecondViewController : UIViewController

@property (nonatomic, strong) RACSubject *delegateSignal;

@end
