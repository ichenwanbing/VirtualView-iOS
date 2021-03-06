//
//  TestViewController.m
//  VirtualViewDemo
//
//  Copyright (c) 2017-2018 Alibaba. All rights reserved.
//

#import "TestViewController.h"
#import <VirtualView/VVBinaryLoader.h>
#import <VirtualView/VVViewFactory.h>
#import <VirtualView/VVViewContainer.h>

@interface TestViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) VVViewContainer *container;

@end

@implementation TestViewController

- (instancetype)initWithFilename:(NSString *)filename
{
    if (self = [super init]) {
        self.title = filename;
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.scrollView = [UIScrollView new];
    [self.view addSubview:self.scrollView];
    
    if (![[VVBinaryLoader shareInstance] getUICodeWithName:self.title]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:self.title ofType:@"out"];
        NSData *buffer = [NSData dataWithContentsOfFile:path];
        [[VVBinaryLoader shareInstance] loadFromBuffer:buffer];
    }
    self.container = (VVViewContainer *)[[VVViewFactory shareFactoryInstance] obtainVirtualWithKey:self.title];
    [self.scrollView addSubview:self.container];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.scrollView.frame = self.view.bounds;
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    self.scrollView.contentSize = CGSizeMake(viewWidth, 1000);
    self.container.frame = CGRectMake(0, 0, viewWidth, 1000);
    [self.container update:self.params];
}

@end
