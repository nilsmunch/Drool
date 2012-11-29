//
//  DemoViewController.m
//  MGBox2 Demo App
//
//  Created by Matt Greenfield on 25/09/12.
//  Copyright (c) 2012 Big Paua. All rights reserved.
//

#import "DemoViewController.h"
#import "MGScrollView.h"
#import "MGTableBoxStyled.h"
#import "MGLine.h"
#import "DetailViewController.h"
#import "PhotoBox.h"
#import "SCAppDelegate.h"

#define TOTAL_IMAGES           10
#define IPHONE_INITIAL_IMAGES  10
#define IPAD_INITIAL_IMAGES    11

#define ROW_SIZE               (CGSize){304, 44}

#define IPHONE_PORTRAIT_PHOTO  (CGSize){148, (148*3)/4}
#define IPHONE_LANDSCAPE_PHOTO (CGSize){148, (148*3)/4}

#define IPHONE_PORTRAIT_GRID   (CGSize){312, 0}
#define IPHONE_LANDSCAPE_GRID  (CGSize){480, 0}
#define IPHONE_TABLES_GRID     (CGSize){320, 0}

#define IPAD_PORTRAIT_PHOTO    (CGSize){128, 128}
#define IPAD_LANDSCAPE_PHOTO   (CGSize){122, 122}

#define IPAD_PORTRAIT_GRID     (CGSize){136, 0}
#define IPAD_LANDSCAPE_GRID    (CGSize){390, 0}
#define IPAD_TABLES_GRID       (CGSize){624, 0}

#define HEADER_FONT            [UIFont fontWithName:@"HelveticaNeue" size:18]


static int photo = 0;




@implementation DemoViewController {
    MGBox *photosGrid, *tablesGrid, *table1, *table2;
    UIImage *arrow;
    BOOL phone;
    PhotoBox *addbox;
}



+(DemoViewController*)sharedListView {
    SCAppDelegate *del = [[UIApplication sharedApplication] delegate];
    return (DemoViewController*)del.window.rootViewController;
}

-(void)clientIsOffline {
    [self loadOfflineSection];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [PhotoBox loadDataFor:self];
    
    self.scroller = [MGScrollView scrollerWithSize:self.view.frame.size];
    [self.view addSubview:self.scroller];
    self.scroller.contentSize = CGSizeMake(200, 200);
    self.scroller.backgroundColor = [UIColor darkGrayColor];
    
    // iPhone or iPad?
    UIDevice *device = UIDevice.currentDevice;
    phone = device.userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    
    // i'll be using this a lot
    arrow = [UIImage imageNamed:@"arrow"];
    
    // setup the main scroller (using a grid layout)
    self.scroller.contentLayoutMode = MGLayoutGridStyle;
    self.scroller.bottomPadding = 8;
    
    // iPhone or iPad grid?
    CGSize photosGridSize = phone ? IPHONE_PORTRAIT_GRID : IPAD_PORTRAIT_GRID;
    
    // the photos grid
    photosGrid = [MGBox boxWithSize:photosGridSize];
    photosGrid.contentLayoutMode = MGLayoutGridStyle;
    [self.scroller.boxes addObject:photosGrid];
    
    // the tables grid
    CGSize tablesGridSize = phone ? IPHONE_TABLES_GRID : IPAD_TABLES_GRID;
    tablesGrid = [MGBox boxWithSize:tablesGridSize];
    tablesGrid.contentLayoutMode = MGLayoutGridStyle;
    [self.scroller.boxes addObject:tablesGrid];
    
    // the features table
    table1 = MGBox.box;
    [tablesGrid.boxes addObject:table1];
    table1.sizingMode = MGResizingShrinkWrap;
    
    // the subsections table
    table2 = MGBox.box;
    [tablesGrid.boxes addObject:table2];
    table2.sizingMode = MGResizingShrinkWrap;
    
    // add photo boxes to the grid
}

-(void)loadMoreBoxes:(int)boxes {
    //[photosGrid.boxes removeAllObjects];
    for (int i = 1; i <= boxes; i++) {
        int photo = [self randomMissingPhoto];
        [photosGrid.boxes addObject:[self photoBoxFor:photo]];
    }
    if (boxes > 0) {
    [photosGrid.boxes addObject:self.photoAddBox];
    }
    [self loadIntroSection];
    [tablesGrid layout];
}


