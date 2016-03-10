//
//  SecondViewController.m
//  avcammanual
//
//  Created by System Administrator on 2/26/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

#import "SecondViewController.h"
#import "FSLineChart.h"
#import "UIColor+FSPalette.h"
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import "AAPLPreviewView.h"
#import "AAPLCameraViewController.h"
@interface SecondViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate,AVCaptureFileOutputRecordingDelegate>
{
    bool isCameraMode;
    bool isPeakDrawingMode;
    int nCurPeakPointer;
    
    NSMutableArray* chartDatagraytemp;
}

    @property (nonatomic, strong) FSLineChart *chart_ref;
    @property (nonatomic, strong) FSLineChart *chart_sig;
    @property (nonatomic, strong) FSLineChart *chart_peak;
    @property (nonatomic, strong) FSLineChart *chart_gray;//jinbei
    @property (nonatomic, strong) FSLineChart *chart_graypeak;

    @property (nonatomic) bool isSignal;

    @property (nonatomic, weak) IBOutlet AAPLPreviewView *previewView;
    @property (nonatomic, weak) IBOutlet UIButton *btnShowHideCam;
    //@property (nonatomic, weak) IBOutlet UILabel *peakpoint;

    @property (nonatomic) AVCaptureSession *session;
    @property (nonatomic) dispatch_queue_t sessionQueue;
    @property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
    @property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
    @property (nonatomic) AVCaptureDevice *videoDevice;
    @property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
    @property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;

    @property (nonatomic) dispatch_queue_t videoDataOutputQueue;
    @property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;

    @property (nonatomic, strong) NSTimer *timer;
    @property (nonatomic, strong) NSTimer *timer_peak;
    @property (nonatomic, strong) NSTimer *timer_peakB;


@end

static NSMutableArray* chartData;
//static NSMutableArray* chartDatagraytemp

