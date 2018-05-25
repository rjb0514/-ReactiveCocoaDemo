# -ReactiveCocoaDemo
ReactiveCocoa学习的Demo

#####首先pod的继承
OC的继承版本为
```
pod 'ReactiveCocoa', :git => 'https://github.com/zhao0/ReactiveCocoa.git', :tag => '2.5.2'
```
RAC这框架是非的强大，可以把iOS的事件，代理，KVO都转成信号的传出，学习起来有点难度，如果要运用的是非灵活的话，得掌握了里面的大部分方法 才可以灵活运用。这个框架也运用了链式编程的思想，都是Block的回调。缺点：后期如果有版本变更，框架使用不了的话就很蛋疼了，因为写代码的时候大部分是直接使用框架的方法，如果框架使用不了了，修改起来还是很费劲的。
######下面都是一些常用的方法
######一、首先介绍下 信号源
RAC的信号源 一般用的话 有三种
RACSignal
RACSubject
RACReplaySubject
1.一个简单的信号的 订阅和发送
RACSignal创建的信号都是冷信号，只有被订阅了 才会立马之前

```
//创建的信号一般都是冷信号
RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {

[subscriber sendNext:@"我是信号"];

return nil;
}];

//只有添加了订阅者 才会变成热信号
[signal subscribeNext:^(id x) {

NSLog(@"接收到的信息---%@",x);
}];
```
2.RACSubject创建的信号
跟RACSignal的区别给订阅者发送信号是手动触犯的 
得调用[sub sendnEST:@2];
```
//1.创建
RACSubject *sub = [RACSubject subject];

//2.订阅信号
[sub subscribeNext:^(id x) {
NSLog(@"11111---%@",x);
}];
//3.发送信号
[sub sendNext:@2];
```
3.RACReplaySubject创建的信号
与 RACSubject的 最大的区别就是 可以先发送数据 在订阅信号

```
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
```
######一、信号的简单实用
1.可以当代理的实用
```
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

在RedView.h中的代码
#import <UIKit/UIKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RedView : UIView

@property (nonatomic, strong) RACSubject *subjectSignal;

@end


在RedView.m中的代码
- (void)btnClick
{

NSLog(@"按钮点击了");

[self.subjectSignal sendNext:@"哈哈哈哈"];

//之前的代理是这么执行的
//    if ([self.delegate respondsToSelector:@selector(redViewBtnClick:)]) {
//        [self.delegate redViewBtnClick:self.btn];
//    }


}
```
2.用来监听某个方法的执行
//模拟器deBug下有模拟内存警告 
```
- (void)daili {
//用来监听某个对象有没有调用某个方法
[[self rac_signalForSelector:@selector(didReceiveMemoryWarning)] subscribeNext:^(id x) {
NSLog(@"模拟内存警告");
}];

}
```
3.代替KVO
```
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
```
4.代替按钮的点击事件等
```
- (void)touchEvent {
[[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
NSLog(@"按钮的点击");
}];
}
```
5.代替通知
```
- (void)notifacation {
[[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"tongzhi" object:nil] subscribeNext:^(id x) {
NSLog(@"接收到通知");
}];
}
```
######三 组合信号
组合信号有好多种情况
1. A B2个信号都执行完 才执行后面的方法
```
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
```
2.类似于 信号合并
```
//信号组合  多个信号中只要有一个执行就执行
- (void)merge {

RACSubject *subjectA = [RACSubject subject];
RACSubject *subjectB = [RACSubject subject];

RACSignal *mergeSignal = [subjectA merge:subjectB];
[mergeSignal subscribeNext:^(id x) {
NSLog(@"%@",x);
}];

[subjectA sendNext:@"1"];
[subjectB sendNext:@"2"];
}
```
3.把两个信号 压成一个
```
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

//在控制台打印的是
2018-05-25 15:47:29.771747+0800 RACDemo[64563:2498367] <RACTuple: 0x600000015650> (
1,
2
)

```

4.两个信号有执行顺序
是按信号顺序来的 必须第一个信号发送完成 而且是 每个信号完成都走一次
```
//信号合并 比喻：皇上-皇太子关系
- (void)concat {

//组合信号
RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {

NSLog(@"发送请求1");
[subscriber sendNext:@"1"];
[subscriber sendCompleted];
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
```
######网络模拟多个请求回来后执行的方法
```
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
```


######四 信号的映射
1.map
```
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

```
2.flattenMap
这个是用于处理信号中的信号的  
```
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

```



#####讲下遇到的坑
1.信号被多次订阅 方法被调用多次 比如
```
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
在控制台的打印是
2018-05-25 15:36:02.573591+0800 RACDemo[64317:2483443] 我要开始发送信号
2018-05-25 15:36:02.573740+0800 RACDemo[64317:2483443] 订阅者1接收到的信息---我是信号
2018-05-25 15:36:02.573876+0800 RACDemo[64317:2483443] 我要开始发送信号
2018-05-25 15:36:02.573985+0800 RACDemo[64317:2483443] 订阅者2接收到的信息---我是信号

```
解决办法
```
1. //信号被订阅多次 调用多次的Bug

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
```
2、
这里有个关于flattenMap的坑
比如我视图有个按钮 要监听按钮的点击事件 然后map后
```
- (RACSignal *)signInSignal {
return [RACSignal createSignal:^RACDisposable *(id subscriber){
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
[subscriber sendNext:@1];
[subscriber sendCompleted];
});
return nil;
}];
}

//flattenMap是真确的  打印会打印是信号发送的 1
[[[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^RACStream *(id value) {
return self.signInSignal;
}] subscribeNext:^(id x) {
NSLog(@"最后的值--%@",x);
}];

//这个是不正确的 打印的 是信号
[[[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] map:^RACStream *(id value) {
return self.signInSignal;
}] subscribeNext:^(id x) {
NSLog(@"最后的值--%@",x);
}];

所以只要是信号中的信号 就得用flattenMap
```



参考文献
https://blog.csdn.net/abc649395594/article/details/45933053
https://blog.csdn.net/abc649395594/article/details/46039363
https://blog.csdn.net/abc649395594/article/details/46123379
https://blog.csdn.net/abc649395594/article/details/46233783
https://blog.csdn.net/abc649395594/article/details/46552865

[简书地址](https://www.jianshu.com/writer#/notebooks/5324419/notes/28578810/preview)