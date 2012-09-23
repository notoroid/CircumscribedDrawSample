//
//  ViewController.m
//  WallPaperOblongood
//
//  Created by 能登 要 on 2012/09/20.
//  Copyright (c) 2012年 noto@irimasu.com. All rights reserved.
//

#import "ViewController.h"
#include <dispatch/dispatch.h>


@interface ViewController ()
{
    ALAssetsLibrary * _assetsLibrary;
}

@property(nonatomic,readonly) ALAssetsLibrary* assetsLibrary;
@property (weak, nonatomic) IBOutlet UIButton *buttonPhotoPicker;
@property (weak, nonatomic) IBOutlet UIImageView *imagePreviewView;

@end

@implementation ViewController

- (ALAssetsLibrary*) assetsLibrary
{
    if( _assetsLibrary == nil ){
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    return _assetsLibrary;
}

- (IBAction)firedSelectPhoto:(id)sender
{
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // モーダルビューとしてカメラ画面を呼び出す
    [self presentModalViewController:imagePicker animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
//{
//
//    [self dismissModalViewControllerAnimated:YES];
//}

//- (void) renderWallpaper:



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"info=%@", info );
    
    NSURL* URL = [info objectForKey:UIImagePickerControllerReferenceURL];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT , 0);
    dispatch_async(queue, ^{
        [self.assetsLibrary assetForURL:URL resultBlock:^(ALAsset *asset) {
            if( asset ){

#if 0
                
#if 1
                // using thumbnail
                UIImage* originalImage = [UIImage imageWithCGImage:asset.aspectRatioThumbnail scale:1.0f orientation:UIImageOrientationUp];
#else
                // using FullScreenImage
                UIImage* originalImage = [UIImage imageWithCGImage:[asset defaultRepresentation].fullScreenImage scale:1.0f orientation:UIImageOrientationUp];
#endif
                
#else
                // using full resolution image
                UIImageOrientation originalOrientation = UIImageOrientationUp;
                switch ([asset defaultRepresentation].orientation) {
                case ALAssetOrientationUp:
                    originalOrientation = UIImageOrientationUp;
                    break;
                case ALAssetOrientationUpMirrored:
                        originalOrientation = UIImageOrientationUpMirrored;
                    break;
                case ALAssetOrientationDown:
                        originalOrientation = UIImageOrientationDown;
                    break;
                case ALAssetOrientationDownMirrored:
                        originalOrientation = UIImageOrientationDownMirrored;
                    break;
                case ALAssetOrientationLeft:
                    originalOrientation = UIImageOrientationLeft;
                    break;
                case ALAssetOrientationLeftMirrored:
                    originalOrientation = UIImageOrientationLeftMirrored;
                    break;
                case ALAssetOrientationRight:
                    originalOrientation = UIImageOrientationRight;
                    break;
                case ALAssetOrientationRightMirrored:
                    originalOrientation = UIImageOrientationRightMirrored;
                    break;
                default:
                    break;
                }
                UIImage* originalImage = [UIImage imageWithCGImage:[asset defaultRepresentation].fullResolutionImage scale:1.0f orientation:originalOrientation];
#endif
                // 矩形に外接した画像を描画する
                UIImage* (^renderCircumscribed)(UIImage* sourceImage,CGSize destinationSize) = ^UIImage* (UIImage* sourceImage,CGSize size){
                    const CGSize destinationSize =CGSizeMake(ceil(size.width), ceil(size.height) );
                    const CGFloat soueceWidth = CGImageGetWidth(sourceImage.CGImage);
                    const CGFloat soueceHeight = CGImageGetHeight(sourceImage.CGImage);
                    
                    // 画像を描画する
                    CGSize sizeSource = CGSizeZero;
                    switch (originalImage.imageOrientation) {
                        case UIImageOrientationUp:
                        case UIImageOrientationUpMirrored:
                        case UIImageOrientationDown:
                        case UIImageOrientationDownMirrored:
                        {
                            sizeSource = CGSizeMake(soueceWidth, soueceHeight );
                        }
                            break;
                        case UIImageOrientationLeft:
                        case UIImageOrientationLeftMirrored:
                        case UIImageOrientationRight:
                        case UIImageOrientationRightMirrored:
                        {
                            sizeSource = CGSizeMake(soueceHeight,soueceWidth );
                        }
                            break;
                        default:
                            break;
                    }
                    
                    const double sourceRatio = sizeSource.width / sizeSource.height;
                    const double destinationRatio = destinationSize.width / destinationSize.height;
                    double scale = 1.0f;
                    CGPoint offset = CGPointZero;
                    if( sourceRatio > destinationRatio ){
                        // ソースの横幅が変換先の横幅よりも大きい場合
                        //　縦幅で比率を求める
                        scale = destinationSize.height / sizeSource.height;
                        offset = CGPointMake((destinationSize.width - sizeSource.width * scale) * .5f, .0f);
                    }else if( sourceRatio < destinationRatio ){
                        // ソースの横幅が変換先の横幅よりも小さい場合
                        //　横幅で比率を求める
                        scale = destinationSize.width / sizeSource.width;
                        offset = CGPointMake(.0f, (destinationSize.height - sizeSource.height * scale) * .5f);
                    }else{
                        scale = destinationSize.width / sizeSource.width;
                    }
                  
                    
                    CGColorSpaceRef  imageColorSpace = CGColorSpaceCreateDeviceRGB();
                    CGContextRef context = CGBitmapContextCreate (NULL,destinationSize.width,destinationSize.height,8, destinationSize.width * 4, imageColorSpace, kCGImageAlphaPremultipliedFirst );
                    
                    // グラフィックス
                    UIGraphicsPushContext(context);
                    
                    CGContextSaveGState(context);
                    CGContextScaleCTM(context, 1.0f, -1.0f);
                    CGContextTranslateCTM(context, .0f, -destinationSize.height);

                    // 画像を描画
                    [sourceImage drawInRect:CGRectMake(offset.x,offset.y, sizeSource.width * scale, sizeSource.height* scale) ];
                    
                    
                    CGContextRestoreGState(context);
                    UIGraphicsPopContext();
                    
                    CGImageRef cgImage = CGBitmapContextCreateImage(context);
                    UIImage* destinationImage = [UIImage imageWithCGImage:cgImage scale:1.0f orientation:UIImageOrientationUp];
                    CGImageRelease(cgImage);
                    
                    CGContextRelease(context);
                    CGColorSpaceRelease(imageColorSpace);
                    
                    return destinationImage;
                };

                UIImage* circumscribedImage = renderCircumscribed( originalImage , CGSizeMake(640.0f, 960.0f) );
                dispatch_async(dispatch_get_main_queue(), ^{
                    _imagePreviewView.image = circumscribedImage;
                });
                
            }
        } failureBlock:^(NSError *error) {
            
            
        }];
    });
    
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}




- (void)viewDidUnload {
    [self setButtonPhotoPicker:nil];
    [self setImagePreviewView:nil];
    [super viewDidUnload];
}
@end
//                CGContextTranslateCTM(context, .0f, -(verticalOffset*2) -(sizeImage.height - verticalOffset) * .5f );
