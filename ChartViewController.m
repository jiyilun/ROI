//
//  ChartViewController.m
//  avcammanual
//
//  Created by System Administrator on 3/19/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

#import "ChartViewController.h"

@interface ChartViewController ()

@end

@implementation ChartViewController
@synthesize barChart;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        [self loadBarChartUsingArray];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadBarChartUsingArray {
    //Generate properly formatted data to give to the bar chart
    
    NSString *sR = [NSString stringWithFormat:@"%d", _nR];
    NSString *sG = [NSString stringWithFormat:@"%d", _nG];
    NSString *sB = [NSString stringWithFormat:@"%d", _nB];
    
    NSArray *array = [barChart createChartDataWithTitles:[NSArray arrayWithObjects:@"Green", @"Blue", @"Red",  nil]
                                                  values:[NSArray arrayWithObjects:sR, sG, sB, nil]
                                                  colors:[NSArray arrayWithObjects:@"87E317", @"17A9E3", @"E32F17", nil]
                                             labelColors:[NSArray arrayWithObjects:@"FFFFFF", @"FFFFFF", @"FFFFFF",  nil]];
    
    //Set the Shape of the Bars (Rounded or Squared) - Rounded is default
    [barChart setupBarViewShape:BarShapeRounded];
    
    //Set the Style of the Bars (Glossy, Matte, or Flat) - Glossy is default
    [barChart setupBarViewStyle:BarStyleGlossy];
    
    //Set the Drop Shadow of the Bars (Light, Heavy, or None) - Light is default
    [barChart setupBarViewShadow:BarShadowLight];
    
    //Generate the bar chart using the formatted data
    [barChart setDataWithArray:array
                      showAxis:DisplayOnlyXAxis
                     withColor:[UIColor whiteColor]
       shouldPlotVerticalLines:YES];
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
