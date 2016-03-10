/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Control of camera functions.
  
 */

#import "AAPLCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
//#import "graphViewController.h"
#import "AAPLPreviewView.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "FSLineChart.h"
#import "UIColor+FSPalette.h"
#import "DragButton.h"
#import "SecondViewController.h"
#import "ChartViewController.h"

int peakvalue=0;
int peakpoint_x_value=0;
int distanceofcursors=0;

static void *CapturingStillImageContext = &CapturingStillImageContext;
static void *RecordingContext = &RecordingContext;
static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

static void *FocusModeContext = &FocusModeContext;
static void *ExposureModeContext = &ExposureModeContext;
static void *WhiteBalanceModeContext = &WhiteBalanceModeContext;
static void *LensPositionContext = &LensPositionContext;
static void *ExposureDurationContext = &ExposureDurationContext;
static void *ISOContext = &ISOContext;
static void *ExposureTargetOffsetContext = &ExposureTargetOffsetContext;
static void *DeviceWhiteBalanceGainsContext = &DeviceWhiteBalanceGainsContext;

@interface AAPLCameraViewController () <AVCaptureFileOutputRecordingDelegate>


@property (nonatomic, strong) DragButton *bt_drag1;
@property (nonatomic, strong) DragButton *bt_drag2;

@property (nonatomic, strong) FSLineChart *lineChart;
@property (nonatomic, strong) FSLineChart *lineChart1;
@property (nonatomic, strong) FSLineChart *lineChart2;


@property (nonatomic, weak) IBOutlet AAPLPreviewView *previewView;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *stillButton;

@property (nonatomic, weak) IBOutlet UIView *viewColors;
@property (nonatomic, strong) UILabel *lblRed;
@property (nonatomic, strong) UILabel *lblBlue;
@property (nonatomic, strong) UILabel *lblGreen;
@property (nonatomic, strong) UILabel *lblSum;

@property (nonatomic, weak) IBOutlet UIView *viewColors2;
@property (nonatomic, strong) UILabel *lblRed2;
@property (nonatomic, strong) UILabel *lblBlue2;
@property (nonatomic, strong) UILabel *lblGreen2;
@property (nonatomic, strong) UILabel *lblSum2;

@property (nonatomic, strong) NSArray *focusModes;
@property (nonatomic, strong) NSMutableArray *m_chartData;

@property (nonatomic, weak) IBOutlet UIView *manualHUDFocusView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *focusModeControl;
@property (nonatomic, weak) IBOutlet UISlider *lensPositionSlider;
@property (nonatomic, weak) IBOutlet UILabel *lensPositionNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *lensPositionValueLabel;

@property (nonatomic, strong) NSArray *exposureModes;
@property (nonatomic, weak) IBOutlet UIView *manualHUDExposureView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *exposureModeControl;
@property (nonatomic, weak) IBOutlet UISlider *exposureDurationSlider;
@property (nonatomic, weak) IBOutlet UILabel *exposureDurationNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *exposureDurationValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *ISOSlider;
@property (nonatomic, weak) IBOutlet UILabel *ISONameLabel;
@property (nonatomic, weak) IBOutlet UILabel *ISOValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *exposureTargetBiasSlider;
@property (nonatomic, weak) IBOutlet UILabel *exposureTargetBiasNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *exposureTargetBiasValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *exposureTargetOffsetSlider;
@property (nonatomic, weak) IBOutlet UILabel *exposureTargetOffsetNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *exposureTargetOffsetValueLabel;

@property (nonatomic, strong) NSArray *whiteBalanceModes;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, weak) IBOutlet UIView *manualHUDWhiteBalanceView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *whiteBalanceModeControl;
@property (nonatomic, weak) IBOutlet UISlider *temperatureSlider;
@property (nonatomic, weak) IBOutlet UILabel *temperatureNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *temperatureValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *tintSlider;
@property (nonatomic, weak) IBOutlet UILabel *tintNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *tintValueLabel;

@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;


@property (nonatomic) AVCaptureSession *session;

@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer *previewLayer;


@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;


@end
@implementation AAPLCameraViewController

static UIColor* CONTROL_NORMAL_COLOR = nil;
static UIColor* CONTROL_HIGHLIGHT_COLOR = nil;
static float EXPOSURE_DURATION_POWER = 5; // Higher numbers will give the slider more sensitivity at shorter durations
static float EXPOSURE_MINIMUM_DURATION = 1.0/1000; // Limit exposure duration to a useful range
bool stop = true;
static NSMutableArray* chartData;
static NSMutableArray* chartDatagraytemp;

static NSMutableArray* chartDataSignal;
static NSMutableArray* chartDataReference;
static NSMutableArray* chartDataGray;


static NSMutableArray* mx;
static NSMutableArray* my;

static NSMutableArray* spectrumSignal;
static NSMutableArray* spectrumReference;


+ (void)initialize
{
	CONTROL_NORMAL_COLOR = [UIColor yellowColor];
	CONTROL_HIGHLIGHT_COLOR = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]; // A nice blue
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

