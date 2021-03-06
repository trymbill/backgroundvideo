#import "backgroundvideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@implementation backgroundvideo

@synthesize parentView, view, session, output, outputPath, isFinished, previewLayer;

#ifndef __IPHONE_3_0
@synthesize webView;
#endif

-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (backgroundvideo*)[super initWithWebView:theWebView];
    return self;
}

#pragma mark -
#pragma mark backgroundvideo

- (void) show:(CDVInvokedUrlCommand *)command
{
    //stop the device from being able to sleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.token = [command.arguments objectAtIndex:0];
    self.camera = [command.arguments objectAtIndex:1];
    
    //get rid of the old dumb view (causes issues if the app is resumed)
    self.parentView = nil;
    
    //make the view
    CGRect viewRect = CGRectMake(
                                 0,
                                 0,
                                 self.webView.superview.frame.size.width,
                                 self.webView.superview.frame.size.height
                                 );
    self.parentView = [[UIView alloc] initWithFrame:viewRect];
    [self.webView.superview addSubview:self.parentView];
    
    self.parentView.backgroundColor = [UIColor clearColor];
    
    //make child view non-filling, we'll make it circular
    CGFloat viewWidth = round(100);
    CGFloat viewHeight = round(100);
    CGFloat viewX = 10;
    CGFloat viewY = self.webView.superview.frame.size.height - 100 - 10;
    
    CGRect viewCircle = CGRectMake(viewX,viewY,100,100);
    
    self.view = [[UIView alloc] initWithFrame: viewCircle];
    [self.parentView addSubview: view];
    view.alpha = 1;
    //view.layer.masksToBounds = NO;
    //view.layer.shadowOffset = CGSizeMake(-15, 20);
    //view.layer.shadowRadius = 5;
    //view.layer.shadowOpacity = 0.5;
    view.layer.cornerRadius = 12;
    self.parentView.userInteractionEnabled = NO;
    
    //camera stuff
    
    //Capture session
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetMedium];
    
    //Get the front camera and set the capture device
    AVCaptureDevice *inputDevice = [self getCamera: self.camera];
    
    
    //write the file
    outputPath = [self getFileName];
    
    //capture device output
    CMTime maxDuration = CMTimeMakeWithSeconds(1800, 1);
    
    output = [[AVCaptureMovieFileOutput alloc]init];
    output.maxRecordedDuration = maxDuration;
    
    
    if ( [session canAddOutput:output])
        [session addOutput:output];
    
    //Capture audio input
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:nil];
    
    if ([session canAddInput:audioInput])
        [session addInput:audioInput];
    
    //Capture device input
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if ( [session canAddInput:deviceInput] )
        [session addInput:deviceInput];
    
    
    //preview view
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [self.previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
    [rootLayer insertSublayer:self.previewLayer atIndex:0];
    
    [session startRunning];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:outputPath];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) hide:(CDVInvokedUrlCommand *)command
{
    //hide
    self.view.alpha = 0;
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:outputPath];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) start:(CDVInvokedUrlCommand *)command
{

    NSURL *fileURI = [[NSURL alloc] initFileURLWithPath:outputPath];
    //go
    [output startRecordingToOutputFileURL:fileURI recordingDelegate:self ];
    
    //return true to ensure callback fires
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stop:(CDVInvokedUrlCommand *)command
{
    [output stopRecording];
    self.view.alpha = 0;
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:outputPath];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(NSString*)getFileName
{
    int fileNameIncrementer = 1;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *libPath = [self getLibraryPath];
    
    NSString *tempPath = [[NSString alloc] initWithFormat:@"%@%@_%i%@", libPath, self.token, fileNameIncrementer, FileExtension];
    
    while ([fileManager fileExistsAtPath:tempPath]) {
        tempPath = [NSString stringWithFormat:@"%@%@_%i%@", libPath, self.token, fileNameIncrementer, FileExtension];
        fileNameIncrementer++;
    }
    
    return tempPath;
}

-(NSString*)getLibraryPath
{
    NSArray *lib = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *library = [lib objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/NoCloud/", library];
}

-(AVCaptureDevice *)getCamera: (NSString *)camera
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if([camera caseInsensitiveCompare:@"front"] == NSOrderedSame)
        {
            if (device.position == AVCaptureDevicePositionFront )
            {
                captureDevice = device;
                break;
            }
        }
        else if ([camera caseInsensitiveCompare:@"BACK"] == NSOrderedSame)
        {
            if (device.position == AVCaptureDevicePositionBack )
            {
                captureDevice = device;
                break;
            }
        }
        else
        {
            //TODO: return cordova error
            NSLog(@"Coudn't find camera");
        }
    }
    return captureDevice;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
}

@end
