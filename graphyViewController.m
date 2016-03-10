//
//  graphyViewController.m
//  AVCamManual
//
//  Created by yilun on 2/9/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//


#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "graphViewController.h"
#import "FSLineChart.h"
#import "UIColor+FSPalette.h"


@interface graphViewController ()

@end

@implementation graphViewController

bool stop = true;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor=[UIColor clearColor];
    
    UIButton *backbutton=[[UIButton alloc]initWithFrame:CGRectMake(((self.view.frame.size.width/2)-50),(self.view.frame.size.height-120), 100, 30)];
    [backbutton addTarget:self action:@selector(backbuttonpressed) forControlEvents:UIControlEventTouchUpInside];
    backbutton.layer.borderColor=[UIColor blueColor].CGColor;
    backbutton.layer.cornerRadius=4.0f;
    [backbutton setTitle:@"Back" forState:UIControlStateNormal];
    backbutton.titleLabel.textColor=[UIColor blackColor];
    backbutton.backgroundColor=[UIColor blueColor];
    [self.view addSubview:backbutton];
    
    // Get R G B pixel data
    
        CGImageRef imageRef = _m_image.CGImage;
    
        NSData *data        = (NSData *)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(imageRef)));
        char *pixels        = (char *)[data bytes];
        
        int startX = 100;
        int startY = 100;
        int endX = 100;
        int endY = 800;
        
        NSMutableArray* chartData = [NSMutableArray arrayWithCapacity:256];
        
        int nChart = 0;
        for (int nX = startX; nX < endX+1; nX++)
            for (int nY = startY; nY < endY; nY++)
            {
                int pixelInfo = ((_m_image.size.width  * nY) + nX ) * 4;
                
                int r = pixelInfo;
                int g = pixelInfo+1;
                int b = pixelInfo+2;
                int a = pixelInfo+3;
                
                char colorR = pixels[r];
                char colorG = pixels[g];
                char colorB = pixels[b];
                
                int realR = (colorR + 256) % 256;
                int realG = (colorG + 256) % 256;
                int realB = (colorB + 256) % 256;
                
                int nSum = (int)colorR + (int)colorB + (int)colorG;
                
                chartData[nChart] = [NSNumber numberWithFloat: (float)(realR + realG + realB)];
                nChart++;
            }
        // Creating the line chart
        FSLineChart* lineChart = [[FSLineChart alloc] initWithFrame:CGRectMake(20, 50, [UIScreen mainScreen].bounds.size.width - 40, [UIScreen mainScreen].bounds.size.height - 200)];
        
        lineChart.gridStep = 4;
        lineChart.color = [UIColor fsOrange];
        
        lineChart.labelForIndex = ^(NSUInteger item) {
            return [NSString stringWithFormat:@"%lu",(unsigned long)item];
        };
        
        lineChart.labelForValue = ^(CGFloat value) {
            return [NSString stringWithFormat:@"%.f", value];
        };
        
        [lineChart setChartData:chartData];
        
        [self.view addSubview:lineChart];
}

-(void)backbuttonpressed
{
    [self dismissViewControllerAnimated:NO completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
