//
//  ViewController.m
//  BeASuccess
//
//  Created by Tarpian Gabriel Lucian on 30/01/2017.
//  Copyright © 2017 Tarpian Gabriel Lucian. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Get screen dimension
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    int height = screenRect.size.height;
    
    // Create wallpaper
    UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    UIImage *image = [UIImage imageNamed:@"TestWallpaper"];
    imageHolder.image = image;
    [self.view addSubview:imageHolder];
    
    // create toolbars
    [self vCreateToolbars:width];
    
    // creating the quote text label
    int labelPosX = 10;
    int labelPosY = height / 8;
    int labelWidth = width - labelPosX;
    int labelHeight = height - labelPosY *2.5;
    _textQuote = [[UITextView alloc]initWithFrame:CGRectMake(labelPosX, labelPosY,labelWidth,labelHeight)];
    _textQuote.backgroundColor = [UIColor grayColor];
    
    [self.view addSubview:_textQuote];
}

-(IBAction) showMainToolbar:(id)sender
{
    // Get the screen width
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    
    // set the origins of main toolbar (Pos X is -width)
    CGRect mainToolbarFrame = self.mainToolbar.frame;
    mainToolbarFrame.origin.x = -width; // moves iPad Toolbar off screen
    self.mainToolbar.frame = mainToolbarFrame;
    self.mainToolbar.hidden = NO;
    
    // create the animation
    [UIView animateWithDuration:0.7
                     animations:^(void)
     {
         // hide right arrow
         CGRect toolbarFrame = self.rightArrowToolbar.frame;
         toolbarFrame.origin.x = width; // moves iPad Toolbar off screen
         self.rightArrowToolbar.frame = toolbarFrame;
         
         // show main toolbar
         CGRect toolbarFrame2 = self.mainToolbar.frame;
         toolbarFrame2.origin.x = 0; // moves Toolbar off screen
         self.mainToolbar.frame = toolbarFrame2;
     }
                     completion:^(BOOL finished)
     {
         self.rightArrowToolbar.hidden = YES;
     }];
}

-(IBAction) showArrowToolbar:(id)sender
{
    // Get the screen width
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    
    // set the origins of arrow toolbar (Pos X is width)
    CGRect mainToolbarFrame = self.rightArrowToolbar.frame;
    mainToolbarFrame.origin.x = width; // moves Toolbar off screen
    self.rightArrowToolbar.frame = mainToolbarFrame;
    self.rightArrowToolbar.hidden = NO;
    
    // create animation
    [UIView animateWithDuration:0.7
                     animations:^(void)
     {
         // hide main toolbar
         CGRect toolbarFrame = self.mainToolbar.frame;
         toolbarFrame.origin.x = -width; // moves Toolbar off screen
         self.mainToolbar.frame = toolbarFrame;
         
         // show right toolbar
         CGRect toolbarFrame2 = self.rightArrowToolbar.frame;
         toolbarFrame2.origin.x = 0; // moves Toolbar off screen
         self.rightArrowToolbar.frame = toolbarFrame2;
     }
                     completion:^(BOOL finished)
     {
         self.mainToolbar.hidden = YES;
     }];
}

-(void) vCreateToolbars:(int)width
{
    // create the intro toolbar
    _rightArrowToolbar = [[UIToolbar alloc]init];
    _rightArrowToolbar.frame = CGRectMake(0, 0, width, 40);
    
    // create color for toolbar
    UIColor *colorToolbar = [UIColor colorWithRed:246.0f/255.0f
                                            green:206.0f/255.0f
                                             blue:147.0f/255.0f
                                            alpha:1.0f];
    
    
    // ************* Right arrow button
    UIImage *imgArrowRight = [UIImage imageNamed:@"arrowRight.png"];
    
    UIButton *btnArrowRight = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnArrowRight addTarget:self action:@selector(showMainToolbar:) forControlEvents:UIControlEventTouchUpInside];
    btnArrowRight.bounds = CGRectMake( 0, 5, 25, 25 );
    [btnArrowRight setImage:imgArrowRight forState:UIControlStateNormal];
    [btnArrowRight setShowsTouchWhenHighlighted:TRUE];
    _barBtnArrowRight = [[UIBarButtonItem alloc] initWithCustomView:btnArrowRight];
    
    // make visible items on the toolbar
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *items = [NSArray arrayWithObjects: _barBtnArrowRight, flexibleSpace, flexibleSpace, nil];
    [_rightArrowToolbar setItems:items animated:YES];
    
    // create the toolbar
    _mainToolbar = [[UIToolbar alloc] init];
    _mainToolbar.frame = CGRectMake(0, 0, width, 40);
    
    // ************* Right arrow button
    UIImage *imgArrowLeft = [UIImage imageNamed:@"arrowLeft.png"];
    
    UIButton *btnArrowLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnArrowLeft addTarget:self action:@selector(showArrowToolbar:) forControlEvents:UIControlEventTouchUpInside];
    btnArrowLeft.bounds = CGRectMake( 0, 5, 25, 25 );
    [btnArrowLeft setImage:imgArrowLeft forState:UIControlStateNormal];
    [btnArrowLeft setShowsTouchWhenHighlighted:TRUE];
    _barBtnArrowLeft = [[UIBarButtonItem alloc] initWithCustomView:btnArrowLeft];
    
    // ************* Settings button
    UIImage *imgSettings = [UIImage imageNamed:@"Settings.png"];
    
    UIButton *btnSettings = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSettings addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    btnSettings.bounds = CGRectMake( 0, 5, 25, 25 );
    [btnSettings setImage:imgSettings forState:UIControlStateNormal];
    [btnSettings setShowsTouchWhenHighlighted:TRUE];
    _barBtnSettings = [[UIBarButtonItem alloc] initWithCustomView:btnSettings];
    
    // ************ Save button
    UIImage *imgSave = [UIImage imageNamed:@"saveLogo.png"];
    
    UIButton *btnSave = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSave addTarget:self action:@selector(saveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    btnSave.bounds = CGRectMake( 100, 5, 25, 25 );
    [btnSave setImage:imgSave forState:UIControlStateNormal];
    [btnSave setShowsTouchWhenHighlighted:TRUE];
    _barBtnSave = [[UIBarButtonItem alloc] initWithCustomView:btnSave];
    
    // ************ Facebook button
    UIImage *imgFacebook = [UIImage imageNamed:@"facebookLogo.png"];
    
    UIButton *btnFacebook = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnFacebook addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    btnFacebook.bounds = CGRectMake( 200, 5, 30, 30 );
    [btnFacebook setImage:imgFacebook forState:UIControlStateNormal];
    [btnFacebook setShowsTouchWhenHighlighted:TRUE];
    _barBtnFacebook = [[UIBarButtonItem alloc] initWithCustomView:btnFacebook];
    
    // make visible items on the toolbar
    UIBarButtonItem *flexibleSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *items2 = [NSArray arrayWithObjects: _barBtnArrowLeft, flexibleSpace2, _barBtnSettings, flexibleSpace2,_barBtnSave, flexibleSpace2,_barBtnFacebook, nil];
    [_mainToolbar setItems:items2 animated:YES];
    
    _mainToolbar.hidden = YES;
    
    _rightArrowToolbar.barTintColor = colorToolbar;
    _mainToolbar.barTintColor = colorToolbar;
    
    [self.view addSubview:_rightArrowToolbar];
    [self.view addSubview:_mainToolbar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// ******************************************************** HIDE THE STATUS BAR (time, battery, etc)
-(BOOL)prefersStatusBarHidden{
    return NO;
}


@end
