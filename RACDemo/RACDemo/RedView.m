//
//  RedView.m
//  RA测试
//
//  Created by 茹 on 2018/5/5.
//  Copyright © 2018年 kkx. All rights reserved.
//

#import "RedView.h"

@interface RedView ()

@property (nonatomic, strong) UIButton *btn;


@end

@implementation RedView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor redColor];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeContactAdd];
        
        [self addSubview:btn];
        _btn = btn;
        btn.backgroundColor = [UIColor yellowColor];
        [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}


- (void)btnClick
{
    
    NSLog(@"按钮点击了");
    
    [self.subjectSignal sendNext:@"哈哈哈哈"];
    
    //之前的代理是这么执行的
//    if ([self.delegate respondsToSelector:@selector(redViewBtnClick:)]) {
//        [self.delegate redViewBtnClick:self.btn];
//    }
    
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.btn.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
}

- (RACSubject *)subjectSignal {
    if (!_subjectSignal) {
        _subjectSignal = [RACSubject subject];
    }
    return _subjectSignal;
}

//- (RACSignal *)subjectSignal {
//    if (!_subjectSignal) {
//        _subjectSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//            return nil;
//        }];
//    }
//    return _subjectSignal;
//}

@end
