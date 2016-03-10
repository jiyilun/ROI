//
//  ChartViewController.h
//  avcammanual
//
//  Created by System Administrator on 3/19/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BarChartView.h"

@interface ChartViewController : UIViewController
    @property (strong, nonatomic) IBOutlet BarChartView *barChart;
    @property (nonatomic) int nR;
    @property (nonatomic) int nG;
    @property (nonatomic) int nB;
@end
