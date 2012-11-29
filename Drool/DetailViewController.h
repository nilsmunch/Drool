//
//  DetailViewController.h
//  Drool
//
//  Created by Nils Munch on 25/11/12.
//  Copyright (c) 2012 NilsMunch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSPushPopPressView.h"

@interface DetailViewController : UIViewController <PSPushPopPressViewDelegate> {
    UIScrollView *containerView_;
    int activeCount_;
    UIImageView *catImageView;
    UILabel *artistNameLabel;
    UILabel *howtocloseLabel;
    UILabel *titleLabel;
}
@property NSDictionary *datadic;

+(id)detailWithDict:(NSDictionary *)dict;
-(void)setPrePhoto:(UIImage *)image;

@end
