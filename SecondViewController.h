//
//  SecondViewController.h
//  avcammanual
//
//  Created by System Administrator on 2/26/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SecondViewController : UIViewController<UITextFieldDelegate>{
    int m_nImageWidth;
    int m_nImageHeight;

}

    @property (nonatomic, strong) NSMutableArray *m_chartData_ref;
    @property (nonatomic, strong) NSMutableArray *m_chartData_sig;
    @property (nonatomic, strong) NSMutableArray *m_chartData_lam;
    @property (nonatomic, strong) NSMutableArray *m_chartData_gray;//jinbei
    @property (nonatomic, strong) NSMutableArray *m_chartData_peak;


    @property (nonatomic, strong) NSMutableArray *chartRate;
    @property (nonatomic, strong) NSMutableArray *dataPeak;
    @property (nonatomic, strong) NSString *dynamic_peakdata_xls;

    @property (nonatomic) int mstartX;
    @property (nonatomic) int mstartY;
    @property (nonatomic) int mendX;
    @property (nonatomic) int mendY;
    @property (nonatomic) int mlength;
    @property (nonatomic) int xcount;
    @property (nonatomic) int nLength;
    @property (nonatomic) int peakindex;

    @property (nonatomic) int startcursor_x;
    @property (nonatomic) int startcursor_y;
    @property (nonatomic) int endcursor_x;
    @property (nonatomic) int endcursor_y;



    @property (nonatomic, strong) NSMutableArray *m_X;
    @property (nonatomic, strong) NSMutableArray *m_Y;
    @property (nonatomic, strong) IBOutlet UILabel *lblLamda;
    @property (weak, nonatomic) IBOutlet UILabel *peakpointlabel;
    @property (weak, nonatomic) IBOutlet UIView *peaklabelview;

    @property (nonatomic, strong) IBOutlet UIView *viewA;
    @property (nonatomic, strong) IBOutlet UIView *viewB;
    @property (nonatomic, strong) IBOutlet UIView *viewC;

    @property (weak, nonatomic) IBOutlet UITextField *delta_t;
    @property (weak, nonatomic) IBOutlet UITextField *total_t;
    @property (weak, nonatomic) IBOutlet UITextField *peak_valuefield;
@property (weak, nonatomic) IBOutlet UITextField *peak_positionfield;


    @property (weak, nonatomic) IBOutlet UIButton *peak_StartButton;
@property (weak, nonatomic) IBOutlet UILabel *total_time;

@end
