//
//  FSLineChart.m
//  AVCamManual
//
//  Created by yilun on 2/9/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <QuartzCore/QuartzCore.h>
#import "FSLineChart.h"
#import "UIColor+FSPalette.h"

@interface FSLineChart ()

@property (nonatomic, strong) NSMutableArray* data;

@property (nonatomic) CGFloat min;
@property (nonatomic) CGFloat max;
@property (nonatomic) CGMutablePathRef initialPath;
@property (nonatomic) CGMutablePathRef newPath;

@end

@implementation FSLineChart

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setDefaultParameters];
    }
    return self;
}

- (void)setChartData:(NSArray *)chartData
{
    //_data = [NSMutableArray arrayWithArray:chartData];
   // _data = [[NSMutableArray alloc] initWithArray:chartData];
    _data = [chartData copy];
    
    _min = MAXFLOAT;
    _max = -MAXFLOAT;
    
    for(int i=0;i<_data.count;i++) {
        NSNumber* number = _data[i];
        if([number floatValue] < _min)
            _min = [number floatValue];
        
        if([number floatValue] > _max)
            _max = [number floatValue];
    }
    
    _max = [self getUpperRoundNumber:_max forGridStep:_gridStep];
    _max = 800;//jinbei
    
    // No data
    if(isnan(_max)) {
        _max = 1;
    }
    _max_y_axis=(int)_max;
    
    [self strokeChart];
    
    if(_labelForValue) {
        for(int i=0;i<_gridStep;i++) {
            CGPoint p = CGPointMake(_margin + _axisWidth, _axisHeight + _margin - (i + 1) * _axisHeight / _gridStep);
            
            NSString* text = _labelForValue(_max / _gridStep * (i + 1));
            CGRect rect = CGRectMake(_margin, p.y + 2, self.frame.size.width - _margin * 2 - 4.0f, 14);
            
            float width =
            [text
             boundingRectWithSize:rect.size
             options:NSStringDrawingUsesLineFragmentOrigin
             attributes:@{ NSFontAttributeName:[UIFont systemFontOfSize:12.0f] }
             context:nil]
            .size.width;
            
            UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(p.x - width + 20, p.y + 2, width + 2, 14)];
            label.text = text;
            label.font = [UIFont systemFontOfSize:11.0f];
            label.textColor = [UIColor redColor];
            label.textAlignment = NSTextAlignmentCenter;
//            label.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.75f];

            label.backgroundColor = [UIColor clearColor];

            [self addSubview:label];
        }
    }
    
    if(_labelForIndex) {
        float scale = 1.0f;
        int q = (int)_data.count / _gridStep;
        scale = (CGFloat)(q * _gridStep) / (CGFloat)(_data.count - 1);
        for(int i=0;i<_gridStep + 1;i++) {
            NSInteger itemIndex = q * i;
            if(itemIndex >= _data.count)
            {
                itemIndex = _data.count - 1;
            }
            NSString* text = _labelForIndex(itemIndex);
            CGPoint p = CGPointMake(_margin + i * (_axisWidth / _gridStep) * scale, _axisHeight + _margin);
            UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(p.x - 6.0f, p.y + 2, self.frame.size.width, 14)];
            label.text = text;
            label.font = [UIFont boldSystemFontOfSize:11.0f];
            label.textColor = [UIColor redColor];
            [self addSubview:label];
        }
    }
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [self drawGrid];
}

- (void)drawGrid
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(ctx);
    CGContextSetLineWidth(ctx, 0.5);
    CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
    
    // draw coordinate axis
    CGContextMoveToPoint(ctx, _margin, _margin);
    CGContextAddLineToPoint(ctx, _margin, _axisHeight + _margin + 3);
    CGContextStrokePath(ctx);
    
    
    CGContextMoveToPoint(ctx, _margin, _axisHeight + _margin);
    CGContextAddLineToPoint(ctx, _axisWidth + _margin, _axisHeight + _margin);
    CGContextStrokePath(ctx);
    
    float scale = 1.0f;
    int q = (int)_data.count / _gridStep;
    scale = (CGFloat)(q * _gridStep) / (CGFloat)(_data.count - 1);
    
    // draw grid
    for(int i=0;i<_gridStep;i++) {
        CGContextSetLineWidth(ctx, 0.5);
        
        CGPoint point = CGPointMake((1 + i) * _axisWidth / _gridStep * scale + _margin, _margin);
        
        CGContextMoveToPoint(ctx, point.x, point.y);
        CGContextAddLineToPoint(ctx, point.x, _axisHeight + _margin);
        CGContextStrokePath(ctx);
        
        
        CGContextSetLineWidth(ctx, 2);
        CGContextMoveToPoint(ctx, point.x - 0.5f, _axisHeight + _margin);
        CGContextAddLineToPoint(ctx, point.x - 0.5f, _axisHeight + _margin + 3);
        CGContextStrokePath(ctx);
    }
    
    for(int i=0;i<_gridStep;i++) {
        CGContextSetLineWidth(ctx, 0.5);
        
        CGPoint point = CGPointMake(_margin, (i) * _axisHeight / _gridStep + _margin);
        
        CGContextMoveToPoint(ctx, point.x, point.y);
        CGContextAddLineToPoint(ctx, _axisWidth + _margin, point.y);
        CGContextStrokePath(ctx);
    }
    
}