- (BOOL)isSessionRunningAndDeviceAuthorized
{
	return [[self session] isRunning] && [self isDeviceAuthorized];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    int nViewWidth = self.view.frame.size.width;
    int nViewHeight = self.view.frame.size.height;
    ratio =1920/(float)nViewHeight;
    chartData=[[NSMutableArray alloc] init];
    for(int i=0; i<nLengthgray-1;i++){
        [chartData addObject:[NSString stringWithFormat:@"%d", 0]];
    }

    isSwiped = false;
    
    
    [[self cameraButton] setEnabled:YES];
	[[self recordButton] setEnabled:YES];
	[[self stillButton] setEnabled:YES];
    
    if (!_isSpectrum)
    {
        _cameraButton.hidden = YES;
        _recordButton.hidden = YES;
    }
    curLevel = 1.0f;
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
    [_previewView addGestureRecognizer:pinchGesture];
//   手势

    
//    if( [UIDevice currentDevice].systemVersion.floatValue >= 7.0 ){
//        if( [self.videoDevice respondsToSelector:@selector(videoMaxZoomFactor)] )
//        {
//            maxZoom = [self.videoDevice ];
//            NSLog(@"max zoom:%d",maxZoom);
//        }
//    }
    
    // (1) Create a user resizable view with a simple red background content view.
    // declare part for color detection (part2)
    CGRect redFrame = CGRectMake(0, 0, 150, 18);
    _lblRed = [[UILabel alloc] initWithFrame:redFrame];
    [self.view addSubview:_lblRed];
    [_lblRed setTextColor:[UIColor whiteColor]];
    [_lblRed setFont: [_lblRed.font fontWithSize: 12]];
  
    
    redFrame.origin.y += 25;
    _lblBlue = [[UILabel alloc] initWithFrame:redFrame];
    [self.view addSubview:_lblBlue];
    [_lblBlue setTextColor:[UIColor whiteColor]];
    [_lblBlue setFont: [_lblBlue.font fontWithSize: 12]];

    redFrame.origin.y += 25;
    _lblGreen = [[UILabel alloc] initWithFrame:redFrame];
    [self.view addSubview:_lblGreen];
    [_lblGreen setTextColor:[UIColor whiteColor]];
    [_lblGreen setFont: [_lblGreen.font fontWithSize: 12]];
    
    redFrame.origin.y += 25;
    _lblSum = [[UILabel alloc] initWithFrame:redFrame];
    [self.view addSubview:_lblSum];
    [_lblSum setTextColor:[UIColor whiteColor]];
    [_lblSum setFont: [_lblSum.font fontWithSize: 12]];

    
    CGRect redFrame2 = CGRectMake(0, 200, 150, 18);
    _lblRed2 = [[UILabel alloc] initWithFrame:redFrame2];
    [self.view addSubview:_lblRed2];
    [_lblRed2 setTextColor:[UIColor whiteColor]];
    [_lblRed2 setFont: [_lblRed2.font fontWithSize: 12]];
    
    
    redFrame2.origin.y += 25;
    _lblBlue2 = [[UILabel alloc] initWithFrame:redFrame2];
    [self.view addSubview:_lblBlue2];
    [_lblBlue2 setTextColor:[UIColor whiteColor]];
    [_lblBlue2 setFont: [_lblBlue2.font fontWithSize: 12]];
    
    redFrame2.origin.y += 25;
    _lblGreen2 = [[UILabel alloc] initWithFrame:redFrame2];
    [self.view addSubview:_lblGreen2];
    [_lblGreen2 setTextColor:[UIColor whiteColor]];
    [_lblGreen2 setFont: [_lblGreen2.font fontWithSize: 12]];
    
    redFrame2.origin.y += 25;
    _lblSum2 = [[UILabel alloc] initWithFrame:redFrame2];
    [self.view addSubview:_lblSum2];
    [_lblSum2 setTextColor:[UIColor whiteColor]];
    [_lblSum2 setFont: [_lblSum2.font fontWithSize: 12]];
    
    CGRect gripFrame = CGRectMake(50, 50, 200, 150);
    SPUserResizableView *userResizableView = [[SPUserResizableView alloc] initWithFrame:gripFrame];
    UIView *contentView = [[UIView alloc] initWithFrame:gripFrame];
    [contentView setBackgroundColor:[UIColor clearColor]];
    userResizableView.contentView = contentView;
    userResizableView.delegate = self;
    [userResizableView showEditingHandles];
    rview = userResizableView;
    [self.view addSubview:userResizableView];
    
    CGRect gripFrame2 = CGRectMake(50, 300, 200, 150);
    SPUserResizableView *userResizableView2 = [[SPUserResizableView alloc] initWithFrame:gripFrame2];
    UIView *contentView2 = [[UIView alloc] initWithFrame:gripFrame2];
    [contentView2 setBackgroundColor:[UIColor clearColor]];
    userResizableView2.contentView = contentView2;
    userResizableView2.delegate = self;
    [userResizableView2 showEditingHandles];
    rview2 = userResizableView2;
    [self.view addSubview:userResizableView2];
    rview.hidden = YES;
    rview2.hidden = YES;
    
    [_recordButton setEnabled:NO];
    [_cameraButton setEnabled:NO];
    _recordButton.userInteractionEnabled = NO;
    _cameraButton.userInteractionEnabled = NO;
    
    mx =[NSMutableArray arrayWithCapacity:2000];
    my =[NSMutableArray arrayWithCapacity:2000];
    
    // 1920*1080 <2000
    
    [self navigationController].navigationBarHidden = true;
    toppointX = 540;
    toppointY = 0;
    bottompointX = 540;
    bottompointY = 1700;
    startX = 540;
    endX = 540;
    startY = 0;
    endY = 1700;

    float deltaX = (endX - startX) / 200;
    float deltaY = (endY - startY) / 200;
    
    for (int ni = 0; ni < 200; ni++)
    {
        int nX = startX + deltaX * (float)ni;
        int nY = startY + deltaY * (float)ni;
        
        mx[ni] = [NSNumber numberWithInt:nX];
        my[ni] = [NSNumber numberWithInt:nY];
        
    }
    
    /// yilun+
    _lineChart = nil;

    //_m_chartData = [NSMutableArray arrayWithCapacity:0];
    

    /// +

	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.recordButton.layer.cornerRadius = self.stillButton.layer.cornerRadius = self.cameraButton.layer.cornerRadius = 4;
	self.recordButton.clipsToBounds = self.stillButton.clipsToBounds = self.cameraButton.clipsToBounds = YES;
	
//	// Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	[self setSession:session];

//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//	    [session setSessionPreset:AVCaptureSessionPreset640x480];
//	else
//	    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    session.sessionPreset = AVCaptureSessionPresetHigh;
//
//	
//	// Set up preview
	[[self previewView] setSession:_session];
	
	// Check for device authorization
	[self checkDeviceAuthorizationStatus];
//
//	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
//	// Why not do all of this on the main queue?
//	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
//	
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];

	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [AAPLCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		[[self session] beginConfiguration];
		
		if ([_session canAddInput:videoDeviceInput])
		{
			[_session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
			[self setVideoDevice:videoDeviceInput.device];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				// Why are we dispatching this to the main queue?
				// Because AVCaptureVideoPreviewLayer is the backing layer for our preview view and UIView can only be manipulated on main thread.
				// Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
  
				[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
			});
		}
        /*
		AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
		AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([_session canAddInput:audioDeviceInput])
		{
			[_session addInput:audioDeviceInput];
		}
         */
		
//		AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
//		if ([_session canAddOutput:movieFileOutput])
//		{
//			[_session addOutput:movieFileOutput];
//			AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//			if ([connection isVideoStabilizationSupported])
//			{
//				[connection setEnablesVideoStabilizationWhenAvailable:YES];
//			}
//			[self setMovieFileOutput:movieFileOutput];
//		}
		
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([_session canAddOutput:stillImageOutput])
		{
            [stillImageOutput setOutputSettings:@{AVVideoCodecKey: AVVideoCodecJPEG}];
			[_session addOutput:stillImageOutput];
			[self setStillImageOutput:stillImageOutput];
		}
        
        /// yilun+
      
        // Make a video data output
        _videoDataOutput = [AVCaptureVideoDataOutput new];
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'It's constant indicating pixel format of image buffer.
          NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];// 4*8
        [_videoDataOutput setVideoSettings:rgbOutputSettings];
        [_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
        
        // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        _videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
        
        if ( [_session canAddOutput:_videoDataOutput] )
            [_session addOutput:_videoDataOutput];
        //[[_videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        ///+
       
       
		[[self session] commitConfiguration];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self configureManualHUD];
		});
	});
