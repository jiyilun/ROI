//
//  FirstViewController.m
//  avcammanual
//
//  Created by System Administrator on 3/16/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

#import "FirstViewController.h"
#import "AAPLCameraViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pressSpectrum:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    AAPLCameraViewController *viewController =   [storyboard instantiateViewControllerWithIdentifier:@"cameraView"];
    
    viewController.isSpectrum = true;
    [self.navigationController pushViewController:viewController animated:YES];

    
    
}

- (IBAction)pressImage:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    AAPLCameraViewController *viewController =   [storyboard instantiateViewControllerWithIdentifier:@"cameraView"];
    
    viewController.isSpectrum = false;
    [self.navigationController pushViewController:viewController animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