- (void)strokeChart
{
    if([_data count] == 0) {
        NSLog(@"Warning: no data provided for the chart");
        return;
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    UIBezierPath *noPath = [UIBezierPath bezierPath];
    UIBezierPath* fill = [UIBezierPath bezierPath];
    UIBezierPath* noFill = [UIBezierPath bezierPath];
    
    CGFloat scale = _axisHeight / _max;
    NSNumber* first = _data[0];
    
    for(int i=1;i<_data.count;i++) {
        NSNumber* last = _data[i - 1];
        NSNumber* number = _data[i];
        
        CGPoint p1 = CGPointMake(_margin + (i - 1) * (_axisWidth / (_data.count - 1)), _axisHeight + _margin - [last floatValue] * scale);
        
        CGPoint p2 = CGPointMake(_margin + i * (_axisWidth / (_data.count - 1)), _axisHeight + _margin - [number floatValue] * scale);
        
        [fill moveToPoint:p1];
        [fill addLineToPoint:p2];
        [fill addLineToPoint:CGPointMake(p2.x, _axisHeight + _margin)];
        [fill addLineToPoint:CGPointMake(p1.x, _axisHeight + _margin)];
        
        [noFill moveToPoint:CGPointMake(p1.x, _axisHeight + _margin)];
        [noFill addLineToPoint:CGPointMake(p2.x, _axisHeight + _margin)];
        [noFill addLineToPoint:CGPointMake(p2.x, _axisHeight + _margin)];
        [noFill addLineToPoint:CGPointMake(p1.x, _axisHeight + _margin)];
    }
    
    
    [path moveToPoint:CGPointMake(_margin, _axisHeight + _margin - [first floatValue] * scale)];
    [noPath moveToPoint:CGPointMake(_margin, _axisHeight + _margin)];
    
    for(int i=1;i<_data.count;i++) {
        NSNumber* number = _data[i];
        
        [path addLineToPoint:CGPointMake(_margin + i * (_axisWidth / (_data.count - 1)), _axisHeight + _margin - [number floatValue] * scale)];
        
        [noPath addLineToPoint:CGPointMake(_margin + i * (_axisWidth / (_data.count - 1)), _axisHeight + _margin)];
    }
    
   /* CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.frame = self.bounds;
    fillLayer.bounds = self.bounds;
    fillLayer.path = fill.CGPath;
    fillLayer.strokeColor = nil;
    fillLayer.fillColor = [_color colorWithAlphaComponent:0.25].CGColor;
    fillLayer.lineWidth = 0;
    fillLayer.lineJoin = kCALineJoinRound;
    
    [self.layer addSublayer:fillLayer];
   */
    
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.frame = self.bounds;
    pathLayer.bounds = self.bounds;
    pathLayer.path = path.CGPath;
    pathLayer.strokeColor = [_color CGColor];
    pathLayer.fillColor = nil;
    pathLayer.lineWidth = 1.0;
    pathLayer.lineJoin = kCALineJoinRound;
    
    [self.layer addSublayer:pathLayer];
    
   /* CABasicAnimation *fillAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    fillAnimation.duration = 0.25;
    fillAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    fillAnimation.fillMode = kCAFillModeForwards;
    fillAnimation.fromValue = (id)noFill.CGPath;
    fillAnimation.toValue = (id)fill.CGPath;
    [fillLayer addAnimation:fillAnimation forKey:@"path"];
    */
    /*
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.duration = 0.025;// 0.25->0.025 to dispay realtime "live"
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    pathAnimation.fromValue = (__bridge id)(noPath.CGPath);
    pathAnimation.toValue = (__bridge id)(path.CGPath);
    [pathLayer addAnimation:pathAnimation forKey:@"path"];
     */
}

- (void)setDefaultParameters
{
    _color = [UIColor fsLightBlue];
    _gridStep = 3;
    _margin = 5.0f;
    _axisWidth = self.frame.size.width - 2 * _margin;
    _axisHeight = self.frame.size.height - 2 * _margin;
    _axisColor = [UIColor colorWithWhite:0.7 alpha:1.0];
}

- (CGFloat)getUpperRoundNumber:(CGFloat)value forGridStep:(int)gridStep
{
    // We consider a round number the following by 0.5 step instead of true round number (with step of 1)
    CGFloat logValue = log10f(value);
    CGFloat scale = powf(10, floorf(logValue));
    CGFloat n = ceilf(value / scale * 2);
    
    int tmp = (int)(n) % gridStep;
    
    if(tmp != 0) {
        n += gridStep - tmp;
    }
    
    return n * scale / 2.0f;
}



@end
// Copyright belongs to original author
// http://code4app.net (en) http://code4app.com (cn)
// From the most professional code share website: Code4App.net