//
	self.manualHUDFocusView.hidden = YES;
	self.manualHUDExposureView.hidden = YES;
	self.manualHUDWhiteBalanceView.hidden = YES;
    

}

- (void)pinchAction:(UIPinchGestureRecognizer *)pinchGesture {
    
    if (self.videoDevice.activeFormat.videoMaxZoomFactor == 1.0) {
        return;
    }
    
    static CGFloat lastPinchScale = 1.0;
    if (pinchGesture.scale == lastPinchScale) {
        return;
    }
    
    CGFloat scale = pinchGesture.scale > lastPinchScale ? pinchGesture.scale : -pinchGesture.scale;
    CGFloat zoomFactor = self.videoDevice.videoZoomFactor + scale;
    zoomFactor = zoomFactor <= 1.0 ? 1.0 : zoomFactor;
    zoomFactor = zoomFactor > self.videoDevice.activeFormat.videoMaxZoomFactor ? self.videoDevice.activeFormat.videoMaxZoomFactor : zoomFactor;
    [self.videoDevice lockForConfiguration:nil];
    [self.videoDevice rampToVideoZoomFactor:zoomFactor withRate:pinchGesture.velocity * 10];
    [self.videoDevice unlockForConfiguration];
    
    lastPinchScale = pinchGesture.scale;
}



/// yilun+

- (void)showGraph
{

     if (_isSpectrum)
     {
//         _viewColors.hidden = YES;
         _lblBlue.hidden = YES;
         _lblRed.hidden = YES;
         _lblGreen.hidden = YES;
         _lblSum.hidden = YES;
         
         _lblBlue2.hidden = YES;
         _lblRed2.hidden = YES;
         _lblGreen2.hidden = YES;
         _lblSum2.hidden = YES;

         if (_lineChart != nil)
         {
             [_lineChart removeFromSuperview];
             _lineChart = nil;
         }
         
         //    if (!_isSpectrum)
         //        return;
         
         
         if (isEditingPoint)
         {
             return;
         }
         _lineChart = [[FSLineChart alloc] initWithFrame:CGRectMake(25, 375, [UIScreen mainScreen].bounds.size.width - 50, [UIScreen mainScreen].bounds.size.height - 430)];
         
         _lineChart.gridStep = 4;
         _lineChart.color = [UIColor fsOrange];
         
         _lineChart.labelForIndex = ^(NSUInteger item) {
             return [NSString stringWithFormat:@"%lu",(unsigned long)item];
         };
         
         _lineChart.labelForValue = ^(CGFloat value) {
             return [NSString stringWithFormat:@"%.f", value];
         };
         
         _m_chartData = chartData;
         
         [_lineChart setChartData:_m_chartData];
         [self.view addSubview:_lineChart];
         // _lineChart.tag = 1;

     }
    else
    {
        if (isEditingPoint)
        {
//          [_viewColors removeFromSuperview];
            CGRect frameRView = rview.frame;
            CGRect frameRed = _lblRed.frame;
            frameRed.origin.y = frameRView.origin.y + frameRView.size.height + 5;
            frameRed.origin.x = frameRView.origin.x + 5;
            _lblRed.frame = frameRed;
            
            frameRed.origin.y += 25;
            _lblGreen.frame = frameRed;
            
            frameRed.origin.y += 25;
            _lblBlue.frame = frameRed;
            
            frameRed.origin.y += 25;
            _lblSum.frame = frameRed;
            
            _viewColors.hidden = NO;
            _lblBlue.hidden = NO;
            _lblRed.hidden = NO;
            _lblGreen.hidden = NO;
            _lblSum.hidden = NO;
            
            [_lblRed setText:[NSString stringWithFormat:@"Red: %d", sumB]];

            [_lblGreen setText:[NSString stringWithFormat:@"Green: %d", sumG]];
         
            [_lblBlue setText:[NSString stringWithFormat:@"Blue: %d", sumR]];

            [_lblSum setText:[NSString stringWithFormat:@"R + G + B: %d",(sumB + sumG + sumR)]];
            
            CGRect frameRView2 = rview2.frame;
            CGRect frameRed2 = _lblRed2.frame;
            frameRed2.origin.y = frameRView2.origin.y + frameRView2.size.height + 5;
            frameRed2.origin.x = frameRView2.origin.x + 5;
            _lblRed2.frame = frameRed2;
            
            frameRed2.origin.y += 25;
            _lblGreen2.frame = frameRed2;
            
            frameRed2.origin.y += 25;
            _lblBlue2.frame = frameRed2;
            
            frameRed2.origin.y += 25;
            _lblSum2.frame = frameRed2;
            
            _viewColors2.hidden = NO;
            _lblBlue2.hidden = NO;
            _lblRed2.hidden = NO;
            _lblGreen2.hidden = NO;
            _lblSum2.hidden = NO;
            
            [_lblRed2 setText:[NSString stringWithFormat:@"Red: %d",sumB2]];
            
            [_lblGreen2 setText:[NSString stringWithFormat:@"Green: %d", sumG2]];
            
            [_lblBlue2 setText:[NSString stringWithFormat:@"Blue: %d",sumR2]];
            
            [_lblSum2 setText:[NSString stringWithFormat:@"R + G + B: %d", (sumB2 + sumG2 + sumR2)]];
// part 2 R+G+B
            
            
        }
        else
        {
//            _viewColors.hidden = YES;
            _lblBlue.hidden = YES;
            _lblRed.hidden = YES;
            _lblGreen.hidden = YES;
            _lblSum.hidden = YES;
            _lblBlue2.hidden = YES;
            _lblRed2.hidden = YES;
            _lblGreen2.hidden = YES;
            _lblSum2.hidden = YES;

            
        }
    }

}


- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    
    NSLog(@"imageFromSampleBuffer: called");
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    UIImage* image = [self imageFromSampleBuffer:sampleBuffer];
    self.m_image = image;
    CGImageRef imageRef = image.CGImage;
    NSData *data        = (NSData *)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(imageRef)));
    char *pixels        = (char *)[data bytes];
    //get image data in realtime from camera
    
    m_nImageWidth = image.size.height;
    m_nImageHeight = image.size.width;
    
    // is swiped to right in image analysing mode.
    if (!_isSpectrum)
    {
//        int nViewWidth = self.view.frame.size.width;
//        int nViewHeight = self.view.frame.size.height;
//        float ratio =(float)m_nImageHeight/(float)nViewHeight;
        
        int sumR_tmp = 0;
        int sumG_tmp = 0;
        int sumB_tmp = 0;
        
        int nsx = rview.frame.origin.x * ratio;
        int nsy = rview.frame.origin.y * ratio;
        
        int nex = rview.frame.origin.x * ratio + rview.frame.size.width * ratio;
        int ney = rview.frame.origin.y * ratio + rview.frame.size.height * ratio;
        
        for (int ni=nsx; ni<nex; ni++){
            for (int nj=nsy; nj<ney; nj++)
            {
                int pixelInfo = ((image.size.width  * (image.size.height-ni)) + nj) * 4;
                //  int pixelInfo = (( image.size.width  * nY) + nX ) * 4;
                int realR = (pixels[pixelInfo] + 256) % 256;
                int realG = (pixels[pixelInfo+1] + 256) % 256;
                int realB = (pixels[pixelInfo+2] + 256) % 256;
                
                sumR_tmp += realR;
                sumG_tmp += realG;
                sumB_tmp += realB;

            }
        }
        sumR = sumR_tmp / ((nex-nsx)*(ney-nsy));
        sumG = sumG_tmp / ((nex-nsx)*(ney-nsy));
        sumB = sumB_tmp / ((nex-nsx)*(ney-nsy));
        
        int sumR2_tmp = 0;
        int sumG2_tmp = 0;
        int sumB2_tmp = 0;
        
        int nsx2 = rview2.frame.origin.x * ratio;
        int nsy2 = rview2.frame.origin.y * ratio;
        
        int nex2 = rview2.frame.origin.x * ratio + rview2.frame.size.width * ratio;
        int ney2 = rview2.frame.origin.y * ratio + rview2.frame.size.height * ratio;
        
        for (int ni=nsx2; ni<nex2; ni++){
            for (int nj=nsy2; nj<ney2; nj++)
            {
                int pixelInfo2 = ((image.size.width  * (image.size.height-ni)) + nj) * 4;
                //  int pixelInfo = (( image.size.width  * nY) + nX ) * 4;
                
                int realR2 = (pixels[pixelInfo2] + 256) % 256;
                int realG2 = (pixels[pixelInfo2+1] + 256) % 256;
                int realB2 = (pixels[pixelInfo2+2] + 256) % 256;
                
                sumR2_tmp += realR2;
                sumG2_tmp += realG2;
                sumB2_tmp += realB2;
                
            }
        }
        sumR2 = sumR2_tmp / ((nex2-nsx2)*(ney2-nsy2));
        sumG2 = sumG2_tmp / ((nex2-nsx2)*(ney2-nsy2));
        sumB2 = sumB2_tmp / ((nex2-nsx2)*(ney2-nsy2));

    }
    else
    {
        [chartData removeAllObjects];
        int nChartgray = 0;
//        int nViewWidth = self.view.frame.size.width;
//        int nViewHeight = self.view.frame.size.height;
//        float ratio =(float)m_nImageHeight/(float)nViewHeight;
        
        int startpoint_x_value = startX/ratio ;
        int startpoint_y_value = startY/ratio;
        int endpoint_x_value = endX/ratio;
        int endpoint_y_value = endY/ratio;
        
        int deltax = endpoint_x_value-startpoint_x_value;
        int deltay = endpoint_y_value-startpoint_y_value;
        int tempgray=0;
        //chartData =[NSMutableArray arrayWithCapacity:nLength + 5];
        int dy = startpoint_y_value-(int)(toppointY/ratio);
        for(int i=0;i<dy;i++){
            [chartData addObject:[NSString stringWithFormat:@"%d", 0]];
            //nChartgray++;
        }
        int peakvaluetemp = 0;
        int peakpoint_x_value_temp =dy;
        for (int ni = startpoint_y_value; ni < endpoint_y_value; ni++)
        {
            int nX = startpoint_x_value * ratio;
            int nY = ni * ratio;
            int pixelInfo = ((image.size.width  * (image.size.height-nX)) + nY) * 4;
            //  int pixelInfo = (( image.size.width  * nY) + nX ) * 4;
            int realR = (pixels[pixelInfo] + 256) % 256;
            int realG = (pixels[pixelInfo+1] + 256) % 256;
            int realB = (pixels[pixelInfo+2] + 256) % 256;
            int sum = realR + realG +realB;
//            chartData[nChartgray] = [NSNumber numberWithFloat: (float)(realR + realG + realB)];
            [chartData addObject:[NSString stringWithFormat:@"%d", sum]];

            if(sum > peakvaluetemp){
                peakvaluetemp = sum;
                //peakvaluetemp = chartDatagraytemp[nChartgray];
                peakpoint_x_value_temp = ni;
            }
            
            //nChartgray++;
        }
        peakpoint_x_value = peakpoint_x_value_temp;
        peakvalue = peakvaluetemp;
        int t=(int)(bottompointY/ratio)+1;
        for(int i=endpoint_y_value;i<t;i++){
            [chartData addObject:[NSString stringWithFormat:@"%d", 0]];
            //nChartgray++;
        }

        if(isEditingPoint){
            chartDatagraytemp = chartData;
            
        }
        
 
    }
}
///+


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
     peakvalue=0;
     peakpoint_x_value=0;
     distanceofcursors=0;
    [chartData removeAllObjects];
    [chartDataGray removeAllObjects];
    [chartDatagraytemp removeAllObjects];
    [chartDataReference removeAllObjects];
    [chartDataSignal removeAllObjects];
    
    isEditingPoint = false;
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(showGraph) userInfo:nil repeats:YES];

    _bt_drag1.hidden = YES;
    _bt_drag2.hidden = YES;
    
	dispatch_async([self sessionQueue], ^{
		[self addObservers];

		[[self session] startRunning];
	});
}

- (void)viewDidDisappear:(BOOL)animated
{
	dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];
		
	//	[self removeObservers];
	});
	
	[super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (BOOL)shouldAutorotate
{
	// Disable autorotation of the interface when recording is in progress.
	return ![self lockInterfaceRotation];
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self positionManualHUD];
}

#pragma mark Actions
- (IBAction)toggleMovieRecording:(id)sender // when click save button
{
  
    chartDataSignal = [[NSMutableArray alloc] init];
    [chartDataSignal addObjectsFromArray:chartData];
    chartDataGray = [[NSMutableArray alloc] init];
    [chartDataGray addObjectsFromArray:chartDatagraytemp];
   
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    isEditingPoint = false;
    [self showGraph];
    isEditingPoint = true;
}


- (IBAction)changeCamera:(id)sender//when click save reference button
{
    chartDataReference = [[NSMutableArray alloc] init];
    [chartDataReference addObjectsFromArray:chartData];
    
  

    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    isEditingPoint = false;
    [self showGraph];
    isEditingPoint = true;
}