@implementation SecondViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    chartDatagraytemp =[[NSMutableArray alloc] init];
    self.total_t.text = @"60";
    for(int i=0; i<_mlength-1;i++){
        [chartDatagraytemp addObject:[NSString stringWithFormat:@"%d", 0]];
    }
    
     [self.delta_t setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
     [self.total_t setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
     [self refreshPeakData];
    
//  self.peaklabelview.frame = CGRectMake(peakpoint_x_value,peakvalue*self.viewA.frame.size.height/800+10,200,100);
    _chart_sig = nil;
    _chart_ref = nil;
    _chart_gray= nil;//jinbei
    _peakindex = 0;
     
    _dataPeak = [NSMutableArray arrayWithCapacity:60];
    _m_chartData_lam = [NSMutableArray arrayWithCapacity:_mlength + 2];
    
    _previewView.hidden = YES;
    _m_chartData_peak = [[NSMutableArray alloc] init];
    [self navigationController].navigationBarHidden = true;
    [self showGraph];
    _isSignal = false;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //	// Create the AVCaptureSession
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [self setSession:session];
    session.sessionPreset = AVCaptureSessionPresetHigh;
    [[self previewView] setSession:_session];
    // Check for device authorization
    [self checkDeviceAuthorizationStatus];
    //	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    //	// Why not do all of this on the main queue?
    //	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
    //
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [SecondViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
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
 
                [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
            });
        }
   
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
        
        [[self session] commitConfiguration];

    });

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goback:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)savetoEmail:(id)sender
{
    if (isPeakDrawingMode)
    {
        isPeakDrawingMode = false;
        _peakindex = 0;
        [[self session] stopRunning];
        [self.peak_StartButton setTitle:@"Start" forState:UIControlStateNormal];
        [_m_chartData_peak removeAllObjects];
        if (_timer_peakB) {
            [_timer_peakB invalidate];
            _timer_peakB = nil;
        }
    }
    NSArray *emailAry = [NSArray arrayWithObjects:@"jiyilunstm@outlook.com",nil];
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:@"Peak Data Report"];
    [controller setToRecipients:emailAry];
    NSString * str = @"This is Peakpoint data. \n\n";
    str = [NSString stringWithFormat:@"%@%@ \n peakvalue data \n\n",str, _dynamic_peakdata_xls];
    NSDateFormatter *formatter;
    NSString        *dateString;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm MMM dd,yyyy"];
    dateString = [formatter stringFromDate:[NSDate date]];
    NSData *myData = [str dataUsingEncoding:NSUTF8StringEncoding];
    [controller addAttachmentData:myData mimeType:@"text/csv" fileName:@"peakvalue.csv"];

    
    [controller setMessageBody:[NSString stringWithFormat:@"Peakpoint data report \n %@", dateString] isHTML:NO];
    if (controller) [self presentModalViewController:controller animated:YES];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)swipeDetect:(UIGestureRecognizer *)gestureRecognizer
{
    [[self session] stopRunning];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showGraph
{

    if (isCameraMode)
    {
        _m_chartData_sig = chartData;
        if (_chart_ref != nil)
        {
            [_chart_ref removeFromSuperview];
            _chart_ref = nil;
        }
        
        if (_chart_sig != nil)
        {
            [_chart_sig removeFromSuperview];
            _chart_sig = nil;
        }
    }

    
    _chart_sig = [[FSLineChart alloc] initWithFrame:CGRectMake(30, 5, [UIScreen mainScreen].bounds.size.width - 60, _viewC.frame.size.height - 10)];
    
    _chart_sig.gridStep = 4;
    _chart_sig.color = [UIColor fsOrange];
    
    _chart_sig.labelForIndex = ^(NSUInteger item) {
        if (_isSignal)
            return [NSString stringWithFormat:@"%lu",(unsigned long)item];
        else
            return @"";
    };
    
    _chart_sig.labelForValue = ^(CGFloat value) {
        if (_isSignal)
            return [NSString stringWithFormat:@"%.f", value];
        else
            return @"";
    };
    

    [_chart_sig setChartData:_m_chartData_sig];
    
    _chart_sig.color = [UIColor fsGreen];
    _isSignal = true;
    [_chart_sig setChartData:_m_chartData_ref];
    
    

    _isSignal = false;
    [_viewA addSubview:_chart_sig];
 
    //adding gray chart line  //jinbei
    _chart_gray = [[FSLineChart alloc] initWithFrame:CGRectMake(30, 5, [UIScreen mainScreen].bounds.size.width - 60, _viewA.frame.size.height - 10)];
    _chart_gray.gridStep = 4;
    _chart_gray.color = [UIColor redColor];
    [_chart_gray setChartData:_m_chartData_gray];
    [_viewA addSubview:_chart_gray];
    
    
    self.peak_positionfield.text=[NSString stringWithFormat:@"%d",peakpoint_x_value];
    self.peak_valuefield.text=[NSString stringWithFormat:@"%d",peakvalue];
    //self.peak_valuefield.text=[NSString stringWithFormat:@"%d",peakvalue];
    //[self showEmptyPeakGraph];//jinbei
    self.peakpointlabel.text = [NSString stringWithFormat:@"%@%d%@%d%@",@"(",peakpoint_x_value,@",", peakvalue,@")"];
    
    int xx=30+peakpoint_x_value * (self.viewA.frame.size.width-60)/_mlength -30;
    int yy=5+(_chart_gray.max_y_axis-peakvalue) * (self.viewA.frame.size.height-10)/_chart_gray.max_y_axis-25;
    if(xx<0){
        xx=0;
    }
    if(xx>self.viewA.frame.size.width-60){
        xx=self.viewA.frame.size.width-60;
    }
    self.peaklabelview.frame = CGRectMake(xx,yy,100,21);
    // _lineChart.tag = 1;
        //add lambda
    for (int ni=0; ni<_mlength; ni++)
    {
        NSNumber *fsig = _m_chartData_ref[ni];
        
        _m_chartData_lam[ni] = [NSNumber numberWithFloat: (float)(727.0 - 0.292655*fsig.floatValue)];
    }
    _chart_sig.color = [UIColor fsLightGray];
    //[_chart_sig setChartData:_m_chartData_lam];
    //
    
    _chart_ref = [[FSLineChart alloc] initWithFrame:CGRectMake(30, 5, [UIScreen mainScreen].bounds.size.width - 60, _viewC.frame.size.height - 10)];
    
    _chart_ref.gridStep = 4;
    _chart_ref.color = [UIColor fsOrange];
    
    _chart_ref.labelForIndex = ^(NSUInteger item) {
        return [NSString stringWithFormat:@"%lu",(unsigned long)item];
    };
//
    _chart_ref.labelForValue = ^(CGFloat value) {
        return [NSString stringWithFormat:@"%.f", value];
    };
    [_viewB addSubview:_chart_ref];
    [self showPeakGraph];
}

- (void)showEmptyPeakGraph
{
    if (isCameraMode)
    {
        //        _m_chartData_sig = chartData;
        if (_chart_peak != nil)
        {
            [_chart_peak removeFromSuperview];
            _chart_peak = nil;
        }
    }
    
    // peak chart
    _chart_peak = [[FSLineChart alloc] initWithFrame:CGRectMake(30, 5, [UIScreen mainScreen].bounds.size.width - 60, _viewC.frame.size.height - 10)];
    
    _chart_peak.gridStep = 4;
    _chart_peak.color = [UIColor fsOrange];
    
    _chart_peak.labelForIndex = ^(NSUInteger item) {
        return [NSString stringWithFormat:@"%lu",(unsigned long)item];
    };
    
    _chart_peak.labelForValue = ^(CGFloat value) {
        return [NSString stringWithFormat:@"%.f", value];
    };
    
    
//    int nPeakPos = [self getCurrentPeak];
//    [self makePeakData:nPeakPos];
//    
        _dataPeak = [NSMutableArray arrayWithCapacity:60];
    
        for (int ni=0; ni<60; ni++)
        {
            _dataPeak[ni] = [NSNumber numberWithFloat:0.1f];
        }
    
    [_chart_peak setChartData:_dataPeak];
    
    //    [_chart_ref setChartData:_m_chartData_ref];
    [_viewC addSubview:_chart_peak];
}

- (void)showPeakGraph
{
    if (isCameraMode)
    {
//        _m_chartData_sig = chartData;
        if (_chart_peak != nil)
        {
            [_chart_peak removeFromSuperview];
            _chart_peak = nil;
        }
    }
    
    // peak chart
    _chart_peak = [[FSLineChart alloc] initWithFrame:CGRectMake(30, 5, [UIScreen mainScreen].bounds.size.width - 60, _viewC.frame.size.height - 10)];
    
    _chart_peak.gridStep = 4;
    _chart_peak.color = [UIColor fsOrange];
    
    _chart_peak.labelForIndex = ^(NSUInteger item) {
        return [NSString stringWithFormat:@"%lu",(unsigned long)item];
    };
    
    _chart_peak.labelForValue = ^(CGFloat value) {
        return [NSString stringWithFormat:@"%.f", value];
    };
    
//    int nPeakPos = [self getCurrentPeak];
    
    int nPeakPos = [self getCurrentGap];
    [self makePeakData:nPeakPos];
   
    [_chart_peak setChartData:_dataPeak];
    
    //    [_chart_ref setChartData:_m_chartData_ref];
    [_viewC addSubview:_chart_peak];
}

- (void)refreshPeakData
{
    nCurPeakPointer = 0;
    
    for (int ni=0; ni<60; ni++)
        _dataPeak[ni] = [NSNumber numberWithFloat:0.0f];

}

- (void)makePeakData:(float)fPeakValue
{
    if (nCurPeakPointer < 60)
    {
        _dataPeak[nCurPeakPointer] = [NSNumber numberWithFloat:fPeakValue];
        nCurPeakPointer++;
        
        for (int ni=nCurPeakPointer; ni<60; ni++)
        {
            _dataPeak[ni] = [NSNumber numberWithFloat:0.0];

        }
    }
    else        // left shift peak data
    {
        for (int ni=0; ni<59; ni++)
        {
            _dataPeak[ni] = _dataPeak[ni+1];
        }
        _dataPeak[59] = [NSNumber numberWithFloat:fPeakValue];
    }
}

- (int)getCurrentPeak
{
    
    float fmaxRate = 0;
    int nmaxPos = -1;
    
    for (int ni=1; ni<199; ni++)
    {
        
        NSNumber* numRate = _chartRate[ni];
        NSNumber* numPrevRate = _chartRate[ni-1];
        NSNumber* numNextRate = _chartRate[ni+1];
        
        float fRate = numRate.floatValue;
        float fPrevRate = numPrevRate.floatValue;
        float fNextRate = numNextRate.floatValue;
        
        if (fRate-fPrevRate >= 0 && fNextRate-fRate <= 0)
        {
            if (fmaxRate < fRate)
            {
                fmaxRate = fRate;
                nmaxPos = ni;
            }
        }
    }
    
    return nmaxPos;
}

- (int)getCurrentGap
{
    
    float fminRate = 10000.0f;
    int nminPos = -1;
    
    for (int ni=1; ni<199; ni++)
    {
        
        NSNumber* numRate = _chartRate[ni];
        NSNumber* numPrevRate = _chartRate[ni-1];
        NSNumber* numNextRate = _chartRate[ni+1];
        
        float fRate = numRate.floatValue;
        float fPrevRate = numPrevRate.floatValue;
        float fNextRate = numNextRate.floatValue;
        
        if (fRate-fPrevRate < 0 && fNextRate-fRate >= 0)
        {
            if (fminRate > fRate)
            {
                fminRate = fRate;
                nminPos = ni;
            }
        }
    }
    return nminPos;
}


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

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection// peak value detection
{
    UIImage* image = [self imageFromSampleBuffer:sampleBuffer];
    CGImageRef imageRef = image.CGImage;
    NSData *data        = (NSData *)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(imageRef)));
    char *pixels        = (char *)[data bytes];
    if(isPeakDrawingMode){
       // if (chartDatagraytemp.count >= _mlength-1) {
        [chartDatagraytemp removeAllObjects];
        //int nViewWidth = self.previewView.frame.size.width;
        int nViewHeight = self.view.frame.size.height;
        m_nImageWidth = image.size.height;
        m_nImageHeight = image.size.width;
        float ratio =(float)m_nImageHeight/(float)nViewHeight;
        //ratio = 2.879;
        //ratio of image (1080*1920) and real device screen size```iphone 6 is 375*667
        int startpoint_x_value = _startcursor_x;
        int startpoint_y_value = _startcursor_y;
        int endpoint_y_value = _endcursor_y;
        //_nLength = sqrt(x1*x1 + y1*y1);
        NSLog(@"%@", chartDatagraytemp );
        int dy = startpoint_y_value-(int)(_mstartY/ratio);
        for(int i=0;i<dy;i++){
            [chartDatagraytemp addObject:[NSString stringWithFormat:@"%d", 0]];
        }
        int peakvaluetemp=0;
        int peakpoint_x_value_temp = dy;
        int deltay = endpoint_y_value-startpoint_y_value;

        for (int ni = startpoint_y_value; ni < endpoint_y_value; ni++)
        {
            int nX = startpoint_x_value * ratio;
            int nY = ni * ratio;
            int pixelInfo = ((m_nImageHeight * (m_nImageWidth-nX)) + nY) * 4;
                     //int pixelInfo = (( image.size.width  * nY) + nX ) * 4;
            int realR = (pixels[pixelInfo] + 256) % 256;
            int realG = (pixels[pixelInfo+1] + 256) % 256;
            int realB = (pixels[pixelInfo+2] + 256) % 256;
            int sum = realR + realG + realB;
            [chartDatagraytemp addObject:[NSString stringWithFormat:@"%d", sum]];
            if(sum > peakvaluetemp){
                peakvaluetemp = sum;
                peakpoint_x_value_temp = ni;
            }
        }
        peakvalue = peakvaluetemp;
        peakpoint_x_value = peakpoint_x_value_temp;
        
        for(int i=endpoint_y_value;i<_mlength;i++){
            [chartDatagraytemp addObject:[NSString stringWithFormat:@"%d", 0]];
        }
        
    }
    
    else{
    
        NSLog(@"aaaa");
    }
    _m_chartData_gray = chartDatagraytemp;
    //}
}
///+

