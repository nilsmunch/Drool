//
//  DetailViewController.m
//  Drool
//
//  Created by Nils Munch on 25/11/12.
//  Copyright (c) 2012 NilsMunch. All rights reserved.
//

#import "DetailViewController.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "SCAppDelegate.h"
#import "AFNetworking.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "DemoViewController.h"

static DetailViewController *view;
static AFHTTPClient *manager;

@implementation DetailViewController

@synthesize datadic;

+(id)detailWithDict:(NSDictionary *)dict {
    if (view == nil) {
    view = [[DetailViewController alloc] init];
        UISwipeGestureRecognizer *new = [[UISwipeGestureRecognizer alloc] initWithTarget:view action:@selector(swiped:)];
        [view.view addGestureRecognizer:new];
    }
    view.datadic = dict;
    [view performSelectorInBackground:@selector(loadPhoto) withObject:nil];
    [view fillData];
    return view;
}

-(void)fillData {
    [containerView_ setContentOffset:CGPointZero animated:YES];

    while ([self.view viewWithTag:999]) {
        [[self.view viewWithTag:999] removeFromSuperview];
    }
    titleLabel.text = [datadic objectForKey:@"title"];
    artistNameLabel.text = [[datadic objectForKey:@"player"] objectForKey:@"name"];
    
    [self performSelector:@selector(hideInfoview) withObject:nil afterDelay:4.0];
    
    containerView_.backgroundColor = [[DemoViewController sharedListView] coreColor];
    
}

-(void)setPrePhoto:(UIImage *)image {
    catImageView.image = image;
}


- (void)loadPhoto {
    if (datadic == nil) {return;}
    //DLog(@"%@",datadic);
    NSURL *url = [NSURL URLWithString:[datadic objectForKey:@"image_url"]];
    NSArray *bits = [url.path componentsSeparatedByString:@"/"];
    
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *cacheFile = [NSString stringWithFormat:@"%@/%@full_%@",cachesPath,[[datadic objectForKey:@"id"] stringValue],bits.lastObject];
    DLog(@"TEST %@",cacheFile);
    catImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if ([UIImage imageWithContentsOfFile:cacheFile]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            catImageView.image = [UIImage imageWithContentsOfFile:cacheFile];
        });
        [self loadComments];
        return;
    }
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    
    NSData* data = [NSData dataWithContentsOfURL:url];
    [data writeToFile:cacheFile atomically:YES];
    // do UI stuff back in UI land
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        // got the photo, so lets show it
        UIImage *image = [UIImage imageWithData:data];
        catImageView.clipsToBounds = YES;
        catImageView.contentMode = UIViewContentModeScaleAspectFit;
        catImageView.image = image;
        [self loadComments];
        //catImageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    });
}



