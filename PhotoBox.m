//
//  Created by matt on 28/09/12.
//

#import "PhotoBox.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "DemoViewController.h"
#import "UIImageView+AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation PhotoBox
static AFHTTPClient *manager;
static DemoViewController* demoview;
static NSMutableArray *datadic;
static int dribblepage;

#pragma mark - Init

- (void)setup {
    // positioning
    self.topMargin = 8;
    self.leftMargin = 8;
    
    // background
    self.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
    
    // shadow
    self.layer.shadowColor = [UIColor colorWithWhite:0.12 alpha:1].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 0.5);
    self.layer.shadowRadius = 1;
    self.layer.shadowOpacity = 1;
}

+(int)dbSize {
    return datadic.count;
}

-(UIImage*)img {
    return imageView.image;
}

#pragma mark - Factories
+(void)loadDataFor:(DemoViewController*)demo {
    int active = [[AFNetworkActivityIndicatorManager sharedManager] activityCount];
    if (active > 0 ) {return;}
    if (manager == nil) {
        manager = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://api.dribbble.com/shots/"]];
        dribblepage = 1;
        NSLog(@"Birthing manager");
    }
    demoview = demo;
    NSMutableURLRequest *req =  [manager requestWithMethod:@"GET" path:[NSString stringWithFormat:@"popular?per_page=10&page=%i",dribblepage] parameters:nil];
    // http://api.dribbble.com/shots/everyone
    AFJSONRequestOperation *con = [AFJSONRequestOperation JSONRequestOperationWithRequest:req success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (dribblepage == 1) {
            datadic = [[JSON objectForKey:@"shots"] mutableCopy];
            [demo introScreen];
        } else {
            NSArray *newbatch = [JSON objectForKey:@"shots"];
            int newboxes = 0;
            for (NSDictionary *dic in newbatch) {
                BOOL bringit = YES;
                for (NSDictionary *exdic in datadic) {
                    if ([[exdic objectForKey:@"id"] integerValue]  == [[dic objectForKey:@"id"] integerValue]) {
                        bringit = NO;
                    }
                }
                if (bringit) {
                    [datadic addObject:dic];
                    newboxes++;
                    
                } else {
                    DLog(@"Discarded!");
                }
            }
            
            //[datadic addObjectsFromArray:[JSON objectForKey:@"shots"]];
            NSLog(@"I BRING %i",newbatch.count);
            NSLog(@"Total %i",datadic.count);
            [demo loadMoreBoxes:newboxes];
        }
        dribblepage = (dribblepage+1);
        //GOP
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Failed");
        [[DemoViewController sharedListView] clientIsOffline];
        //FAIL
    }];
    [con start];
}

+ (PhotoBox *)photoAddBoxWithSize:(CGSize)size {
    
    // basic box
    PhotoBox *box = [PhotoBox boxWithSize:size];
    
    // style and tag
    box.backgroundColor = [UIColor colorWithRed:0.74 green:0.74 blue:0.75 alpha:1];
    box.tag = -1;
    
    // add the add image
    UIImage *add = [UIImage imageNamed:@"add"];
    UIImageView *addView = [[UIImageView alloc] initWithImage:add];
    [box addSubview:addView];
    addView.center = (CGPoint){box.width / 2, box.height / 2};
    addView.alpha = 0.2;
    /*
     addView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
     | UIViewAutoresizingFlexibleRightMargin
     | UIViewAutoresizingFlexibleBottomMargin
     | UIViewAutoresizingFlexibleLeftMargin;
     */
    addView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleLeftMargin;
    addView.contentMode = UIViewContentModeScaleAspectFill;
    
    return box;
}

+ (PhotoBox *)photoBoxFor:(int)i size:(CGSize)size {
    
    // box with photo number tag
    PhotoBox *box = [PhotoBox boxWithSize:size];
    box.tag = i;
    
    // add a loading spinner
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.center = CGPointMake(box.width / 2, box.height / 2);
    spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
    | UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleBottomMargin
    | UIViewAutoresizingFlexibleLeftMargin;
    spinner.color = UIColor.lightGrayColor;
    [box addSubview:spinner];
    [spinner startAnimating];
    
    // do the photo loading async, because internets
    __block id bbox = box;
    box.asyncLayoutOnce = ^{
        [bbox loadPhoto];
    };
    
    return box;
}

#pragma mark - Layout

- (void)layout {
    [super layout];
    
    // speed up shadows
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
}

#pragma mark - Photo box loading

-(NSDictionary*)imageData {
    return datapack;
}

- (void)loadPhoto {
    if (datadic == nil) {return;}
    if (datadic.count <= self.tag-1) {DLog(@"TAG BUG!");return;}
    datapack = [datadic objectAtIndex:self.tag-1];
    
    // DLog(@"%i %@ %@",self.tag,[datapack objectForKey:@"id"],[datapack objectForKey:@"title"]);
    if (datapack == nil) {
        return;}
    NSURL *url = [NSURL URLWithString:[datapack objectForKey:@"image_teaser_url"]];
    NSArray *bits = [url.path componentsSeparatedByString:@"/"];
    
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *cacheFile = [NSString stringWithFormat:@"%@/%@_%@",cachesPath,[[datapack objectForKey:@"id"] stringValue],bits.lastObject];
    
    imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.clipsToBounds = YES;
    imageView.alpha = 0;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    if ([UIImage imageWithContentsOfFile:cacheFile]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = [UIImage imageWithContentsOfFile:cacheFile];
            [self fadeinImage];
        });
        return;
    }
    
    
    NSData* data = [NSData dataWithContentsOfURL:url];
    [data writeToFile:cacheFile atomically:YES];
    // do UI stuff back in UI land
    dispatch_async(dispatch_get_main_queue(), ^{
        // NSLog(@"Data got");
        // ditch the spinner
        
        // got the photo, so lets show it
        UIImage *image = [UIImage imageWithData:data];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.image = image;
        
        [self fadeinImage];
    });
}

-(void)fadeinImage {
    UIActivityIndicatorView *spinner = self.subviews.lastObject;
    [spinner stopAnimating];
    [spinner removeFromSuperview];
    [self addSubview:imageView];
    
    // failed to get the photo?
    if (!imageView.image) {
        self.alpha = 0.3;
        return;
    }
    
    // fade the image in
    [UIView animateWithDuration:0.2 animations:^{
        imageView.alpha = 1;
    }];
    
}

@end