int selectedAVCaptureDeviceFormatIdx = 22;
- (IBAction)snapStillImage:(id)sender  //when click ROI button
{
    
    if (isEditingPoint)
    {
        int nViewWidth = self.view.frame.size.width;
        int nViewHeight = self.view.frame.size.height;

        if (_isSpectrum)
        {
            startX = (_bt_drag1.frame.origin.x + 15) * m_nImageWidth / nViewWidth;
            startY = (_bt_drag1.frame.origin.y + 15) * m_nImageHeight / nViewHeight;
            
            endX = (_bt_drag2.frame.origin.x + 15) * m_nImageWidth / nViewWidth;
            endY = (_bt_drag2.frame.origin.y + 15) * m_nImageHeight / nViewHeight;
            
            float x1 = _bt_drag2.frame.origin.x - _bt_drag1.frame.origin.x;
            float y1 = _bt_drag2.frame.origin.y - _bt_drag1.frame.origin.y;
            nLength = sqrt(x1*x1 + y1*y1);

            [_bt_drag1 removeFromSuperview];
            [_bt_drag2 removeFromSuperview];
            
            float deltaX = (endX - startX) / nLength;
            float deltaY = (endY - startY) / nLength;
            
            for (int ni = 0; ni < nLength; ni++)
            {
                int nX = startX + deltaX * (float)ni;
                int nY = startY + deltaY * (float)ni;
                
                mx[ni] = [NSNumber numberWithInt:nX];
                my[ni] = [NSNumber numberWithInt:nY];
                
            }

        }
        else
        {
            rview.hidden = YES;
            rview2.hidden = YES;
        }
  
        [_recordButton setEnabled:NO];
        [_cameraButton setEnabled:NO];
        _recordButton.userInteractionEnabled = NO;
        _cameraButton.userInteractionEnabled = NO;
        
        isEditingPoint = false;
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(showGraph) userInfo:nil repeats:YES];
    }
    else
    {
        [_recordButton setEnabled:YES];
        [_cameraButton setEnabled:YES];
        _recordButton.userInteractionEnabled = YES;
        _cameraButton.userInteractionEnabled = YES;
        isEditingPoint = true;
        int nViewWidth = self.view.frame.size.width;
        int nViewHeight = self.view.frame.size.height;
        
        if (_isSpectrum)
        {
            nLengthgray = (int)(bottompointY - toppointY)*nViewHeight/m_nImageHeight;
            int x1 = (int)((float)startX / m_nImageWidth * nViewWidth);
            int x2 = (int)((float)endX / m_nImageWidth * nViewWidth);
            int y1 = (int)((float)startY / m_nImageHeight * nViewHeight);
            int y2 = (int)((float)endY / m_nImageHeight * nViewHeight);
            
            [_bt_drag1 removeFromSuperview];
            [_bt_drag2 removeFromSuperview];
            
            _bt_drag1 = [[DragButton alloc] initWithFrame:CGRectMake(x1 - 14, y1 - 14, 100, 30)];
            _bt_drag2 = [[DragButton alloc] initWithFrame:CGRectMake(x2 - 14, y2 - 14, 100, 30)];
            
            [_bt_drag1 setFrame:CGRectMake(x1 - 14, y1 - 14, 100, 30)];
            //Test1 -- set image
            [_bt_drag1 setImage:[UIImage imageNamed:@"thick_cross.png"] forState:UIControlStateNormal];
            [self.view addSubview:_bt_drag1];
            
            [_bt_drag2 setFrame:CGRectMake(x2 - 14, y2 - 14, 100, 30)];
            //Test1 -- set image
            [_bt_drag2 setImage:[UIImage imageNamed:@"thick_cross.png"] forState:UIControlStateNormal];
            [self.view addSubview:_bt_drag2];
        }
        else
        {
            rview.hidden = NO;
            rview2.hidden = NO;
        }
    }
}



- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
	if (self.videoDevice.focusMode != AVCaptureFocusModeLocked && self.videoDevice.exposureMode != AVCaptureExposureModeCustom)
	{
		CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
		[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
	}
}

- (IBAction)swipeDetect:(UIGestureRecognizer *)gestureRecognizer
{
    if (isEditingPoint)
    {
        if (!_isSpectrum)
        {
//            isSwiped = true;
        }
        else
        {
            [[self session] stopRunning];

            [self performSegueWithIdentifier:@"preview_sec"
                                      sender:self];
        }

    }
    return ;
}


- (IBAction)swipeRight:(UIGestureRecognizer *)gestureRecognizer
{
    [[self session] stopRunning];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender// at this function this value will be saved
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([[segue identifier] isEqualToString:@"preview_sec"]) {
        int nViewWidth = self.previewView.frame.size.width;
        SecondViewController* svc = (SecondViewController*)[segue destinationViewController];
        svc.m_chartData_ref = chartDataReference;
        svc.m_chartData_sig = chartDataSignal;
        svc.m_chartData_gray =chartDataGray;
        
        svc.m_X = mx;
        svc.m_Y = my;
        svc.mstartX = toppointX;
        svc.mstartY = toppointY;
        svc.mendX = bottompointX;
        svc.mendY = bottompointY;
        svc.mlength = nLengthgray;
      
        
        svc.startcursor_x =(_bt_drag1.frame.origin.x + 15);
        svc.startcursor_y=(_bt_drag1.frame.origin.y + 15);
        svc.endcursor_x =(_bt_drag2.frame.origin.x + 15);
        svc.endcursor_y =(_bt_drag2.frame.origin.y + 15);
        NSLog(@"%d",svc.startcursor_x);
        NSLog(@"%d",svc.startcursor_y);
        NSLog(@"%d",svc.endcursor_x);
        NSLog(@"%d",svc.endcursor_y);

        
        
        
       // svc.startcursor_x =startX;
        //svc.startcursor_y =startY;
       // svc.endcursor_x =endX;
        //svc.endcursor_y =endY;
       //svc.xxxxx = nLength;
    }
}


- (IBAction)changeManualHUD:(id)sender
{
	UISegmentedControl *control = sender;
	
	[self positionManualHUD];
	
	self.manualHUDFocusView.hidden = (control.selectedSegmentIndex == 1) ? NO : YES;
	self.manualHUDExposureView.hidden = (control.selectedSegmentIndex == 2) ? NO : YES;
	self.manualHUDWhiteBalanceView.hidden = (control.selectedSegmentIndex == 3) ? NO : YES;
}