- (IBAction)showAndHideCamera:(id)sender
{
    if (isCameraMode)
    {
        isCameraMode = false;
        [[self session] stopRunning];
        [_btnShowHideCam setTitle:@"Dynamic Analysis" forState:UIControlStateNormal];

//        _previewView.hidden = YES;
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        
        if (_timer_peak) {
            [_timer_peak invalidate];
            _timer_peak = nil;
        }
    }
    else
    {
        isCameraMode = true;
//        _previewView.hidden = NO;
        [[self session] startRunning];
        [_btnShowHideCam setTitle:@"Static Analysis" forState:UIControlStateNormal];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(showGraph) userInfo:nil repeats:YES];
        _timer_peak = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(showPeakGraph) userInfo:nil repeats:YES];
    }
    
}

- (IBAction)onTap_PeakStart:(id)sender {

    if (isPeakDrawingMode)
    {
        isPeakDrawingMode = false;
        _peakindex = 0;
        [[self session] stopRunning];
        [self.peak_StartButton setTitle:@"Start" forState:UIControlStateNormal];
        [_m_chartData_peak removeAllObjects];
        if (_timer_peakB) {
            [_timer_peakB invalidate];
            _timer_peakB = nil;
        }
        
    }
    else
    {
        isPeakDrawingMode = true;
        
        _dynamic_peakdata_xls = [NSString stringWithFormat:@"%@ %@ %@ %@ %@\n", @" Time (s)",@",",@"Peak Position",@",",@"Peak Value"];
        [self showEmptyPeakGraphB];
        int buffer = (int)[self.total_t.text floatValue] / [self.delta_t.text floatValue];
        _m_chartData_peak =[NSMutableArray arrayWithCapacity:buffer + 1];
        for(int i=0 ; i<buffer+1;i++){
            _m_chartData_peak[i]=[NSNumber numberWithInt:(int)(0)];
        }
        
        [[self session] startRunning];
        self.total_time.text=self.total_t.text;
        [self.peak_StartButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        //_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(showGraph) userInfo:nil repeats:YES];
        float t = [self.delta_t.text floatValue];
        
        _timer_peakB = [NSTimer scheduledTimerWithTimeInterval:t target:self selector:@selector(showPeakGraphDynamically) userInfo:nil repeats:YES];
        
    }
}

-(void)showPeakGraphDynamically
{
    if(isPeakDrawingMode){
        [self drawGraygraph:nil];
        if (_chart_graypeak != nil)
        {
            [_chart_graypeak removeFromSuperview];
        }
        //float fCost = [[NSDecimalNumber decimalNumberWithString:@"3.45"]floatValue] ;
        float t = [self.delta_t.text floatValue];
        float time=_peakindex * t;
        _dynamic_peakdata_xls = [NSString stringWithFormat:@"%@ %.2f,%d,%d\n", _dynamic_peakdata_xls,time,peakpoint_x_value, peakvalue];
        // _dynamic_peakdata_xls = [NSString stringWithFormat:@"%@ %.2f,%d\n", _dynamic_peakdata_xls,time, peakpoint_x_value];
        _m_chartData_peak[_peakindex]=[NSNumber numberWithInt:(int)(peakvalue)];
        _peakindex++;
        _chart_graypeak = [[FSLineChart alloc] initWithFrame:CGRectMake(30, 5, [UIScreen mainScreen].bounds.size.width - 60, _viewB.frame.size.height - 10)];
        _chart_graypeak.gridStep = 4;
        _chart_graypeak.color = [UIColor redColor];
        [_chart_graypeak setChartData:_m_chartData_peak];
        [_viewB addSubview:_chart_graypeak];
        if(_peakindex==_m_chartData_peak.count){
            isPeakDrawingMode = false;
            _peakindex = 0;
            [[self session] stopRunning];
            [self.peak_StartButton setTitle:@"Start" forState:UIControlStateNormal];
            [_m_chartData_peak removeAllObjects];
            if (_timer_peakB) {
                [_timer_peakB invalidate];
                _timer_peakB = nil;
            }
        }
    }
}

-(void)drawGraygraph:(id)sender{
    if(isPeakDrawingMode){
        if (_chart_gray != nil)
        {
            [_chart_gray removeFromSuperview];
        }
        _chart_gray = [[FSLineChart alloc] initWithFrame:CGRectMake(30, 5, [UIScreen mainScreen].bounds.size.width - 60, _viewA.frame.size.height - 10)];
        _chart_gray.gridStep = 4;
        _chart_gray.color = [UIColor redColor];
        //[_m_chartData_gray removeAllObjects];
        //_m_chartData_gray = chartDatagraytemp;
        [_chart_gray setChartData:_m_chartData_gray];
//        [_chart_gray setChartData:_m_chartData_peak];
        
        [_viewA addSubview:_chart_gray];
        self.peakpointlabel.text = [NSString stringWithFormat:@"%@%d%@%d%@",@"(",peakpoint_x_value,@",", peakvalue,@")"];
        
        int xx=30+peakpoint_x_value * (self.viewA.frame.size.width-60)/_mlength -30;
        int yy=5+(_chart_gray.max_y_axis-peakvalue) * (self.viewA.frame.size.height-10)/_chart_gray.max_y_axis-25;
        if(xx<0){
            xx=0;
        }
        if(xx>self.viewA.frame.size.width-60){
            xx=self.viewA.frame.size.width-60;
        }
        self.peaklabelview.frame = CGRectMake(xx,yy,100,21);
        //self.peak_valuefield.text = [NSString stringWithFormat:@"%d", peakvalue];
        self.peak_positionfield.text = [NSString stringWithFormat:@"%d",peakpoint_x_value];
        self.peak_valuefield.text = [NSString stringWithFormat:@"%d", peakvalue];
    }
}


- (void)showEmptyPeakGraphB
{
    if (isPeakDrawingMode)
    {
        //        _m_chartData_sig = chartData;
        if (_chart_graypeak != nil)
        {
            [_chart_graypeak removeFromSuperview];
            _chart_graypeak = nil;
        }
    }
    
    // peak chart
    _chart_graypeak = [[FSLineChart alloc] initWithFrame:CGRectMake(30, 5, [UIScreen mainScreen].bounds.size.width - 60, _viewC.frame.size.height - 10)];
    
    _chart_graypeak.gridStep = 4;
    _chart_graypeak.color = [UIColor fsOrange];
    
    _chart_graypeak.labelForIndex = ^(NSUInteger item) {
        return [NSString stringWithFormat:@"%lu",(unsigned long)item];
    };
    
    _chart_graypeak.labelForValue = ^(CGFloat value) {
        return [NSString stringWithFormat:@"%.f", value];
    };
    
    
    //    int nPeakPos = [self getCurrentPeak];
    //    [self makePeakData:nPeakPos];
    //
    _dataPeak = [NSMutableArray arrayWithCapacity:60];
    int b=_m_chartData_peak.count;
    for (int ni=0; ni<b; ni++)
    {
        _dataPeak[ni] = [NSNumber numberWithFloat:0.1f];
    }
    [_chart_graypeak setChartData:_dataPeak];
    [_viewB addSubview:_chart_graypeak];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    isCameraMode = false;
    isPeakDrawingMode = false;
    
    //    [[self session] startRunning];
}

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async([self sessionQueue], ^{
        [[self session] stopRunning];
        
        //	[self removeObservers];
    });
    
    [super viewDidDisappear:animated];
}
- (void) textFieldDidBeginEditing:(UITextField *)textField:(UITextField *) textField {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}
- (void) textFieldDidEndEditing:(UITextField *)textField:(UITextField *) textField {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [self.view endEditing:YES];
    
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
   
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
  
    return YES;
    
}
- (void)keyboardDidShow:(NSNotificationCenter*)notification{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    
    [self.view setFrame:CGRectMake(0, -180, self.view.frame.size.width, self.view.frame.size.height)];
    
    [UIView commitAnimations];
}

- (void)keyboardDidHide:(NSNotificationCenter*)notification{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    
    [self.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self keyboardDidHide:UIKeyboardDidHideNotification];
    [textField resignFirstResponder];
    [self.delta_t resignFirstResponder];
    [self.total_t resignFirstResponder];
    return YES;
}



@end
