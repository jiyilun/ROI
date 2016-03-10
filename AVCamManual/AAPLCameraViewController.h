/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Control of camera functions.
  
*/

#import "SPUserResizableView.h"

@import UIKit;

@interface AAPLCameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, SPUserResizableViewDelegate>
{
    UIImage *image;
    NSString *pathLocation;
    UIButton *Getgraph;
    Boolean isEditingPoint;
    Boolean isSwiped;
    
    int startX;
    int endX;
    int startY;
    int endY;
    int toppointX;
    int toppointY;
    int bottompointX;
    int bottompointY;
    int m_nImageWidth;
    int m_nImageHeight;
    int nLength;
    int xcounts;
    int nLengthgray;
    float ratio;
    SPUserResizableView *rview;
    SPUserResizableView *rview2;
    
    CGFloat curLevel;
    int sumR, sumG, sumB;
    CGFloat curLevel2;
    int sumR2, sumG2, sumB2;

}

@property(nonatomic,strong)UIImageView *myImage;
//- (IBAction)picker:(id)sender;
//@property (strong, nonatomic) UIImagePickerController * iamgePicker;
@property (strong, nonatomic) UIImage *m_image;
@property (nonatomic) Boolean isSpectrum;
extern int peakvalue;
extern int peakpoint_x_value;
extern int distanceofcursors;

@end