- (IBAction)changeFocusMode:(id)sender
{
	UISegmentedControl *control = sender;
	AVCaptureFocusMode mode = (AVCaptureFocusMode)[self.focusModes[control.selectedSegmentIndex] intValue];
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		if ([self.videoDevice isFocusModeSupported:mode])
		{
			self.videoDevice.focusMode = mode;
		}
		else
		{
			NSLog(@"Focus mode %@ is not supported. Focus mode is %@.", [self stringFromFocusMode:mode], [self stringFromFocusMode:self.videoDevice.focusMode]);
			self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(self.videoDevice.focusMode)];
		}
	}
	else
	{
		NSLog(@"%@", error);
	}
}
- (IBAction)changeExposureMode:(id)sender
{
	UISegmentedControl *control = sender;
	NSError *error = nil;
	AVCaptureExposureMode mode = (AVCaptureExposureMode)[self.exposureModes[control.selectedSegmentIndex] intValue];
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		if ([self.videoDevice isExposureModeSupported:mode])
		{
			self.videoDevice.exposureMode = mode;
		}
		else
		{
			NSLog(@"Exposure mode %@ is not supported. Exposure mode is %@.", [self stringFromExposureMode:mode], [self stringFromExposureMode:self.videoDevice.exposureMode]);
		}
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeWhiteBalanceMode:(id)sender
{
	UISegmentedControl *control = sender;
	AVCaptureWhiteBalanceMode mode = (AVCaptureWhiteBalanceMode)[self.whiteBalanceModes[control.selectedSegmentIndex] intValue];
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		if ([self.videoDevice isWhiteBalanceModeSupported:mode])
		{
			self.videoDevice.whiteBalanceMode = mode;
		}
		else
		{
			NSLog(@"White balance mode %@ is not supported. White balance mode is %@.", [self stringFromWhiteBalanceMode:mode], [self stringFromWhiteBalanceMode:self.videoDevice.whiteBalanceMode]);
		}
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeLensPosition:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		[self.videoDevice setFocusModeLockedWithLensPosition:control.value completionHandler:nil];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeExposureDuration:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	double p = pow( control.value, EXPOSURE_DURATION_POWER ); // Apply power function to expand slider's low-end range
	double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
	double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
	double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
	
	if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom)
	{
		if ( newDurationSeconds < 1 )
		{
			int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
			self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"1/%.*f", digits, 1/newDurationSeconds];
		}
		else
		{
			self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"%.2f", newDurationSeconds];
		}
	}

	if ([self.videoDevice lockForConfiguration:&error])
	{
		[self.videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(newDurationSeconds, 1000*1000*1000)  ISO:AVCaptureISOCurrent completionHandler:nil];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeISO:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		[self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:control.value completionHandler:nil];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeExposureTargetBias:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		[self.videoDevice setExposureTargetBias:control.value completionHandler:nil];
		self.exposureTargetBiasValueLabel.text = [NSString stringWithFormat:@"%.1f", control.value];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeTemperature:(id)sender
{
	AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
		.temperature = self.temperatureSlider.value,
		.tint = self.tintSlider.value,
	};
	
	[self setWhiteBalanceGains:[self.videoDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint]];
}

- (IBAction)changeTint:(id)sender
{
	AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
		.temperature = self.temperatureSlider.value,
		.tint = self.tintSlider.value,
	};
	
	[self setWhiteBalanceGains:[self.videoDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint]];
}

- (IBAction)lockWithGrayWorld:(id)sender
{
	[self setWhiteBalanceGains:self.videoDevice.grayWorldDeviceWhiteBalanceGains];
}

- (IBAction)sliderTouchBegan:(id)sender
{
	UISlider *slider = (UISlider*)sender;
	[self setSlider:slider highlightColor:CONTROL_HIGHLIGHT_COLOR];
}

- (IBAction)sliderTouchEnded:(id)sender
{
	UISlider *slider = (UISlider*)sender;
	[self setSlider:slider highlightColor:CONTROL_NORMAL_COLOR];
}

#pragma mark UI

- (void)runStillImageCaptureAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[[self previewView] layer] setOpacity:0.0];
		[UIView animateWithDuration:.25 animations:^{
			[[[self previewView] layer] setOpacity:1.0];
		}];
	});
}

- (void)configureManualHUD
{
	// Manual focus controls
	self.focusModes = @[@(AVCaptureFocusModeContinuousAutoFocus), @(AVCaptureFocusModeLocked)];
	
	self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(self.videoDevice.focusMode)];
	for (NSNumber *mode in self.focusModes) {
		[self.focusModeControl setEnabled:([self.videoDevice isFocusModeSupported:[mode intValue]]) forSegmentAtIndex:[self.focusModes indexOfObject:mode]];
	}
	
	self.lensPositionSlider.minimumValue = 0.0;
	self.lensPositionSlider.maximumValue = 1.0;
	self.lensPositionSlider.enabled = (self.videoDevice.focusMode == AVCaptureFocusModeLocked);
	
	// Manual exposure controls
	self.exposureModes = @[@(AVCaptureExposureModeContinuousAutoExposure), @(AVCaptureExposureModeLocked), @(AVCaptureExposureModeCustom)];
	
	self.exposureModeControl.selectedSegmentIndex = [self.exposureModes indexOfObject:@(self.videoDevice.exposureMode)];
	for (NSNumber *mode in self.exposureModes) {
		[self.exposureModeControl setEnabled:([self.videoDevice isExposureModeSupported:[mode intValue]]) forSegmentAtIndex:[self.exposureModes indexOfObject:mode]];
	}
	
	// Use 0-1 as the slider range and do a non-linear mapping from the slider value to the actual device exposure duration
	self.exposureDurationSlider.minimumValue = 0;
	self.exposureDurationSlider.maximumValue = 1;
	self.exposureDurationSlider.enabled = (self.videoDevice.exposureMode == AVCaptureExposureModeCustom);
	
	self.ISOSlider.minimumValue = self.videoDevice.activeFormat.minISO;
	self.ISOSlider.maximumValue = self.videoDevice.activeFormat.maxISO;
	self.ISOSlider.enabled = (self.videoDevice.exposureMode == AVCaptureExposureModeCustom);
	
	self.exposureTargetBiasSlider.minimumValue = self.videoDevice.minExposureTargetBias;
	self.exposureTargetBiasSlider.maximumValue = self.videoDevice.maxExposureTargetBias;
	self.exposureTargetBiasSlider.enabled = YES;
	
	self.exposureTargetOffsetSlider.minimumValue = self.videoDevice.minExposureTargetBias;
	self.exposureTargetOffsetSlider.maximumValue = self.videoDevice.maxExposureTargetBias;
	self.exposureTargetOffsetSlider.enabled = NO;
	
	// Manual white balance controls
	self.whiteBalanceModes = @[@(AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance), @(AVCaptureWhiteBalanceModeLocked)];
	
	self.whiteBalanceModeControl.selectedSegmentIndex = [self.whiteBalanceModes indexOfObject:@(self.videoDevice.whiteBalanceMode)];
	for (NSNumber *mode in self.whiteBalanceModes) {
		[self.whiteBalanceModeControl setEnabled:([self.videoDevice isWhiteBalanceModeSupported:[mode intValue]]) forSegmentAtIndex:[self.whiteBalanceModes indexOfObject:mode]];
	}
	
	self.temperatureSlider.minimumValue = 3000;
	self.temperatureSlider.maximumValue = 8000;
	self.temperatureSlider.enabled = (self.videoDevice.whiteBalanceMode == AVCaptureWhiteBalanceModeLocked);
	
	self.tintSlider.minimumValue = -150;
	self.tintSlider.maximumValue = 150;
	self.tintSlider.enabled = (self.videoDevice.whiteBalanceMode == AVCaptureWhiteBalanceModeLocked);
}

