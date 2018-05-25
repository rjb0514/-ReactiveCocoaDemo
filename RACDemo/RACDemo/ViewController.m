//
//  ViewController.m
//  RACDemo
//
//  Created by ru on 2018/5/25.
//  Copyright © 2018年 ru. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>
#import "RedView.h"
#import "NSObject+RACKVOWrapper.h"
#import "RACReturnSignal.h"



@interface ViewController ()

@property (nonatomic, strong) RedView         *redView;

@property (nonatomic, strong) UIButton         *btn;

@property (nonatomic, strong) RACSignal         *signInSignal;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.btn];
    [self network];
    
    
//    [[self.btn.rac_command.executionSignals map:^id(id value) {
//        return value;
//    }]subscribeNext:^(id x) {
//        //结果是个这个  RACTuple
//        NSLog(@"最后结果:-%@",x);
//    }];
    
 

}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.redView.frame = CGRectMake(200, 200, 100, 100);
}


#pragma mark - 坑
- (void)test {
    
    [[[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^RACStream *(id value) {
        return self.signInSignal;
    }] subscribeNext:^(id x) {
        NSLog(@"最后的值--%@",x);
    }];
    
    [[[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] map:^RACStream *(id value) {
        return self.signInSignal;
    }] subscribeNext:^(id x) {
        NSLog(@"最后的值--%@",x);
    }];
}
- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id subscriber){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:@1];
            [subscriber sendCompleted];
        });
        return nil;
    }];
}

#pragma mark - 信号的映射
//信号的映射
- (void)map {
    
    //1.创建信号
    RACSubject *subject = [RACSubject subject];
    
    //2.绑定信号
    RACSignal *bindSignal = [subject map:^id(id value) {
        
        //修改value的值
        return [NSString stringWithFormat:@"啦啦--%@",value];
    }];
    
    [bindSignal subscribeNext:^(id x) {
        
        NSLog(@"map后的值——--%@",x);
    }];
    
    //发送数据
    [subject sendNext:@"123"];
}

- (void)flattenMap2  {
    
    //flattenMap是用于信号中的信号
    RACSubject *subject = [RACSubject subject];
    RACSubject *subject2 = [RACSubject subject];
    
    [[subject flattenMap:^RACStream *(id value) {
        return value;
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //发送信号
    [subject sendNext:subject2];
    [subject2 sendNext:@"2"];
}

//信号的绑定  --  flattenMap
- (void)flattenMap {
    //1.创建信号
    RACSubject *subject = [RACSubject subject];
    
    //2.绑定信号
    RACSignal *bindSignal = [subject flattenMap:^RACStream *(id value) {
        //value 是源信号的内容
        
        //返回修改后的内容  需要这个头文件 #import "RACReturnSignal.h"
        return [RACReturnSignal return:@"ru"];
        
    }];
    
    [bindSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    //发送数据
    [subject sendNext:@"123"];
}


#pragma mark - 信号的组合
- (void)combienReduce {
    //组合信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"发送请求1");
        [subscriber sendNext:@"1"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"发送请求2");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [subscriber sendNext:@"2"];
        });
        return nil;
    }];
    
    //组合信号  只有前2个信号都执行完才执行这个
    [[RACSignal combineLatest:@[signal,signal2] reduce:^id(NSString *str,NSString *str2){
        NSLog(@"%@--%@",str,str2);
        NSString *str3 = [NSString stringWithFormat:@"%@--%@",str,str2];
        return str3;
    }] subscribeNext:^(id x) {
        NSLog(@"最后收到的数据--%@",x);
    }] ;
}


//多请求结束后 执行代码
- (void)network {
    
    //请求热销模块
    RACSignal *hotSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"热销请求数据");
        [subscriber sendNext:@"热销请求数据发送"];
        return nil;
    }];
    
    //请求最新模块
    RACSignal *newSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"最新请求数据");
        [subscriber sendNext:@"最新请求数据发送"];
        return nil;
    }];
    
    
    //当一个界面有多个请求的时候，需保证所有请求都回来 才执行的方法
    //方法的参数必须要跟数组的信号 一一对应
    //方法的参数是每个信号发送的数据
    [self rac_liftSelector:@selector(updateUIWithHot:new:) withSignalsFromArray:@[newSignal,hotSignal]];
    
}

- (void)updateUIWithHot:(NSString *)str1 new:(NSString *)str2 {
    NSLog(@"%@0---%@",str1,str2);
}

//信号组合  多个信号中只要有一个执行就执行
- (void)merge {
    
    RACSubject *subjectA = [RACSubject subject];
    RACSubject *subjectB = [RACSubject subject];
    
    RACSignal *mergeSignal = [subjectA merge:subjectB];
    [mergeSignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [subjectA sendNext:@"1"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [subjectB sendNext:@"2"];
    });
}

