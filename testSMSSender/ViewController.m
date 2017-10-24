//
//  ViewController.m
//  testSMSSender
//
//  Created by xiao xiao on 2017/8/3.
//  Copyright © 2017年 xiao xiao. All rights reserved.
//

#import "ViewController.h"
#import "XXRootViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnAction:(id)sender {
    XXRootViewController* root = [XXRootViewController new];
    [self.navigationController pushViewController:root animated:YES];
}

@end