- (void)positionManualHUD
{
	// Since we only show one manual view at a time, put them all in the same place (at the top)
	self.manualHUDExposureView.frame = CGRectMake(self.manualHUDFocusView.frame.origin.x, self.manualHUDFocusView.frame.origin.y, self.manualHUDExposureView.frame.size.width, self.manualHUDExposureView.frame.size.height);
	self.manualHUDWhiteBalanceView.frame = CGRectMake(self.manualHUDFocusView.frame.origin.x, self.manualHUDFocusView.frame.origin.y, self.manualHUDWhiteBalanceView.frame.size.width, self.manualHUDWhiteBalanceView.frame.size.height);
}

- (void)setSlider:(UISlider*)slider highlightColor:(UIColor*)color
{
	slider.tintColor = color;
	
	if (slider == self.lensPositionSlider)
	{
		self.lensPositionNameLabel.textColor = self.lensPositionValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.exposureDurationSlider)
	{
		self.exposureDurationNameLabel.textColor = self.exposureDurationValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.ISOSlider)
	{
		self.ISONameLabel.textColor = self.ISOValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.exposureTargetBiasSlider)
	{
		self.exposureTargetBiasNameLabel.textColor = self.exposureTargetBiasValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.temperatureSlider)
	{
		self.temperatureNameLabel.textColor = self.temperatureValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.tintSlider)
	{
		self.tintNameLabel.textColor = self.tintValueLabel.textColor = slider.tintColor;
	}
}

#pragma mark File Output Delegate

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *device = [self videoDevice];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	});
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}

- (void)setWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains
{
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		AVCaptureWhiteBalanceGains normalizedGains = [self normalizedGains:gains]; // Conversion can yield out-of-bound values, cap to limits
		[self.videoDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:normalizedGains completionHandler:nil];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

#pragma mark KVO

- (void)addObservers
{
	[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
	[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
	[self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
	
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.focusMode" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:FocusModeContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.lensPosition" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:LensPositionContext];
	
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.exposureMode" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureModeContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.exposureDuration" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureDurationContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.ISO" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ISOContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.exposureTargetOffset" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureTargetOffsetContext];
	
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.whiteBalanceMode" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:WhiteBalanceModeContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.deviceWhiteBalanceGains" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:DeviceWhiteBalanceGainsContext];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[self videoDevice]];
	
	__weak AAPLCameraViewController *weakSelf = self;
	[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
		AAPLCameraViewController *strongSelf = weakSelf;
		dispatch_async([strongSelf sessionQueue], ^{
			// Manually restart the session since it must have been stopped due to an error
			[[strongSelf session] startRunning];
			[[strongSelf recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
		});
	}]];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == FocusModeContext)
	{
		AVCaptureFocusMode oldMode = [change[NSKeyValueChangeOldKey] intValue];
		AVCaptureFocusMode newMode = [change[NSKeyValueChangeNewKey] intValue];
		NSLog(@"focus mode: %@ -> %@", [self stringFromFocusMode:oldMode], [self stringFromFocusMode:newMode]);
		
		self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(newMode)];
		self.lensPositionSlider.enabled = (newMode == AVCaptureFocusModeLocked);
	}
	else if (context == LensPositionContext)
	{
		float newLensPosition = [change[NSKeyValueChangeNewKey] floatValue];
		
		if (self.videoDevice.focusMode != AVCaptureFocusModeLocked)
		{
			self.lensPositionSlider.value = newLensPosition;
		}
		self.lensPositionValueLabel.text = [NSString stringWithFormat:@"%.1f", newLensPosition];
	}
	else if (context == ExposureModeContext)
	{
		AVCaptureExposureMode oldMode = [change[NSKeyValueChangeOldKey] intValue];
		AVCaptureExposureMode newMode = [change[NSKeyValueChangeNewKey] intValue];
		NSLog(@"exposure mode: %@ -> %@", [self stringFromExposureMode:oldMode], [self stringFromExposureMode:newMode]);
		
		self.exposureModeControl.selectedSegmentIndex = [self.exposureModes indexOfObject:@(newMode)];
		self.exposureDurationSlider.enabled = (newMode == AVCaptureExposureModeCustom);
		self.ISOSlider.enabled = (newMode == AVCaptureExposureModeCustom);
	}
	else if (context == ExposureDurationContext)
	{
		double newDurationSeconds = CMTimeGetSeconds([change[NSKeyValueChangeNewKey] CMTimeValue]);
		if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom)
		{
			double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
			double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
			// Map from duration to non-linear UI range 0-1
			double p = ( newDurationSeconds - minDurationSeconds ) / ( maxDurationSeconds - minDurationSeconds ); // Scale to 0-1
			self.exposureDurationSlider.value = pow( p, 1 / EXPOSURE_DURATION_POWER ); // Apply inverse power
			
			if ( newDurationSeconds < 1 )
			{
				int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
				self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"1/%.*f", digits, 1/newDurationSeconds];
			}
			else
			{
				self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"%.2f", newDurationSeconds];
			}
		}
	}
	else if (context == ISOContext)
	{
		float newISO = [change[NSKeyValueChangeNewKey] floatValue];
		
		if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom)
		{
			self.ISOSlider.value = newISO;
		}
		self.ISOValueLabel.text = [NSString stringWithFormat:@"%i", (int)newISO];
	}
	else if (context == ExposureTargetOffsetContext)
	{
		float newExposureTargetOffset = [change[NSKeyValueChangeNewKey] floatValue];
		
		self.exposureTargetOffsetSlider.value = newExposureTargetOffset;
		self.exposureTargetOffsetValueLabel.text = [NSString stringWithFormat:@"%.1f", newExposureTargetOffset];
	}
	else if (context == WhiteBalanceModeContext)
	{
		AVCaptureWhiteBalanceMode oldMode = [change[NSKeyValueChangeOldKey] intValue];
		AVCaptureWhiteBalanceMode newMode = [change[NSKeyValueChangeNewKey] intValue];
		NSLog(@"white balance mode: %@ -> %@", [self stringFromWhiteBalanceMode:oldMode], [self stringFromWhiteBalanceMode:newMode]);
		
		self.whiteBalanceModeControl.selectedSegmentIndex = [self.whiteBalanceModes indexOfObject:@(newMode)];
		self.temperatureSlider.enabled = (newMode == AVCaptureWhiteBalanceModeLocked);
		self.tintSlider.enabled = (newMode == AVCaptureWhiteBalanceModeLocked);
	}
	else if (context == DeviceWhiteBalanceGainsContext)
	{
		AVCaptureWhiteBalanceGains newGains;
		[change[NSKeyValueChangeNewKey] getValue:&newGains];
		AVCaptureWhiteBalanceTemperatureAndTintValues newTemperatureAndTint = [self.videoDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:newGains];
		
		if (self.videoDevice.whiteBalanceMode != AVCaptureExposureModeLocked)
		{
			self.temperatureSlider.value = newTemperatureAndTint.temperature;
			self.tintSlider.value = newTemperatureAndTint.tint;
		}
		self.temperatureValueLabel.text = [NSString stringWithFormat:@"%i", (int)newTemperatureAndTint.temperature];
		self.tintValueLabel.text = [NSString stringWithFormat:@"%i", (int)newTemperatureAndTint.tint];
	}
	else if (context == CapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage)
		{
			[self runStillImageCaptureAnimation];
		}
	}
	else if (context == RecordingContext)
	{
		BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRecording)
			{
				[[self cameraButton] setEnabled:NO];
				[[self recordButton] setTitle:NSLocalizedString(@"Stop", @"Recording button stop title") forState:UIControlStateNormal];
				[[self recordButton] setEnabled:YES];
			}
			else
			{
				[[self cameraButton] setEnabled:YES];
				[[self recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
				[[self recordButton] setEnabled:YES];
			}
		});
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext)
	{
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRunning)
			{
				[[self cameraButton] setEnabled:YES];
				[[self recordButton] setEnabled:YES];
				[[self stillButton] setEnabled:YES];
			}
			else
			{
				[[self cameraButton] setEnabled:NO];
				[[self recordButton] setEnabled:NO];
				[[self stillButton] setEnabled:NO];
			}
		});
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark Utilities

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}

