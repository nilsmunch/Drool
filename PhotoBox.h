//
//  Created by matt on 28/09/12.
//

#import "MGBox.h"
@class DemoViewController;

@interface PhotoBox : MGBox {
    UIImageView *imageView;
    NSDictionary *datapack;
}


+ (PhotoBox *)photoAddBoxWithSize:(CGSize)size;
+ (PhotoBox *)photoBoxFor:(int)i size:(CGSize)size;

- (void)loadPhoto;
+(void)loadDataFor:(DemoViewController*)demo;
-(UIImage *)img;
-(NSDictionary*)imageData;
+(int)dbSize;
@end
