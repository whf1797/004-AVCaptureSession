//
//  ViewController.m
//  004-AVCaptureSession
//
//  Created by 王洪飞 on 2018/11/21.
//  Copyright © 2018 王洪飞. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    // 输入输出中心
    AVCaptureSession *_captureSession;
    // 设备
    AVCaptureDevice *_captureDevice;
    // 输入源
    AVCaptureDeviceInput *_videoCaptureDeviceInput;
    AVCaptureDeviceInput *_audioCaptureDeviceInput;
    
    // 视频输出
    AVCaptureVideoDataOutput *_captureVideoDataOutput;
    // 音频输出
    AVCaptureAudioDataOutput *_captureAudioDataOutput;
    
    // 队列
    dispatch_queue_t my_queue;
    
    // 视频连接
    AVCaptureConnection *_videoConnection;
    // 音频连接
    AVCaptureConnection *_audioConnection;
    // 用来显示每一帧imageview
    UIImageView *bufferImageView;
    
}
// 写入路径
@property (nonatomic, copy)NSString *path;
// 写入
@property (nonatomic, strong)AVAssetWriter *assetWriter;
@property (nonatomic, strong)AVAssetWriterInputPixelBufferAdaptor *adaptor;

// 视频写入
@property (nonatomic, strong)AVAssetWriterInput *videoInput;
// 音频写入
@property (nonatomic, strong)AVAssetWriterInput *audioInput;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDevice];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)initDevice
{
    bufferImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 50, 375, 375)];
    [self.view addSubview:bufferImageView];
    _captureSession = [[AVCaptureSession alloc] init];
    bufferImageView.backgroundColor = [UIColor cyanColor];
    
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
    
    // 获取后置摄像头
    _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 音频输入
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    _audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:nil];
    
    _videoCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:nil];
    
    [_captureSession addInput:_videoCaptureDeviceInput];
    [_captureSession addInput:_audioCaptureDeviceInput];
    
    
    [_captureDevice lockForConfiguration:nil];
    [_captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 15)];
    [_captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 15)];
    [_captureDevice unlockForConfiguration];
    
    // 视频输出
    _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    _captureVideoDataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [_captureSession addOutput:_captureVideoDataOutput];
    my_queue = dispatch_queue_create("myqueue", DISPATCH_QUEUE_SERIAL);
    
    [_captureVideoDataOutput setSampleBufferDelegate:self queue:my_queue];
    
    // 音频连接
    _captureAudioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_captureAudioDataOutput setSampleBufferDelegate:self queue:my_queue];
    [_captureSession addOutput:_captureAudioDataOutput];
    [_captureSession startRunning];
    
}


-(void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
}
-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (output == _captureAudioDataOutput) {
        NSLog(@"音频");
    } else if (output == _captureVideoDataOutput) {
        dispatch_block_t block = ^{
            UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
            NSLog(@"视频 = %@",img);
            self->bufferImageView.image = img;
        };
        
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


-(void)conertSamplebuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!CMSampleBufferIsValid(sampleBuffer)) {
        return ;
    }
     UIImage *image = nil;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
}


// 通过抽样缓存数据创建一个UIImage对象

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer

{
    if (!CMSampleBufferIsValid(sampleBuffer)) {
        return nil;
    }
    
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    UIImage *image = nil;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    NSLog(@"format = %@", CMSampleBufferGetFormatDescription(sampleBuffer));
    
    // 锁定pixel buffer的基地址
     CVReturn ret = CVPixelBufferLockBaseAddress(imageBuffer, 0);
    @try {
        
        
        
        // 得到pixel buffer的基地址
        
        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
        
        
        
        // 得到pixel buffer的行字节数
        
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        
        // 得到pixel buffer的宽和高
        
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        if (width == 0 || height == 0) {
            
            return nil;
            
        }
        
        // 创建一个依赖于设备的RGB颜色空间
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        
        
        // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
        
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                     
                                                     bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        
        //
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        
        
        
        CGContextConcatCTM(context, transform);
        
        
        
        // 根据这个位图context中的像素数据创建一个Quartz image对象
        
        CGImageRef quartzImage = CGBitmapContextCreateImage(context);
        
        // 裁剪 图片
        
        struct CGImage *cgImage = CGImageCreateWithImageInRect(quartzImage, CGRectMake(0, 0, height, height));
        
        // 释放context和颜色空间
        
        CGContextRelease(context);
        
        CGColorSpaceRelease(colorSpace);
        
        
        
        // 用Quartz image创建一个UIImage对象image
        
       image = [UIImage imageWithCGImage:cgImage];
        
        //    UIImage *image =  [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
        
        
        
        // 释放Quartz image对象
        
        CGImageRelease(cgImage);
        
        CGImageRelease(quartzImage);
        
        // 解锁pixel buffer
    } @catch (NSException *exception) {
        
    } @finally {
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }
    
   
    
    
   
    
    
    
    
    

    
    //    NSLog(@"原来的%ld %f",(long)image.size.width,image.size.height);
    
    //    image = [self image:image rotation:UIImageOrientationRight];
    
    //    NSLog(@"变换过的%ld %f",(long)image.size.width,image.size.height);
    
    
    
    //    image.imageOrientation = 2;
    
    //    CGImageRelease(cgImage);
    
    
    
    
    
    //    UIImage *resultImage = [[JBFaceDetectorHelper sharedInstance] rotateWithImage:image isFont:isFront];
    
    
    
    return (image);
    
}

//-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
//{
//
//}







@end