- (void)checkDeviceAuthorizationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted)
		{
			[self setDeviceAuthorized:YES];
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"AVCamManual"
											message:@"AVCamManual doesn't have permission to use the Camera"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				[self setDeviceAuthorized:NO];
			});
		}
	}];
}

- (NSString *)stringFromFocusMode:(AVCaptureFocusMode) focusMode
{
	NSString *string = @"INVALID FOCUS MODE";
	
	if (focusMode == AVCaptureFocusModeLocked)
	{
		string = @"Locked";
	}
	else if (focusMode == AVCaptureFocusModeAutoFocus)
	{
		string = @"Auto";
	}
	else if (focusMode == AVCaptureFocusModeContinuousAutoFocus)
	{
		string = @"ContinuousAuto";
	}
	
	return string;
}

- (NSString *)stringFromExposureMode:(AVCaptureExposureMode) exposureMode
{
	NSString *string = @"INVALID EXPOSURE MODE";
	
	if (exposureMode == AVCaptureExposureModeLocked)
	{
		string = @"Locked";
	}
	else if (exposureMode == AVCaptureExposureModeAutoExpose)
	{
		string = @"Auto";
	}
	else if (exposureMode == AVCaptureExposureModeContinuousAutoExposure)
	{
		string = @"ContinuousAuto";
	}
	else if (exposureMode == AVCaptureExposureModeCustom)
	{
		string = @"Custom";
	}
	
	return string;
}

- (NSString *)stringFromWhiteBalanceMode:(AVCaptureWhiteBalanceMode) whiteBalanceMode
{
	NSString *string = @"INVALID WHITE BALANCE MODE";
	
	if (whiteBalanceMode == AVCaptureWhiteBalanceModeLocked)
	{
		string = @"Locked";
	}
	else if (whiteBalanceMode == AVCaptureWhiteBalanceModeAutoWhiteBalance)
	{
		string = @"Auto";
	}
	else if (whiteBalanceMode == AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance)
	{
		string = @"ContinuousAuto";
	}
	
	return string;
}

- (AVCaptureWhiteBalanceGains)normalizedGains:(AVCaptureWhiteBalanceGains) gains
{
	AVCaptureWhiteBalanceGains g = gains;
	
	g.redGain = MAX(1.0, g.redGain);
	g.greenGain = MAX(1.0, g.greenGain);
	g.blueGain = MAX(1.0, g.blueGain);
	
	g.redGain = MIN(self.videoDevice.maxWhiteBalanceGain, g.redGain);
	g.greenGain = MIN(self.videoDevice.maxWhiteBalanceGain, g.greenGain);
	g.blueGain = MIN(self.videoDevice.maxWhiteBalanceGain, g.blueGain);
	
	return g;
}


- (void)userResizableViewDidBeginEditing:(SPUserResizableView *)userResizableView
{
    CGRect frameRView = rview.frame;
    CGRect frameRed = _lblRed.frame;
    frameRed.origin.y = frameRView.origin.y + frameRView.size.height + 5;
    frameRed.origin.x = frameRView.origin.x + 5;
    _lblRed.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblGreen.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblBlue.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblSum.frame = frameRed;
    
    CGRect frameRView2 = rview2.frame;
    CGRect frameRed2 = _lblRed2.frame;
    frameRed2.origin.y = frameRView2.origin.y + frameRView2.size.height + 5;
    frameRed2.origin.x = frameRView2.origin.x + 5;
    _lblRed2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblGreen2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblBlue2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblSum2.frame = frameRed2;
}


- (void)userResizableViewEditing:(SPUserResizableView *)userResizableView
{
    CGRect frameRView = rview.frame;
    CGRect frameRed = _lblRed.frame;
    frameRed.origin.y = frameRView.origin.y + frameRView.size.height + 5;
    frameRed.origin.x = frameRView.origin.x + 5;
    _lblRed.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblGreen.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblBlue.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblSum.frame = frameRed;
    
    CGRect frameRView2 = rview2.frame;
    CGRect frameRed2 = _lblRed2.frame;
    frameRed2.origin.y = frameRView2.origin.y + frameRView2.size.height + 5;
    frameRed2.origin.x = frameRView2.origin.x + 5;
    _lblRed2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblGreen2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblBlue2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblSum2.frame = frameRed2;
    
}

- (void)userResizableViewDidEndEditing:(SPUserResizableView *)userResizableView
{
    CGRect frameRView = rview.frame;
    CGRect frameRed = _lblRed.frame;
    frameRed.origin.y = frameRView.origin.y + frameRView.size.height + 5;
    frameRed.origin.x = frameRView.origin.x + 5;
    _lblRed.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblGreen.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblBlue.frame = frameRed;
    
    frameRed.origin.y += 25;
    _lblSum.frame = frameRed;
    
    CGRect frameRView2 = rview2.frame;
    CGRect frameRed2 = _lblRed2.frame;
    frameRed2.origin.y = frameRView2.origin.y + frameRView2.size.height + 5;
    frameRed2.origin.x = frameRView2.origin.x + 5;
    _lblRed2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblGreen2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblBlue2.frame = frameRed2;
    
    frameRed2.origin.y += 25;
    _lblSum2.frame = frameRed2;

 }


@end