-(void)swiped:(UISwipeGestureRecognizerDirection)dir {
    DLog(@"Swiped ! %i",dir);
    SCAppDelegate *del = (SCAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    del.window.rootViewController = (UIViewController*)del.viewController;
    /*
    [self dismissViewControllerAnimated:YES completion:^{
        //test,
    }];
     */
}
-(NSString *)stringByStrippingHTML:(NSString *)s {
    NSRange r;
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    containerView_ = [[UIScrollView alloc] initWithFrame:self.view.frame];
    containerView_.frame = self.view.bounds;
    containerView_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    containerView_.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:containerView_];
    
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 321, self.view.frame.size.width, 50)];
    titleLabel.backgroundColor  = [UIColor colorWithWhite:1 alpha:0.6];
    titleLabel.textAlignment = UITextAlignmentCenter;
    [containerView_ addSubview:titleLabel];
    
    artistNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 321+titleLabel.frame.size.height+3, self.view.frame.size.width, 25)];
    artistNameLabel.backgroundColor  = [UIColor colorWithWhite:1 alpha:0.4];
    artistNameLabel.textColor = [UIColor blackColor];
    artistNameLabel.font = [UIFont boldSystemFontOfSize:12];
    artistNameLabel.textAlignment = UITextAlignmentCenter;
    [containerView_ addSubview:artistNameLabel];
    
    // create the push pop press container
    CGRect firstRect = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? CGRectMake(140, 40, 500, 400) : CGRectMake(10, 10, 300, 300);
    PSPushPopPressView *pushPopPressView_ = [[PSPushPopPressView alloc] init];
	pushPopPressView_.frame = firstRect;
    pushPopPressView_.pushPopPressViewDelegate = self;
    [containerView_ addSubview:pushPopPressView_];
    
    howtocloseLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-20, self.view.frame.size.width, 20)];
    howtocloseLabel.backgroundColor  = [UIColor colorWithWhite:0  alpha:0.8];
    howtocloseLabel.textColor = [UIColor whiteColor];
    howtocloseLabel.font = [UIFont boldSystemFontOfSize:11];
    howtocloseLabel.text = @"Swipe left to right to return to list";
    howtocloseLabel.textAlignment = UITextAlignmentCenter;
    [self.view addSubview:howtocloseLabel];
    
    // add a cat image to the container
    catImageView = [[UIImageView alloc] init];
    catImageView.frame = pushPopPressView_.bounds;
    catImageView.contentMode = UIViewContentModeScaleAspectFit;
    catImageView.backgroundColor = [UIColor blackColor];
    catImageView.layer.borderColor = [UIColor blackColor].CGColor;
    catImageView.layer.borderWidth = 1.0f;
    catImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    catImageView.clipsToBounds = YES;
    [pushPopPressView_ addSubview:catImageView];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)hideInfoview {
    [UIView animateWithDuration:2.0 animations:^{
        howtocloseLabel.alpha = 0.0;
    }];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSPushPopPressViewDelegate

- (void)pushPopPressViewDidStartManipulation:(PSPushPopPressView *)pushPopPressView {
    //NSLog(@"pushPopPressViewDidStartManipulation: %@", pushPopPressView);
    
    activeCount_++;
    [UIView animateWithDuration:0.45f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // note that we can't just apply this transform to self.view, we would loose the
        // already applied transforms (like rotation)
        containerView_.transform = CGAffineTransformMakeScale(0.97, 0.97);
    } completion:nil];
}

