//
//  ViewController.m
//  RACDemo
//
//  Created by zys on 2017/2/16.
//  Copyright © 2017年 XiYiChangXiang. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "SecondViewController.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //[self testSignal];
    //[self testSubject];
    //[self testCommand];
    //[self testConnection];
    [self testLifeSelector];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // 使用RACSubject代替代理(感觉使用block回调更简单一点，不过使用RAC可以统一代码风格，便于多人开发)
    if ([segue.identifier isEqualToString:@"SecondVCSegue"]) {
        SecondViewController *secondVC = segue.destinationViewController;
        secondVC.delegateSignal = [RACSubject subject];
        [secondVC.delegateSignal subscribeNext:^(id  _Nullable x) {
            NSLog(@"收到secondVC的数据: %@", x);
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - event response
- (IBAction)unwindToRootVC:(UIStoryboardSegue *)segue {}

#pragma mark - custom methods

/**
 *  注意：RACSiganl，只是表示当数据改变时，信号内部会发出数据，它本身不具备发送信号的能
 *  力，而是交给内部一个订阅者去发出
 */
- (void)testSignal {
    // 1.创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        
        // block调用时刻：每当有订阅者订阅信号，就会调用block。
        
        // 2.发送信号
        [subscriber sendNext:@1];
        
        // 如果不在发送数据，最好发送信号完成，内部会自动调用[RACDisposable disposable]取消订阅信号。
        [subscriber sendCompleted];
        
        return [RACDisposable disposableWithBlock:^{
            // block调用时刻：当信号发送完成或者发送错误，就会自动执行这个block,取消订阅信号。
            
            // 执行完Block后，当前信号就不再被订阅了。
            NSLog(@"信号被销毁");
        }];
    }];
    
    // 3.订阅信号,才会激活信号
    [signal subscribeNext:^(id  _Nullable x) {
        // block调用时刻：每当有信号发出数据，就会调用block.
        NSLog(@"接收到数据:%@",x);
    }];
}

/**
 *  注意：RACSubject:信号提供者，自己可以充当信号，又能发送信号；必须先订阅，才能发送
 *  使用场景：代替代理。使用RACSignal不能代替代理的原因（以vc1跳转到vc2为例）：RACSignal本身不能发送信号，所以不能在vc1里创建信号，只能在vc2里创建并发送信号，这样造成的结果就是：vc1跳转vc2之前，信号是空的不能订阅，所以就收不到数据了；而RACSubject本身可以发送信号，在vc1跳转vc2之前就可以在vc1里创建vc2的信号并订阅信号来接收数据，然后在vc2需要回传数据的地方发送信号即可。
 */
- (void)testSubject {
    // 1.创建信号
    RACSubject *subject = [RACSubject subject];
    
    // 2.订阅信号
    [subject subscribeNext:^(id x) {
        // block调用时刻：当信号发出新值，就会调用.
        NSLog(@"第一个订阅者收到数据: %@", x);
    }];
    [subject subscribeNext:^(id x) {
        // block调用时刻：当信号发出新值，就会调用.
        NSLog(@"第二个订阅者收到数据: %@", x);
    }];
    
    // 3.发送信号
    [subject sendNext:@"1"];
}

/**
 *  RACCommand：处理事件，监控事件的执行过程。
 *  注意：RACCommand不执行（execute），订阅者是收不到信号的
 *  使用场景：网络请求。使用RACSingnal也可以监听网络请求，并回传数据；使用RACCommand在执行（execute）的时候，可以传递参数，RACSingnal则办不到；其次，RACCommand的block返回信号时，可以返回一个新的模型信号，可以用于模型解析
 */
- (void)testCommand {
    // 1.创建命令
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        
        NSLog(@"执行命令");
        
        // 创建空信号,必须返回信号
        //return [RACSignal empty];
        
        // 2.创建信号,用来传递数据
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            
            [subscriber sendNext:@"请求数据"];
            
            // 注意：数据传递完，最好调用sendCompleted，这时命令才执行完毕。
            [subscriber sendCompleted];
            return nil;
        }];
    }];
    
    // 3.订阅RACCommand中的信号
//    [command.executionSignals subscribeNext:^(id x) {
//        [x subscribeNext:^(id x) {
//            NSLog(@"%@",x);
//        }];
//    }];
    
    // RAC高级用法
    // switchToLatest:用于signal of signals，获取signal of signals发出的最新信号,也就是可以直接拿到RACCommand中的信号
    [command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
       NSLog(@"接收数据: %@",x);
    }];
    
    // 4.监听命令是否执行完毕,默认会来一次，可以直接跳过，skip表示跳过第一次信号;take表示总共执行一次
    [[[command.executing skip:1] take:1] subscribeNext:^(NSNumber * _Nullable x) {
        if (x.boolValue == YES) {
            NSLog(@"正在执行");
        } else {
            NSLog(@"执行完成");
        }
    }];
    
    // 5.执行命令
    [command execute:nil];
}


/**
 *  RACMulticastConnect
 *  使用场景：假设在一个信号中发送请求，每次订阅一次都会发送请求，这样就会导致多次请求，使用RACMulticastConnection就能解决
 */
- (void)testConnection {
//    // 1.创建请求信号
//    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
//        NSLog(@"发送请求");
//        [subscriber sendNext:@"data"];
//        return nil;
//    }];
//    
//    // 2.订阅信号
//    [signal subscribeNext:^(id  _Nullable x) {
//        NSLog(@"订阅者一接收数据: %@", x);
//    }];
//    [signal subscribeNext:^(id  _Nullable x) {
//        NSLog(@"订阅者二接收数据: %@", x);
//    }];
//    
//    // 3.运行结果，会执行两遍发送请求，也就是每次订阅都会发送一次请求
    
    // RACMulticastConnection:解决重复请求问题
    // 1.创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"发送请求");
        [subscriber sendNext:@"data"];
        return nil;
    }];
    
    // 2.创建连接
    RACMulticastConnection *connection = [signal publish];
    
    // 3.订阅信号，
    // 注意：订阅信号，也不能激活信号，只是保存订阅者到数组，必须通过连接,当调用连接，就会一次性调用所有订阅者的sendNext:
    [connection.signal subscribeNext:^(id  _Nullable x) {
       NSLog(@"订阅者一信号: %@", x);
    }];
    
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"订阅者二信号: %@", x);
    }];
    
    // 4.连接,激活信号
    [connection connect];
}

/**
 *  rac_liftSelector: 当传入的Signals(信号数组)，每一个signal都至少sendNext过一次，就会去触发第一个selector参数的方法
 *  使用场景：处理多个请求，都返回结果的时候，统一做处理（例如刷新UI）
 */
- (void)testLifeSelector {
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"发送请求1");
        [subscriber sendNext:@"数据1"];
        return nil;
    }];
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"发送请求2");
        [subscriber sendNext:@"数据2"];
        return nil;
    }];
    
    // 使用注意：几个信号，参数一的方法就几个参数，每个参数对应信号发出的数据
    [self rac_liftSelector:@selector(updateUI:andData2:) withSignalsFromArray:@[request1, request2]];
}

- (void)updateUI:(id)data1 andData2:(id)data2 {
    NSLog(@"updateUI: %@, %@", data1, data2);
}

@end