//把两个信号 压缩成一个  比喻：夫妻关系
- (void)zimpSignal {
    
    RACSubject *subjectA = [RACSubject subject];
    RACSubject *subjectB = [RACSubject subject];
    
    //当所有请求都回来时
    RACSignal *mergeSignal = [subjectA zipWith:subjectB];
    [mergeSignal subscribeNext:^(id x) {
        //返回来的是组合 tuple
        NSLog(@"%@",x);
    }];
    
    [subjectA sendNext:@"1"];
    [subjectB sendNext:@"2"];
    
}

//信号合并 比喻：皇上-皇太子关系
- (void)concat {
    
    //组合信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"发送请求1");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:@"1"];
            [subscriber sendCompleted];
        });
        return nil;
    }];
    
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"发送请求2");
        [subscriber sendNext:@"2"];
        return nil;
    }];
    
    
    //组合信号
    //concat 是按信号顺序来的 必须第一个信号发送完成 而且是 每个信号完成都走一次
    RACSignal *concatSignal = [signal concat:signal2];
    [concatSignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}



#pragma makr - 信号的简单实用
//信号做代理使用
- (void)redDelegate {
    RedView *red  = [[RedView alloc] initWithFrame:CGRectMake(100, 100, 200, 200)];
    
    [self.view addSubview:red];
    self.redView = red;
    
    //信号做代理使用
    [red.subjectSignal subscribeNext:^(id x) {
        NSLog(@"代理传值过来:--%@",x);
    }];
}

//2.代理KVO
- (void)racKVO {
    
    //方法1 需要导入头文件  #import "NSObject+RACKVOWrapper.h"
    [self.redView rac_observeKeyPath:@"frame" options:(NSKeyValueObservingOptionNew) observer:nil block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
         NSLog(@"KVO 1:--%@",value);
    }];
    
    //方法2
    [[self.redView rac_valuesForKeyPath:@"frame" observer:nil] subscribeNext:^(id x) {
        NSLog(@"KVO 2:--%@",x);
    }];
    
}

//事件的监听
- (void)touchEvent {
    [[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        NSLog(@"按钮的点击");
    }];
}

- (void)daili {
    //用来监听某个对象有没有调用某个方法
    [[self rac_signalForSelector:@selector(didReceiveMemoryWarning)] subscribeNext:^(id x) {
        NSLog(@"模拟内存警告");
    }];
    
}
//代替通知
- (void)notifacation {
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"tongzhi" object:nil] subscribeNext:^(id x) {
        NSLog(@"接收到通知");
    }];
}


#pragma mark - 三种信号源
- (void)subject {
    //1.创建
    RACSubject *sub = [RACSubject subject];
    
    //2.订阅信号
    [sub subscribeNext:^(id x) {
        NSLog(@"11111---%@",x);
    }];
    //3.发送信号
    [sub sendNext:@2];
    
}

- (void)RACReplaySubject {
    //1.创建
    RACReplaySubject *replaySub = [RACReplaySubject subject];
    //2.订阅信号
    [replaySub subscribeNext:^(id x) {
        NSLog(@"11111---%@",x);
    }];
    //遍历所有值发送信号
    
    //3.发送信号
    [replaySub sendNext:@2];
    //RACReplaySubject发送数据
    //1.保存值
    //2.遍历所有订阅者，发送信号
    
    
    [replaySub subscribeNext:^(id x) {
        NSLog(@"22222---%@",x);
    }];
    
    //与 RACSubject的 最大的区别就是 可以先发送数据 在订阅信号
}

- (void)signal {
    //创建的信号一般都是冷信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"我要开始发送信号");
        //网络请求的代码
        //比如 requestData
        [subscriber sendNext:@"我是信号"];
        
        return nil;
    }];
    
    //只有添加了订阅者 才会变成热信号
    [signal subscribeNext:^(id x) {
        
        NSLog(@"订阅者1接收到的信息---%@",x);
    }];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"订阅者2接收到的信息---%@",x);
    }];
}

#pragma mark - 订阅多次 信号被多次调用的Bug
- (void)signalBug {
    //创建的信号一般都是冷信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"我要开始发送信号");
        //网络请求的代码
        //比如 requestData
        [subscriber sendNext:@"我是信号"];
        
        return nil;
    }];
    
    //只有添加了订阅者 才会变成热信号
    [signal subscribeNext:^(id x) {
        
        NSLog(@"订阅者1接收到的信息---%@",x);
    }];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"订阅者2接收到的信息---%@",x);
    }];
}

- (void)multicastSignal {
    
    //信号被订阅多次 调用多次的Bug
    
    //    1.创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"发送请求");
        [subscriber sendNext:@"1"];
        
        return nil;
    }];
    //    2.把信号转成连接类  RACMulticastConnection ---- signal->publish
    RACMulticastConnection *connection = [signal publish];
    //    3.订阅信号
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"第一个订阅者--%@",x);
    }];
    
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"第二个订阅者--%@",x);
    }];
    //    4.连接
    [connection connect];
}


#pragma mark - lazy
- (UIButton *)btn {
    if (!_btn) {
        _btn = [UIButton buttonWithType:UIButtonTypeContactAdd];
        _btn.center = self.view.center;
        [_btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btn;
}

- (void)btnClick {
    NSLog(@"按钮的点击");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"收到内存警告了");
}

@end