- (void)pushPopPressViewDidFinishManipulation:(PSPushPopPressView *)pushPopPressView {
    //NSLog(@"pushPopPressViewDidFinishManipulation: %@", pushPopPressView);
    
    if (activeCount_ > 0) {
        activeCount_--;
        if (activeCount_ == 0) {
            [UIView animateWithDuration:0.45f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                containerView_.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    }
}


-(void)loadComments {
    int active = [[AFNetworkActivityIndicatorManager sharedManager] activityCount];
    if (active > 0 ) {return;}
    if (manager == nil) {
        manager = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://api.dribbble.com/shots/"]];
    }
    
    NSMutableURLRequest *req =  [manager requestWithMethod:@"GET" path:[NSString stringWithFormat:@"/shots/%@/comments",[[datadic objectForKey:@"id"] stringValue]] parameters:nil];
    // http://api.dribbble.com/shots/everyone
    AFJSONRequestOperation *con = [AFJSONRequestOperation JSONRequestOperationWithRequest:req success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        commentArray = [JSON objectForKey:@"comments"];
        DLog(@"%@",commentArray);
        [self drawComments];
        //GOP
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Failed");
        //FAIL
    }];
    [con start];
}

-(void)drawComments {
    float heightpost = artistNameLabel.frame.origin.y+artistNameLabel.frame.size.height+3;
    for (NSDictionary *comdict in commentArray) {
        NSDictionary *user = [comdict objectForKey:@"player"];
        if (!(heightpost == artistNameLabel.frame.origin.y+artistNameLabel.frame.size.height+3 && [[user objectForKey:@"name"] isEqualToString:artistNameLabel.text])) {
        UILabel *playerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, heightpost, self.view.frame.size.width, 25)];
        playerLabel.backgroundColor  = [UIColor colorWithWhite:1 alpha:0.4];
        playerLabel.textColor = [UIColor blackColor];
        playerLabel.font = [UIFont boldSystemFontOfSize:12];
        playerLabel.textAlignment = UITextAlignmentCenter;
        playerLabel.text = [user objectForKey:@"name"];
        playerLabel.tag = 999;
        [containerView_ addSubview:playerLabel];
        
        heightpost+= 25+3;
        }
        
        UITextView *commentTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, heightpost, self.view.frame.size.width, 25)];
        commentTextView.text = [self stringByStrippingHTML:[comdict objectForKey:@"body"]];
        //CGSize fullsize = [commentTextView.text sizeWithFont:commentTextView.font forWidth:commentTextView.frame.size.width lineBreakMode:UILineBreakModeWordWrap];
        CGSize fullsize = [commentTextView.text sizeWithFont:commentTextView.font constrainedToSize:CGSizeMake(310, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
        commentTextView.frame = CGRectMake(0, heightpost-6, self.view.frame.size.width, fullsize.height+10);
        commentTextView.tag = 999;
        commentTextView.contentMode = UIViewContentModeTop;
        commentTextView.textColor = [UIColor whiteColor];
        commentTextView.backgroundColor = [UIColor clearColor];
        commentTextView.userInteractionEnabled = NO;
        [containerView_ addSubview:commentTextView];
        heightpost+= fullsize.height+5+3;
    }
    
    
    containerView_.contentSize = CGSizeMake(320, heightpost);
}


- (void)pushPopPressViewWillAnimateToOriginalFrame:(PSPushPopPressView *)pushPopPressView duration:(NSTimeInterval)duration {
    //NSLog(@"pushPopPressViewWillAnimateToOriginalFrame: %@duration: %f", pushPopPressView, duration);
}

- (void)pushPopPressViewDidAnimateToOriginalFrame:(PSPushPopPressView *)pushPopPressView {
    //NSLog(@"pushPopPressViewDidAnimateToOriginalFrame: %@", pushPopPressView);
    
    // update autoresizing mask to adapt to width only
    pushPopPressView.autoresizingMask = UIViewAutoresizingNone;
    
    // ensure the view doesn't overlap with another (possible fullscreen) view
    [containerView_ sendSubviewToBack:pushPopPressView];
}

- (void)pushPopPressViewWillAnimateToFullscreenWindowFrame:(PSPushPopPressView *)pushPopPressView duration:(NSTimeInterval)duration {
    //NSLog(@"pushPopPressViewWillAnimateToFullscreenWindowFrame:%@ duration: %f", pushPopPressView, duration);
}

- (void)pushPopPressViewDidAnimateToFullscreenWindowFrame:(PSPushPopPressView *)pushPopPressView {
    //NSLog(@"pushPopPressViewDidAnimateToFullscreenWindowFrame: %@", pushPopPressView);
    
    // update autoresizing mask to adapt to borders
    pushPopPressView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

- (BOOL)pushPopPressViewShouldAllowTapToAnimateToOriginalFrame:(PSPushPopPressView *)pushPopPressView {
    //NSLog(@"pushPopPressViewShouldAllowTapToAnimateToOriginalFrame: %@", pushPopPressView);
    return YES;
}

- (BOOL)pushPopPressViewShouldAllowTapToAnimateToFullscreenWindowFrame:(PSPushPopPressView *)pushPopPressView {
    //NSLog(@"pushPopPressViewShouldAllowTapToAnimateToFullscreenWindowFrame: %@", pushPopPressView);
    return YES;
}

- (void)pushPopPressViewDidReceiveTap:(PSPushPopPressView *)pushPopPressView {
    //NSLog(@"pushPopPressViewDidReceiveTap: %@", pushPopPressView);
}

@end