-(void)introScreen {
    int initialImages = TOTAL_IMAGES;
    for (int i = 1; i <= initialImages; i++) {
        int photo = [self randomMissingPhoto];
        [photosGrid.boxes addObject:[self photoBoxFor:photo]];
    }
    
    // add a blank "add photo" box
    [photosGrid.boxes addObject:self.photoAddBox];
    
    // load some table sections
    [self loadIntroSection];
    [tablesGrid layout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation
                                           duration:1];
    [self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
}

#pragma mark - Rotation and resizing

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orient
                                         duration:(NSTimeInterval)duration {
    
    BOOL portrait = UIInterfaceOrientationIsPortrait(orient);
    
    // grid size
    photosGrid.size = phone ? portrait
    ? IPHONE_PORTRAIT_GRID
    : IPHONE_LANDSCAPE_GRID : portrait
    ? IPAD_PORTRAIT_GRID
    : IPAD_LANDSCAPE_GRID;
    
    // photo sizes
    CGSize size = phone
    ? portrait ? IPHONE_PORTRAIT_PHOTO : IPHONE_LANDSCAPE_PHOTO
    : portrait ? IPAD_PORTRAIT_PHOTO : IPAD_LANDSCAPE_PHOTO;
    
    // apply to each photo
    for (MGBox *photo in photosGrid.boxes) {
        photo.size = size;
        photo.layer.shadowPath
        = [UIBezierPath bezierPathWithRect:photo.bounds].CGPath;
        photo.layer.shadowOpacity = 0;
    }
    
    // relayout the sections
    [self.scroller layoutWithSpeed:duration completion:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orient {
    for (MGBox *photo in photosGrid.boxes) {
        photo.layer.shadowOpacity = 1;
    }
}

#pragma mark - Photo Box factories

- (CGSize)photoBoxSize {
    BOOL portrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    
    // what size plz?
    return phone
    ? portrait ? IPHONE_PORTRAIT_PHOTO : IPHONE_LANDSCAPE_PHOTO
    : portrait ? IPAD_PORTRAIT_PHOTO : IPAD_LANDSCAPE_PHOTO;
}

-(void)spawnDetail:(PhotoBox *)details {
    DLog(@"TAG WAS %i",details.tag);
    DetailViewController *dv = [DetailViewController detailWithDict:[details imageData]];
    [dv setPrePhoto:details.img];
    dv.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.view.window.rootViewController = dv;
    /*
    [self presentViewController:dv animated:YES completion:^{
        //nil;
        self.view.window.rootViewController = dv;
    }];
     */
}

- (MGBox *)photoBoxFor:(int)i {
   // DLog(@"Loading box %i",i);
    // make the photo box
    PhotoBox *box = [PhotoBox photoBoxFor:i size:[self photoBoxSize]];
    
    // remove the box when tapped
    __block id bbox = box;
    box.onTap = ^{
        [self spawnDetail:box];
    };
    box.onLongPress = ^{
        MGBox *section = (id)box.parentBox;
        
        // remove
        [section.boxes removeObject:bbox];
        
        // if we don't have an add box, and there's photos left, add one
        if (![self photoBoxWithTag:-1] && [self randomMissingPhoto]) {
            [section.boxes addObject:self.photoAddBox];
        }
        
        // animate
        [section layoutWithSpeed:0.3 completion:nil];
        [self.scroller layoutWithSpeed:0.3 completion:nil];
    };
    
    
    return box;
}

- (MGBox *)photoAddBox {
    if (addbox != nil) {return addbox;}
    
    // make the box
    addbox = [PhotoBox photoAddBoxWithSize:[self photoBoxSize]];
    
    // deal with taps
    //__block MGBox *bbox = box;
    addbox.onTap = ^{
        [photosGrid.boxes removeObject:self.photoAddBox];
        [PhotoBox loadDataFor:self];
    };
    
    return addbox;
}

#pragma mark - Photo Box helpers

- (int)randomMissingPhoto {
    photo++;
    return photo;
    /*
    int photo;
    id existing;
    
    do {
        if (self.allPhotosLoaded) {
            return 0;
        }
        photo = arc4random_uniform(PhotoBox.dbSize) + 1;
        existing = [self photoBoxWithTag:photo];
    } while (existing);
    
    return photo;
     */
}

- (MGBox *)photoBoxWithTag:(int)tag {
    for (MGBox *box in photosGrid.boxes) {
        if (box.tag == tag) {
            return box;
        }
    }
    return nil;
}

- (BOOL)allPhotosLoaded {
    return FALSE;
    return photosGrid.boxes.count == TOTAL_IMAGES && ![self photoBoxWithTag:-1];
}



#pragma mark - Main menu sections

- (void)loadOfflineSection {
    
    // empty table2 out
    [table2.boxes removeAllObjects];
    
    // make the section
    MGTableBoxStyled *section = MGTableBoxStyled.box;
    [table2.boxes addObject:section];
    
    // header
    MGLine *head = [MGLine lineWithLeft:@"Offline error" right:nil size:ROW_SIZE];
    head.leftPadding = head.rightPadding = 16;
    [section.topLines addObject:head];
    head.font = HEADER_FONT;
    
    id waffle = @"Could not reach the Dribbble.com server. You will need to be connected to the internet in order to use Drool.";
    
    // stuff
    MGLine *line = [MGLine multilineWithText:waffle font:nil width:304
                                     padding:UIEdgeInsetsMake(16, 16, 16, 16)];
    [section.topLines addObject:line];
    
    // animate
    //table2.size = TABLE_SIZE;
    [table2 layoutWithSpeed:0.3 completion:nil];
    [self.scroller layoutWithSpeed:0.3 completion:nil];
    
    // scroll
    [self.scroller scrollToView:section withMargin:8];
}

- (void)loadIntroSection {
    
    // empty table2 out
    [table2.boxes removeAllObjects];
    
    // make the section
    MGTableBoxStyled *section = MGTableBoxStyled.box;
    [table2.boxes addObject:section];
    
    // header
    MGLine *head = [MGLine lineWithLeft:@"What is Drool" right:nil size:ROW_SIZE];
    head.leftPadding = head.rightPadding = 16;
    [section.topLines addObject:head];
    head.font = HEADER_FONT;
    
    id waffle = @"Drool is a showcasing app, bringing you random fresh content from the website Dribbble.com.\n\nIt serves no real purpose except viewing some of the most popular and fresh eyecandy from some of the internets most elite graphic designers.\n\nSo whether you do it for fun, inspiration or just pure boredom, I hope you will tune in and feast your eyes on some of the pixelicious goodies that appear each day.";
    
    // stuff
    MGLine *line2 = [MGLine multilineWithText:waffle font:nil width:304
                                     padding:UIEdgeInsetsMake(8, 16, 16, 16)];
    [section.topLines addObject:line2];
    
    // animate
    //table2.size = TABLE_SIZE;
    [table2 layoutWithSpeed:0.3 completion:nil];
    [self.scroller layoutWithSpeed:0.3 completion:nil];
    
    // scroll
    //[self.scroller scrollToView:section withMargin:8];
}

@end
