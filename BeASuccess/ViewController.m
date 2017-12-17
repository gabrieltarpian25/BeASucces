//
//  ViewController.m
//  BeASuccess
//
//  Created by Tarpian Gabriel Lucian on 30/01/2017.
//  Copyright © 2017 Tarpian Gabriel Lucian. All rights reserved.
//

#import "ViewController.h"
#import "DBManager.h"

// imported for screenshot
#import <QuartzCore/QuartzCore.h>

// imported for sharing on facebook
#import <Social/Social.h>
#import <Photos/Photos.h>

// used for random number generator
#include <time.h>
#include <stdlib.h>

// used for internet connection
#import "Reachability.h"

#import "MBProgressHUD.h"

// import for facebook
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

// import for twitter
#import <TwitterKit/TwitterKit.h>

#ifdef RELEASE
    # define NSLog(...) //remove loggin in production
#else
    #define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])
#endif

@interface ViewController ()

@end

// format NSLog to not display timestamp


static BOOL displayAdvice = TRUE;

static NSArray *_bookTitles;
static NSArray *_bookAuthors;
static NSArray *_bookImages;

static NSArray *_moviesTitle;
static NSArray *_moviesYear;
static NSArray *_moviesImages;

static BOOL iphoneSE = FALSE;

@implementation ViewController

-(void) viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    // Start coding from here
    
    [NSThread sleepForTimeInterval:1.2f];
    
    bool initial_advice_displayed = [[NSUserDefaults standardUserDefaults] boolForKey:@"InitialAdviceDisplayed"];
    if(initial_advice_displayed == TRUE && displayAdvice == TRUE )
    {
        int adviceId = [self calculateAdviceID];
        NSString *advice = [[DBManager getSharedInstance] getAdviceByID:adviceId];
        
        [self sendAlert:@"Hey, successful, it's me, Roady! My advice for you is ..." :advice:false];
    }
    else displayAdvice = TRUE;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // set icon badge to 0
    // It will be set when a quote needs to be calculated
    // [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone) {
        
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
                
            case 1136:
                // printf("iPhone 5 or 5S or 5C");
                iphoneSE = TRUE;
                break;
            case 1334:
                // printf("iPhone 6/6S/7/8");
                break;
            case 2208:
                // printf("iPhone 6+/6S+/7+/8+");
                break;
            case 2436:
                // printf("iPhone X");
                break;
        }
    }
    
    [self initializeBooksAndMovies];
    
    // Get if this is the first time of running the app
    BOOL boSecondTime = [[NSUserDefaults standardUserDefaults] boolForKey:@"SecondTime"];
    
    if(boSecondTime == NO)
    {
        // set current day as 0
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"CurrentDay"];
        
        // Get screen dimension
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        int width = screenRect.size.width;
        int height = screenRect.size.height;
        
        // Create wallpaper
        UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        UIImage *image = [UIImage imageNamed:@"InitialImage"];
        imageHolder.image = image;
        
        // create black overlay
        UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]];
        [imageHolder addSubview:overlay];
        
        [self.view addSubview:imageHolder];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        // hud.mode = MBProgressHUDModeAnnularDeterminate;
        hud.label.text = @"Setting up everything for you ...";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // create push notification when running app for first time
            [self createPushNotification:9 m:0 boAlert:NO];
            [self initializeAdvicesArray];
            [self initializeQuotesArray];
            
            [hud hideAnimated:YES];
            
            [self displayQuote];
            [self showInitialIntro_1];
            
        });
    }
    else [self displayQuote];
}

-(void) displayQuote
{
    int quoteId = [self calculateQuoteID];
    //int quoteId = 99;
    
    // Get if this is the first time of running the app
    BOOL boSecondTime = [[NSUserDefaults standardUserDefaults] boolForKey:@"SecondTime"];
    
    if(boSecondTime == FALSE)
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"SecondTime"];
    
    NSString *imageName = [[DBManager getSharedInstance] getCategoryByID:quoteId];
    
    // Get screen dimension
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    int height = screenRect.size.height;
    
    // Create wallpaper
    _imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    UIImage *image = [UIImage imageNamed:imageName];
    _imageHolder.image = image;
    
    // create black overlay
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]];
    [_imageHolder addSubview:overlay];
    [self.view addSubview:_imageHolder];
    
    // creating the quote text label
    int labelPosX = 5;
    int labelPosY = height / 10;
    int labelWidth = width - labelPosX * 2;
    int labelHeight = height - labelPosY * 2;
    _textQuote = [[UITextView alloc]initWithFrame:CGRectMake(labelPosX, labelPosY,labelWidth,labelHeight)];
    
    // get quote, author and create the final string
    NSString *quote = [[DBManager getSharedInstance] getQuoteByID:quoteId];
    NSString *author = [[DBManager getSharedInstance] getAuthorByID:quoteId];
    
    if(quote == nil || author == nil)
    {
        [self sendAlert:@"Error" :@"Failed to retrieve quote from database. Please reinstall the application." :false];
    }
    
    NSString *finalString = [NSString stringWithFormat:@"%@\n\n%@", quote, author];
    _strQuoteAndAuthor = [[NSMutableString alloc] initWithString:finalString];
    
    // create the font
    int font_size = [self calculateFontSize:finalString];
    _fontSize = font_size;
    UIFont *textViewfont = [UIFont fontWithName:@"Noteworthy-Bold" size:font_size];
    
    // text color
    UIColor *textColor = [UIColor colorWithRed:255.0f/255.0f
                                         green:165.0f/255.0f
                                          blue:0.0f/255.0f
                                         alpha:1.0f];
    
    // text color
    UIColor *textBackgroundColor = [UIColor colorWithRed:255.0f/255.0f
                                                   green:165.0f/255.0f
                                                    blue:0.0f/255.0f
                                                   alpha:0.0f];
    
    // Assign quote to label
    _textQuote.text = finalString;
    _textQuote.textColor = textColor;
    _textQuote.backgroundColor = textBackgroundColor;
    [_textQuote setUserInteractionEnabled:NO];
    _textQuote.font = textViewfont;
    _textQuote.textAlignment = NSTextAlignmentCenter;
    
    // Vertical center alignment
    [self adjustContentSize:_textQuote];
    
    _textAuthor = [[UITextView alloc]initWithFrame:CGRectMake(0, 0, 100,100)];
    
    // create the author text
    NSString *textCopyright = [NSString stringWithFormat:@"TheRoadToSuccess\n%cGabriel Tarpian",169];
    _textAuthor.text = textCopyright;
    UIFont *textAuthorFont = [UIFont fontWithName:@"Noteworthy-Bold" size:10];
    _textAuthor.font = textAuthorFont;
    _textAuthor.textAlignment = NSTextAlignmentRight;
    _textAuthor.backgroundColor = [UIColor clearColor];
    _textAuthor.textColor = textColor;
    [_textAuthor setUserInteractionEnabled:NO];
    
    // check if heigh needed by text is bigger than the height
    CGSize text_size = _textAuthor.contentSize;
    int height_needed = (int) text_size.height;
    int width_needed = (int) text_size.width;
    
    // create positions for copyright text
    
    // check if device is iPhone X and apply the offset
    int iPhoneXOffset = 0;
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
    {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 2436:
                iPhoneXOffset = 10;
                break;
            default:
                break;
        }
    }
    int textPosX = width - width_needed - iPhoneXOffset;
    int textPosY = height - height_needed;
    _textAuthor.frame = CGRectMake(textPosX, textPosY, width_needed, height_needed);
    
    // create the banner
    int bannerPosX = 0;
    int bannerPosY = self.textQuote.frame.origin.y + self.textQuote.frame.size.height;
    int bannerWidth = width;
    int bannerHeight = height - bannerPosY;
    
    // create the banner view
    _bannerView = [[GADBannerView alloc]initWithFrame:CGRectMake(bannerPosX, bannerPosY,bannerWidth,bannerHeight)];
    
     _bannerView.adUnitID = @"ca-app-pub-7014753020131070/3584035347";
    _bannerView.rootViewController = self;
    
    //  TO DO: remove this when releasing the app (just for testing)
    GADRequest *request = [GADRequest request];
    [self.bannerView loadRequest:request];
    
    // [self.bannerView loadRequest:[GADRequest request]];
    
    // create toolbars
    [self vCreateToolbars:width];
    
    // add components to main view
    [self.view addSubview:_textQuote];
    [self.view addSubview:_textAuthor];
    [self.view addSubview:_bannerView];
    
    [self displayInitialAnimation];
}

-(void) displayInitialAnimation
{
    // Get the screen width
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    
    // store the initial positions
    int textQuotePosX = self.textQuote.frame.origin.x;
    int textAuthorPosX = self.textAuthor.frame.origin.x;
    int mainToolbarPosX = self.mainToolbar.frame.origin.x;
    int rightArrowToolbarPosX = self.rightArrowToolbar.frame.origin.x;
    int bannerViewPosX = self.bannerView.frame.origin.x;
    
    // set the negative origins of _textQuote, _textAuthor, mainToolbar and rightArrowToolbar
    self.textQuote.frame = CGRectMake(width, self.textQuote.frame.origin.y, self.textQuote.frame.size.width,self.textQuote.frame.size.height);
    
    self.textAuthor.frame = CGRectMake(width, self.textAuthor.frame.origin.y, self.textAuthor.frame.size.width,self.textAuthor.frame.size.height);
    
    self.mainToolbar.frame = CGRectMake(0, self.mainToolbar.frame.origin.y, self.mainToolbar.frame.size.width, self.mainToolbar.frame.size.height);
    
    self.rightArrowToolbar.frame = CGRectMake(width, self.rightArrowToolbar.frame.origin.y, self.rightArrowToolbar.frame.size.width, self.rightArrowToolbar.frame.size.height);
    
    self.bannerView.frame = CGRectMake(width, self.bannerView.frame.origin.y, self.bannerView.frame.size.width, self.bannerView.frame.size.height);
    
    // create the animation
    [UIView animateWithDuration:1.3
                     animations:^(void)
     {
         // set the positive positions for textQuote and textAuthor
         // set the negative origins of _textQuote and _textAuthor
         self.textQuote.frame = CGRectMake(textQuotePosX, self.textQuote.frame.origin.y, self.textQuote.frame.size.width,self.textQuote.frame.size.height);
         
         self.textAuthor.frame = CGRectMake(textAuthorPosX, self.textAuthor.frame.origin.y, self.textAuthor.frame.size.width,self.textAuthor.frame.size.height);
         
         self.mainToolbar.frame = CGRectMake(mainToolbarPosX, self.mainToolbar.frame.origin.y, self.mainToolbar.frame.size.width, self.mainToolbar.frame.size.height);
         
         self.rightArrowToolbar.frame = CGRectMake(rightArrowToolbarPosX, self.rightArrowToolbar.frame.origin.y, self.rightArrowToolbar.frame.size.width, self.rightArrowToolbar.frame.size.height);
         
         self.bannerView.frame = CGRectMake(bannerViewPosX, self.bannerView.frame.origin.y, self.bannerView.frame.size.width, self.bannerView.frame.size.height);
         
         
     }
                     completion:^(BOOL finished)
     {
         
     }];
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
    [UIView animateWithDuration:0.6
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
    [UIView animateWithDuration:0.6
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
    // check if device is iPhone X and apply the offset
    int iPhoneXOffset = 0;
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
    {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 2436:
                iPhoneXOffset = 30;
                break;
            default:
                break;
        }
    }
    
    // ########################################################## create the intro toolbar ###################################################
    _rightArrowToolbar = [[UIToolbar alloc]init];
    _rightArrowToolbar.frame = CGRectMake(0, 0+iPhoneXOffset, width, 40);
    
    // Settings button
    UIImage *imgSettings = [UIImage imageNamed:@"Settings_r.png"];
    // UIImage *imgArrowRight = [self imageWithImage:aux convertToSize:CGSizeMake(32, 32)];
    
    UIButton *btnSettings = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSettings addTarget:self action:@selector(showMainToolbar:) forControlEvents:UIControlEventTouchUpInside];
    // btnSettings.bounds = CGRectMake( 0, 5 + iPhoneXOffset, 25, 25 );
    [btnSettings setImage:imgSettings forState:UIControlStateNormal];
    [btnSettings setShowsTouchWhenHighlighted:TRUE];
    _barBtnSettings = [[UIBarButtonItem alloc] initWithCustomView:btnSettings];
    
    // make visible items on the toolbar
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *items = [NSArray arrayWithObjects: _barBtnSettings, flexibleSpace, flexibleSpace, nil];
    [_rightArrowToolbar setItems:items animated:YES];
    
    // ########################################################## create the main toolbar ###################################################
    _mainToolbar = [[UIToolbar alloc] init];
    _mainToolbar.frame = CGRectMake(-width, 0 + iPhoneXOffset, width, 40);
    
    // *** Left arrow button
    UIImage *imgArrowLeft = [UIImage imageNamed:@"LeftArrow_r.png"];
    // UIImage *imgArrowLeft = [self imageWithImage:aux convertToSize:CGSizeMake(32, 32)];
    
    UIButton *btnArrowLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnArrowLeft addTarget:self action:@selector(showArrowToolbar:) forControlEvents:UIControlEventTouchUpInside];
    // btnArrowLeft.bounds = CGRectMake( 0, 5, 25, 25 );
    [btnArrowLeft setImage:imgArrowLeft forState:UIControlStateNormal];
    [btnArrowLeft setShowsTouchWhenHighlighted:TRUE];
    _barBtnArrowLeft = [[UIBarButtonItem alloc] initWithCustomView:btnArrowLeft];
    
    // *** Clock button
    UIImage *imgClock = [UIImage imageNamed:@"Clock_r.png"];
    UIImage *imgClockSelected = [UIImage imageNamed:@"Clock_r_selected.png"];
    // UIImage *imgSettings = [self imageWithImage:aux convertToSize:CGSizeMake(32, 32)];
    
    _btnClock = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnClock addTarget:self action:@selector(changeNotificationTime:) forControlEvents:UIControlEventTouchUpInside];
    // btnClock.bounds = CGRectMake( btnClock.bounds.origin.x, btnClock.bounds.origin.y, 35, 35 );
    [_btnClock setImage:imgClock forState:UIControlStateNormal];
    [_btnClock setImage:imgClockSelected forState:UIControlStateDisabled];
    
    _barBtnClock = [[UIBarButtonItem alloc] initWithCustomView:_btnClock];
    
    // ************ Save button
    UIImage *imgSave = [UIImage imageNamed:@"Save_r.png"];
    UIImage *imgSaveSelected = [UIImage imageNamed:@"Save_r_selected.png"];
    // UIImage *imgSave = [self imageWithImage:aux convertToSize:CGSizeMake(30, 30)];
    
    _btnSave = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnSave addTarget:self action:@selector(saveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    // btnSave.bounds = CGRectMake( btnSave.bounds.origin.x, btnSave.bounds.origin.y, 40, 40 );
    [_btnSave setImage:imgSave forState:UIControlStateNormal];
    [_btnSave setImage:imgSaveSelected forState:UIControlStateDisabled];
    _barBtnSave = [[UIBarButtonItem alloc] initWithCustomView:_btnSave];
    
    // ************ Share button
    UIImage *imgShare = [UIImage imageNamed:@"Share_r.png"];
    
    _btnShare = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnShare addTarget:self action:@selector(shareQuoteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_btnShare setImage:imgShare forState:UIControlStateNormal];
    [_btnShare setShowsTouchWhenHighlighted: TRUE];
    _barBtnShare = [[UIBarButtonItem alloc] initWithCustomView:_btnShare];
    
    // ************ Books button
    UIImage *imgBooks = [UIImage imageNamed:@"Books_r"];
    
    _btnBooks = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnBooks addTarget:self action:@selector(booksButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_btnBooks setImage:imgBooks forState:UIControlStateNormal];
    [_btnBooks setImage:imgBooks forState:UIControlStateDisabled];
    [_btnBooks setShowsTouchWhenHighlighted:TRUE];
    _barBtnBooks = [[UIBarButtonItem alloc] initWithCustomView:_btnBooks];
    
    // ************ Movies button
    UIImage *imgMovies = [UIImage imageNamed:@"Movies_r"];
    
    _btnMovies = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnMovies addTarget:self action:@selector(moviesButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_btnMovies setImage:imgMovies forState:UIControlStateNormal];
    [_btnMovies setImage:imgMovies forState:UIControlStateDisabled];
    [_btnMovies setShowsTouchWhenHighlighted:TRUE];
    _barBtnMovies = [[UIBarButtonItem alloc] initWithCustomView:_btnMovies];
     
    // ************ Info button
    UIImage *imgInfo = [UIImage imageNamed:@"Info_r"];
    UIImage *imgInfoSelected = [UIImage imageNamed:@"Info_r_selected"];
    // UIImage *imgInfo = [self imageWithImage:aux convertToSize:CGSizeMake(32, 32)];
    
    _btnInfo = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnInfo addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    // btnInfo.bounds = CGRectMake( 300, 5, 27, 27 );
    [_btnInfo setImage:imgInfo forState:UIControlStateNormal];
    [_btnInfo setImage:imgInfoSelected forState:UIControlStateDisabled];
    _barBtnInfo = [[UIBarButtonItem alloc] initWithCustomView:_btnInfo];
    
    // make visible items on the toolbar
    UIBarButtonItem *flexibleSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *items2 = [NSArray arrayWithObjects: _barBtnArrowLeft, flexibleSpace2, _barBtnClock, flexibleSpace2, _barBtnSave,flexibleSpace2,  _barBtnShare, flexibleSpace2,_barBtnBooks, flexibleSpace2, _barBtnMovies, flexibleSpace2,  _barBtnInfo, nil];
    [_mainToolbar setItems:items2 animated:YES];
    
    // background color for rightArrowToolbar
    [self.rightArrowToolbar setBackgroundImage:[UIImage new]
                            forToolbarPosition:UIToolbarPositionAny
                                    barMetrics:UIBarMetricsDefault];
    _rightArrowToolbar.barTintColor = [UIColor clearColor];
    
    // background color for main toolbar
    [self.mainToolbar setBackgroundImage:[UIImage new]
                      forToolbarPosition:UIToolbarPositionAny
                              barMetrics:UIBarMetricsDefault];
    _mainToolbar.barTintColor = [UIColor clearColor];
    
    // ########################################################## create the share toolbar ###################################################
    _shareToolbar = [[UIToolbar alloc] init];
    _shareToolbar.frame = CGRectMake(0, -40, width, 40);
    
    // ************ ArrowUp Button
    UIImage *imgArrowUp = [UIImage imageNamed:@"ArrowUp_r.png"];
    
    _btnArrowUp = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnArrowUp addTarget:self action:@selector(arrowUpButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_btnArrowUp setImage:imgArrowUp forState:UIControlStateNormal];
    [_btnArrowUp setShowsTouchWhenHighlighted: TRUE];
    _barBtnArrowUp = [[UIBarButtonItem alloc] initWithCustomView:_btnArrowUp];
    
    // ************ Facebook button
    UIImage *imgFacebook = [UIImage imageNamed:@"Facebook_r.png"];
    UIImage *imgFacebookSelected = [UIImage imageNamed:@"Facebook_r_selected.png"];
    // UIImage *imgFacebook = [self imageWithImage:aux convertToSize:CGSizeMake(40, 40)];
    
    _btnFacebook = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnFacebook addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    // btnFacebook.bounds = CGRectMake( 200, 5, 32, 32 );
    [_btnFacebook setImage:imgFacebook forState:UIControlStateNormal];
    [_btnFacebook setImage:imgFacebookSelected forState:UIControlStateDisabled];
    
    _barBtnFacebook = [[UIBarButtonItem alloc] initWithCustomView:_btnFacebook];
    
    // ************ Twitter button
    UIImage *imgTwitter = [UIImage imageNamed:@"Twitter_r.png"];
    UIImage *imgTwitterSelected = [UIImage imageNamed:@"Twitter_r_selected.png"];
    // UIImage *imgTwitter = [self imageWithImage:aux convertToSize:CGSizeMake(32, 32)];
    
    _btnTwitter = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnTwitter addTarget:self action:@selector(twitterButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    // btnTwitter.bounds = CGRectMake( 300, 5, 27, 27 );
    [_btnTwitter setImage:imgTwitter forState:UIControlStateNormal];
    [_btnTwitter setImage:imgTwitterSelected forState:UIControlStateDisabled];
    _barBtnTwitter = [[UIBarButtonItem alloc] initWithCustomView:_btnTwitter];
    
    // ************ WhatsApp button
    UIImage *imgPlus = [UIImage imageNamed:@"Plus_r.png"];
    UIImage *imgPlusSelected = [UIImage imageNamed:@"Plus_r_selected.png"];
    
     _btnPlus = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnPlus addTarget:self action:@selector(whatsAppButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_btnPlus setImage:imgPlus forState:UIControlStateNormal];
    [_btnPlus setImage:imgPlusSelected forState:UIControlStateDisabled];
    _barBtnPlus = [[UIBarButtonItem alloc] initWithCustomView:_btnPlus];
    
    // make visible items on the toolbar
    UIBarButtonItem *flexibleSpace3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *items3 = [NSArray arrayWithObjects: _barBtnArrowUp,flexibleSpace3, _barBtnFacebook, flexibleSpace3, _barBtnTwitter, flexibleSpace3, _barBtnPlus, nil];
    [_shareToolbar setItems:items3 animated:YES];
    
    // background color for _shareToolbar
    [self.shareToolbar setBackgroundImage:[UIImage new]
                            forToolbarPosition:UIToolbarPositionAny
                                    barMetrics:UIBarMetricsDefault];
    _shareToolbar.barTintColor = [UIColor clearColor];
    
    // ########### create the books toolbar ############
    _booksToolbar = [[UIToolbar alloc] init];
    _booksToolbar.frame = CGRectMake(width, 0, width, 40);
    _booksToolbar.tintColor = [UIColor blackColor];
    _booksToolbar.backgroundColor = [UIColor blackColor];
    _booksToolbar.barStyle = UIBarStyleBlack;
    
    // **** create arrow right image
    UIImage *imgCancelBooksTable = [UIImage imageNamed:@"ArrowRight_r"];
    
    _btnHideBooksToolbar = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnHideBooksToolbar addTarget:self action:@selector(CancelBooksToolbarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_btnHideBooksToolbar setImage:imgCancelBooksTable forState:UIControlStateNormal];
    [_btnHideBooksToolbar setShowsTouchWhenHighlighted: TRUE];
    _barBtnHideBooksToolbar = [[UIBarButtonItem alloc] initWithCustomView:_btnHideBooksToolbar];
    
    // text color
    UIColor *textColor = [UIColor colorWithRed:255.0f/255.0f
                                         green:165.0f/255.0f
                                          blue:0.0f/255.0f
                                         alpha:1.0f];
    
    UIBarButtonItem* booksTitleButton = [[UIBarButtonItem alloc] initWithTitle:@"Books" style:UIBarButtonItemStyleDone target:self action:nil];
    [booksTitleButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: textColor,  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    [booksTitleButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: textColor,  NSForegroundColorAttributeName,nil] forState:UIControlStateDisabled];
    // [booksTitleButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: booksTitleFont,  NSFontAttributeName,nil] forState:UIControlStateNormal];
    // [booksTitleButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: booksTitleFont,  NSFontAttributeName,nil] forState:UIControlStateDisabled];
    booksTitleButton.enabled = NO;
    
    // ************ Info button
    UIImage *imgInfoBooks = [UIImage imageNamed:@"Info_r"];
    UIImage *imgInfoBooksSelected = [UIImage imageNamed:@"Info_r_selected"];
    // UIImage *imgInfo = [self imageWithImage:aux convertToSize:CGSizeMake(32, 32)];
    
    _btnInfoBooksToolbar = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnInfoBooksToolbar addTarget:self action:@selector(infoBooksButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    // btnInfo.bounds = CGRectMake( 300, 5, 27, 27 );
    [_btnInfoBooksToolbar setImage:imgInfoBooks forState:UIControlStateNormal];
    [_btnInfoBooksToolbar setImage:imgInfoBooksSelected forState:UIControlStateDisabled];
    _barBtnInfoBooksToolbar = [[UIBarButtonItem alloc] initWithCustomView:_btnInfoBooksToolbar];
    
    // set items to booksToolbar
    NSArray *items4 = [NSArray arrayWithObjects: _barBtnHideBooksToolbar, flexibleSpace3, booksTitleButton, flexibleSpace3, _barBtnInfoBooksToolbar, nil];
    [_booksToolbar setItems:items4 animated:YES];
    
    // ########### create the books toolbar ############
    _moviesToolbar = [[UIToolbar alloc] init];
    _moviesToolbar.frame = CGRectMake(width, 0, width, 40);
    _moviesToolbar.tintColor = [UIColor blackColor];
    _moviesToolbar.backgroundColor = [UIColor blackColor];
    _moviesToolbar.barStyle = UIBarStyleBlack;
    
    // **** create arrow right image
    UIImage *imgCancelMoviesTable = [UIImage imageNamed:@"ArrowRight_r"];
    
    _btnHideMoviesToolbar = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnHideMoviesToolbar addTarget:self action:@selector(CancelMoviesToolbarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_btnHideMoviesToolbar setImage:imgCancelMoviesTable forState:UIControlStateNormal];
    [_btnHideMoviesToolbar setShowsTouchWhenHighlighted: TRUE];
    _barBtnHideMoviesToolbar = [[UIBarButtonItem alloc] initWithCustomView:_btnHideMoviesToolbar];
    
    UIBarButtonItem* moviesTitleButton = [[UIBarButtonItem alloc] initWithTitle:@"Movies" style:UIBarButtonItemStyleDone target:self action:nil];
    [moviesTitleButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: textColor,  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    [moviesTitleButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: textColor,  NSForegroundColorAttributeName,nil] forState:UIControlStateDisabled];
    // [booksTitleButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: booksTitleFont,  NSFontAttributeName,nil] forState:UIControlStateNormal];
    // [booksTitleButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: booksTitleFont,  NSFontAttributeName,nil] forState:UIControlStateDisabled];
    moviesTitleButton.enabled = NO;
    
    // ************ Info button
    UIImage *imgInfoMovies = [UIImage imageNamed:@"Info_r"];
    UIImage *imgInfoMoviesSelected = [UIImage imageNamed:@"Info_r_selected"];
    // UIImage *imgInfo = [self imageWithImage:aux convertToSize:CGSizeMake(32, 32)];
    
    _btnInfoMoviesToolbar = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnInfoMoviesToolbar addTarget:self action:@selector(infoMoviesButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    // btnInfo.bounds = CGRectMake( 300, 5, 27, 27 );
    [_btnInfoMoviesToolbar setImage:imgInfoMovies forState:UIControlStateNormal];
    [_btnInfoMoviesToolbar setImage:imgInfoMoviesSelected forState:UIControlStateDisabled];
    _barBtnInfoMoviesToolbar = [[UIBarButtonItem alloc] initWithCustomView:_btnInfoMoviesToolbar];
    
    // set items to booksToolbar
    NSArray *items5 = [NSArray arrayWithObjects: _barBtnHideMoviesToolbar, flexibleSpace3, moviesTitleButton, flexibleSpace3, _barBtnInfoMoviesToolbar, nil];
    [_moviesToolbar setItems:items5 animated:YES];
    
    [self.view addSubview:_rightArrowToolbar];
    [self.view addSubview:_mainToolbar];
    [self.view addSubview:_shareToolbar];
    [self.view addSubview:_booksToolbar];
    [self.view addSubview:_moviesToolbar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// ******************************************************** CHANGE NOTIFICATION TIME BUTTON PRESSED
-(IBAction)changeNotificationTime:(id)sender
{
    _btnClock.enabled = FALSE;
    
    // hide animated main toolbar by setting its x position to 0
    // create the animation
    [UIView animateWithDuration:0.6
                     animations:^(void)
     {
         // hide right arrow
         CGRect toolbarFrame = self.mainToolbar.frame;
         toolbarFrame.origin.y = 0;
         self.mainToolbar.frame = toolbarFrame;
     }
                     completion:^(BOOL finished)
     {
     }];
    
    // check if user has allowed notification access
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus != UNAuthorizationStatusAuthorized)
        {
            [self sendAlert:@"Information" :@"You will not receive notifications at the moment. Please allow our app to send you notifications by navigating to Settings -> Notifications -> ToSucces.\n\n Thank you" :false];
        }
    }];
    
    int display_width = self.view.frame.size.width;
    int display_height = self.view.frame.size.height;
    
    // set up the date picker
    _datePickerNotification = [[UIDatePicker alloc] init];
    _datePickerNotification.datePickerMode = UIDatePickerModeTime;
    _datePickerNotification.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    int posYDatePicker = display_height - (display_height / 3);
    _datePickerNotification.frame = CGRectMake(0, posYDatePicker, display_width, display_height - posYDatePicker);
    
    // create color
    UIColor *colorDatePicker = [UIColor colorWithRed:30.0f/255.0f
                                               green:30.0f/255.0f
                                                blue:30.0f/255.0f
                                               alpha:1.0f];
    _datePickerNotification.backgroundColor = colorDatePicker;
    [_datePickerNotification setValue:[UIColor orangeColor] forKey:@"textColor"];
    
    // default value
    int currentHour = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"Hour"];
    int currentMin  = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"Minute"];
    NSDate *currentDate = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: currentDate];
    [components setHour: currentHour];
    [components setMinute: currentMin];
    NSDate *newDate = [gregorian dateFromComponents: components];
    _datePickerNotification.date = newDate;
    
    // setup the toolbar
    _toolbarNotification = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,45)];
    _toolbarNotification.barStyle = UIBarStyleDefault;
    _toolbarNotification.hidden = NO;
    _toolbarNotification.barTintColor = [UIColor blackColor];
    
    UIBarButtonItem *flexibleSpaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(notificationHourChanged)];
    [doneButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor orangeColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    
    UIBarButtonItem* notifButton = [[UIBarButtonItem alloc] initWithTitle:@"Notification Time" style:UIBarButtonItemStyleDone target:self action:nil];
    [notifButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor orangeColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    [notifButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor orangeColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateDisabled];
    notifButton.enabled = NO;
    
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelNotificationHour)];
    [cancelButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor orangeColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    
    [_toolbarNotification setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpaceLeft, notifButton,flexibleSpaceLeft, doneButton, nil]];
    
    // [_dateNotification addSubview:_toolbarNotification];
    // _dateNotification.inputAccessoryView = _toolbarNotification;
    [self.view addSubview:_datePickerNotification];
    [self.view addSubview:_toolbarNotification];
}
// *********************************************************************************

-(IBAction)CancelBooksToolbarButtonPressed:(id)sender
{
    _btnBooks.enabled = TRUE;
    
    // Get screen dimension
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    
    // create the animation
    [UIView animateWithDuration:0.6
                     animations:^(void)
     {
         // show booksToolbar
         CGRect booksToolbarFrame = self.booksToolbar.frame;
         booksToolbarFrame.origin.x = width;
         self.booksToolbar.frame = booksToolbarFrame;
         
         // show tableView
         CGRect tableViewFrame = _booksTableView.frame;
         tableViewFrame.origin.x = width;
         _booksTableView.frame = tableViewFrame;
     }
                     completion:^(BOOL finished)
     {
     }];
}

-(IBAction)CancelMoviesToolbarButtonPressed:(id)sender
{
    _btnMovies.enabled = TRUE;
    
    // Get screen dimension
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    
    // create the animation
    [UIView animateWithDuration:0.6
                     animations:^(void)
     {
         // hide moviesToolbar
         CGRect booksToolbarFrame = self.moviesToolbar.frame;
         booksToolbarFrame.origin.x = width;
         self.moviesToolbar.frame = booksToolbarFrame;
         
         // hide tableView
         CGRect tableViewFrame = _moviesTableView.frame;
         tableViewFrame.origin.x = width;
         _moviesTableView.frame = tableViewFrame;
     }
                     completion:^(BOOL finished)
     {
     }];
}

// ******************************************************** NOTIFICATION HOUR CHANGED
-(void) notificationHourChanged
{
    _btnClock.enabled = NO;
    
    int currentHour = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"Hour"];
    int currentMinute  = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"Minute"];
    
    // get the date stored in _dateNotification
    NSDate *notificationDate = [_datePickerNotification date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:notificationDate];
    int nextHour = (int) [components hour];
    int nextMinute = (int) [components minute];
    
    bool hide = YES;
    if(currentHour != nextHour || currentMinute != nextMinute)
    {
        [self createPushNotification:nextHour m:nextMinute boAlert:YES];
    }
    else
    {
        [self sendAlert:@"Info" :@"The requested notification time is the same with the current notification time " :false];
        hide = NO;
    }
    
    if( hide )
    {
        _toolbarNotification.hidden = YES;
        _datePickerNotification.hidden = YES;
        
        // check if device is iPhone X and apply the offset
        int iPhoneXOffset = 0;
        if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
        {
            switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
                case 2436:
                    iPhoneXOffset = 30;
                    break;
                default:
                    break;
            }
        }
        
        // unhide animated main toolbar by setting its Y position to 0
        [UIView animateWithDuration:0.6
                         animations:^(void)
         {
             // hide right arrow
             CGRect toolbarFrame = self.mainToolbar.frame;
             toolbarFrame.origin.y = 0 + iPhoneXOffset;
             self.mainToolbar.frame = toolbarFrame;
         }
                         completion:^(BOOL finished)
         {
         }];
    }
}
// *********************************************************************************

// ******************************************************** CREATE PUSH NOTIFICATION
-(void) createPushNotification:(int)hour m:(int)minute boAlert:(BOOL)alert
{
    // first of all, cancel all notifications
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
    
    // get current quote day
    NSCalendar *calendarN = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    NSDateComponents *componentsN = [calendarN components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    
    // create the date from today or tomorrow at the desired hour
    [componentsN setHour:hour];
    [componentsN setMinute:minute];
    
    // create the LocalNotification
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.hour = hour;
    dateComponents.minute = minute;
    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:YES];
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString localizedUserNotificationStringForKey:@"Hey, successful!" arguments:nil];
    content.body = [NSString localizedUserNotificationStringForKey:@"It's time for a quote!"
                                                         arguments:nil];
    content.sound = [UNNotificationSound defaultSound];
    NSInteger myValue = 1;
    NSNumber *number = [NSNumber numberWithInteger: myValue];
    content.badge = number;
    
    // request the notification
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Quote"
                                                                          content:content trigger:trigger];
    ///Schedule localNotification
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (!error)
        {
            // store the hour and the minute
            [[NSUserDefaults standardUserDefaults]setInteger:hour forKey:@"Hour"];
            [[NSUserDefaults standardUserDefaults]setInteger:minute forKey:@"Minute"];
            
            // send a confirmation alert only the current notification is not the default notification
            if( alert == YES )
            {
                NSString *message = [[NSString alloc] initWithFormat:@"Notification time changed to %02d:%02d",hour,minute];
                
                [self sendAlert:@"Success" : message: false];
            }
        }
        else
        {
            [self sendAlert:@"Error" :@"Failed to change the notification time. Please try again":false];
        }
    }];
    
}
// *********************************************************************************

// ******************************************************** SAVE BUTTON PRESSED
-(IBAction)saveButtonPressed:(id)sender
{
    _btnSave.enabled = FALSE;
    if( [self hasPhotoLibraryAcess] )
        [self savePhoto];
    else [self sendAlert:@"Error" :@"App did not receive access to Photo Library. Please go to Settings -> Privacy -> Photos and allow access to our app. Thank you":false];
}
// *********************************************************************************

-(BOOL) hasPhotoLibraryAcess
{
    // check if user received rights for using the photos library
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized)
        return true;
    else return false;
}

-(void) savePhoto
{
    UIImage *image = [self takeScreenshot];
    
    NSData *imageData = UIImagePNGRepresentation(image);
    if (imageData)
    {
        //[imageData writeToFile:@"screenshot.png" atomically:YES];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        [self sendAlert:@"Success" :@"Photo saved. Please check your gallery":false];
        
    }
    else
    {
        [self sendAlert:@"Error" :@"Failed to save the photo. Please try again":false];
        
    }
}

// ******************************************************** FACEBOOK BUTTON PRESSED
-(IBAction)facebookButtonPressed:(id)sender
{
    _btnFacebook.enabled = NO;
    
    // check if facebook app is installed
    BOOL isInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]];
    if (!isInstalled)
    {
        [self sendAlert:@"Error" :@"You need to have Facebook app installed in order to share this quote":false];
        
        return;
    }
    
    UIImage *image = [self takeScreenshot];
    
    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
    photo.image = image;
    photo.caption = @"Quote of the day ...";
    photo.userGenerated = YES;
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[photo];
    content.hashtag = [FBSDKHashtag hashtagWithString:@"#TheRoadToSuccess"];
    
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:self];
}
// *********************************************************************************

// ******************************************************** TWITTER BUTTON PRESSED
-(IBAction)twitterButtonPressed:(id)sender
{
    _btnTwitter.enabled = FALSE;
    
    // check if twitter app is installed
    BOOL isInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
    if (!isInstalled)
    {
        [self sendAlert:@"Error" :@"You need to have Twitter app installed in order to share this quote":false];
        return;
    }
    
    // get current quote screenshot
    UIImage *image = [self takeScreenshot];
    
    TWTRComposer *composer = [[TWTRComposer alloc] init];
    
    [composer setText:@"#TheRoadToSuccess #QuoteOfTheDay"];
    [composer setImage:image];
    
    /*
     Step 1: Check if there are logged in users
     Step 2a: If yes => post the tweet
     Step 2b: If no => Create a loggin session then post the tweet
     */
    
    bool isUserLoggedIn = [[NSUserDefaults standardUserDefaults] boolForKey:@"TwitterLoggedIn"];
    if(isUserLoggedIn)
    {
        // Called from a UIViewController
        [composer showFromViewController:self completion:^(TWTRComposerResult result) {
            if (result == TWTRComposerResultCancelled) {
                _btnTwitter.enabled = TRUE;
            }
            else
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self sendAlert:@"Success" :@"Tweet posted" :true];
                });
            }
        }];
        
    }
    else
    {
        [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
            if (session)
            {
                // Called from a UIViewController
                [composer showFromViewController:self completion:^(TWTRComposerResult result) {
                    if (result == TWTRComposerResultCancelled) {
                        _btnTwitter.enabled = TRUE;
                    }
                    else
                    {
                        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"TwitterLoggedIn"];
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [self sendAlert:@"Success" :@"Tweet posted" :true];
                        });
                    }
                }];
            }
            else
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self sendAlert:@"Error" :@"Failed to connect to your twitter account" :true];
                });
            }
        }];
    }
}
// *********************************************************************************

// ******************************************************** INFO BUTTON PRESSED

-(IBAction)infoButtonPressed:(id)sender
{
    _btnInfo.enabled = FALSE;
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSString *msg = [[NSString alloc] initWithFormat:@"Success is a very personal thing. What drives one person may be radically different for another. And understanding how others measure success can help you better understand your own definition. For me, health success, right now, is having a muscular and lean body, weighting 75 kg (165 lbs) and having a ten percent body fat, having an incredible energy to work, play, have fun and be active all day. How do I plan to achieve success? By having 3 home workouts per week (usually in the morning before going to work), drinking 2l of water per day, resting 7 hours per night, having at least 2 days per week without meat, eating at least 3 salads per week. When do I plan to achieve success? By the end of May, 2018. So now I know what success is for me, I know how to achieve it and I’ve also set a due date. What should I do next? Take action, stick to the schedule! What I will do after I reach success? I will change my definition for success, I will raise the bar, I will continue my road to success. This is an example of how to define success. \n\nWhat you should do next? Define success in all areas of life (health, relationships, social, career, financial, spiritual, giving). Please be careful, define your version of success not the version of your parents, friends, relatives or anybody else have set for you. Then take action! I wish you to grow and be the best version of you!\n\nThank you for using this application!! The main important thing is to enjoy the journey because it is actually the destination. There is no point in trying to reach something that does not make you happy.\n\n The Road To Success \n Version: %@ \n\nCopyright © 2017 \nGabriel Tarpian\nAll rights reserved", appVersion];
    
    [self sendAlert:@"What is Success?" :msg:false];
}
// *********************************************************************************

-(IBAction)infoBooksButtonPressed:(id)sender
{
    _btnInfoBooksToolbar.enabled = FALSE;
    
    [self sendAlert:@"Hey, successful! It's me, Roady..." :@"Here are some books that will help you in your Road To Success. These books will help you to achieve goals faster, be more productive, have a better money management and increase your wisdom about life. I recommend you to read all of them, commit yourself to reading 1,2,3 or even 4 books per month. The main important thing is to commit to something and stick to the schedule, no matter how small the commitment is. By starting reading, you will discover many more books, feel free to read anything you like. Please take notice that you will change your life in a spectacular way!":false];
}

-(IBAction)infoMoviesButtonPressed:(id)sender
{
    _btnInfoMoviesToolbar.enabled = FALSE;
    
    [self sendAlert:@"Hey, successful! It's me, Roady..." :@"Here are some movies that will inspire and uplift you. You may find strength when going through some hard times or you could just boost your motivation. Watch and learn. Enjoy!":false];
}

// ******************************************************** SHOW ADVICE
-(void) showAdvice:(NSString*)advice
{
    // send a confirmation alert
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Hey, successful! It's me, Roady..."
                                 message:advice
                                 preferredStyle:UIAlertControllerStyleAlert];
    // create color for toolbar
    UIColor *backgroundColorAlert = [UIColor colorWithRed:130.0f/255.0f
                                                    green:130.0f/255.0f
                                                     blue:130.0f/255.0f
                                                    alpha:1.0f];
    UIView *firstSubview = alert.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    for (UIView *subSubView in alertContentView.subviews) { //This is main catch
        subSubView.backgroundColor = backgroundColorAlert;//Here you change background
    }
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"I am successful"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                                   [alert dismissViewControllerAnimated:YES completion:nil];
                               }];
    
    [alert addAction:okButton];
    
    [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                             green:165.0f/255.0f
                                              blue:0.0f/255.0f
                                             alpha:1.0f]];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self presentViewController:alert animated:YES completion:nil];
}
// *********************************************************************************

// ******************************************************** INITIALIZE QUOTES ARRAY
-(void) initializeQuotesArray
{
    int number_of_quotes = [[DBManager getSharedInstance] getNumberOfQuotes];
    
    NSMutableArray *quotes = [NSMutableArray array];
    for (NSInteger i = 1; i <= number_of_quotes; i++)
        [quotes addObject:[NSNumber numberWithInteger:i]];
    
    // store them in user defaults
    [[NSUserDefaults standardUserDefaults] setObject:quotes forKey:@"AvailableQuotes"];
}
// *********************************************************************************


// ******************************************************** INITIALIZE ADVICES ARRAY
-(void) initializeAdvicesArray
{
    int number_of_advices = [[DBManager getSharedInstance] getNumberOfAdvices];
    
    NSMutableArray *advices = [NSMutableArray array];
    for (NSInteger i = 1; i <= number_of_advices; i++)
        [advices addObject:[NSNumber numberWithInteger:i]];
    
    [[NSUserDefaults standardUserDefaults] setObject:advices forKey:@"AvailableAdvices"];
}
// *********************************************************************************


// ******************************************************** CALCULATE ADVICE ID
-(int) calculateAdviceID
{
    NSArray *advicesImutable = [[NSUserDefaults standardUserDefaults] objectForKey:@"AvailableAdvices"];
    NSMutableArray *advices = [advicesImutable mutableCopy];
    
    // get number of advices and a random index
    int number_of_advices = (int) [advices count];
    int advice_index = arc4random_uniform(number_of_advices);
    
    // get the actual advice id
    int adviceID = [[advices objectAtIndex:advice_index] intValue];
    
    NSLog(@"# Advice ID = %d",adviceID);
    
    // remove the advice id
    [advices removeObjectAtIndex:advice_index];
    
    int number_of_advices_after_removal = (int) [advices count];
    
    NSLog(@"# Advices array after removal is: ");
    printf("[");
    for (NSNumber *item in advices)
        printf("%d ",[item intValue]);
    printf("]\n");
    
    if (number_of_advices_after_removal == 0)
        [self initializeAdvicesArray];
    else [[NSUserDefaults standardUserDefaults] setObject:advices forKey:@"AvailableAdvices"];
    
    return adviceID;
}
// *********************************************************************************


// ******************************************************** CALCULATE QUOTE ID
-(int) calculateQuoteID
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:[NSDate date]];
    
    // store the current calendar day, hour, min
    int current_calendar_day = (int) [components day];
    int current_hour = (int) [components hour];
    int current_min = (int) [components minute];
    NSLog(@"# Current calendar day = %d",current_calendar_day);
    NSLog(@"# Current calendar hour = %d", current_hour);
    NSLog(@"# Current calendar min = %d", current_min);
    
    // get the user defaults
    int current_day = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentDay"];
    int current_quote_id = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentQuoteID"];
    int notification_hour = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"Hour"];
    int notification_min  = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"Minute"];
    bool secondTime = [[NSUserDefaults standardUserDefaults] boolForKey:@"SecondTime"];
    NSLog(@"# Current day = %d", current_day);
    NSLog(@"# Current quote id = %d", current_quote_id);
    NSLog(@"# Current notification hour = %d", notification_hour);
    NSLog(@"# Current notification min = %d", notification_min);
    NSLog(@"# Second time = %d",secondTime);
    
    int return_value = current_quote_id;
    
    // check if quote needs to be changed
    bool change_quote = FALSE;
    
    if([UIApplication sharedApplication].applicationIconBadgeNumber == 1 && (current_day != current_calendar_day) )
        change_quote = TRUE;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    if( (current_day != current_calendar_day) && (change_quote == FALSE) )
    {
        if ( (current_hour > notification_hour) || (current_hour == notification_hour && current_min >= notification_min) )
            change_quote = TRUE;
    }
    
    if(secondTime == FALSE && change_quote == FALSE)
        change_quote = TRUE;
    
    if(change_quote == TRUE)
    {
        
        NSArray *quotesImutable = [[NSUserDefaults standardUserDefaults] objectForKey:@"AvailableQuotes"];
        NSMutableArray *quotes = [quotesImutable mutableCopy];
        
        // get number of quotes and a random index
        int number_of_quotes = (int) [quotes count];
        int quote_index = arc4random_uniform(number_of_quotes);
        
        // get the actual quote id
        int quoteID = [[quotes objectAtIndex:quote_index] intValue];
        
        NSLog(@"# Next quote ID = %d",quoteID);
        
        // remove the quote id
        [quotes removeObjectAtIndex:quote_index];
        
        int number_of_quotes_after_removal = (int)[quotes count];
        
        NSLog(@"# Quotes array after removal is: ");
        printf("[");
        for (NSNumber *item in quotes)
            printf("%d ",[item intValue]);
        printf("]\n");
        
        NSLog(@"# Number of quotes after removal = %d", number_of_quotes_after_removal);
        
        if (number_of_quotes_after_removal == 0)
            [self initializeQuotesArray];
        else [[NSUserDefaults standardUserDefaults] setObject:quotes forKey:@"AvailableQuotes"];
        
        [[NSUserDefaults standardUserDefaults] setInteger:current_calendar_day forKey:@"CurrentDay"];
        [[NSUserDefaults standardUserDefaults] setInteger:quoteID forKey:@"CurrentQuoteID"];
        
        return_value = quoteID;
    }
    else NSLog(@"# Quote does not need to be changed");
    
    return return_value;
}
// *********************************************************************************

-(int) getDifferenceBetweenCurrentDateAndNotificationDate: (int)current_day : (int)notification_day
{
    int difference = 0;
    
    return difference;
}


// ******************************************************** SEND ALERT
-(void) sendAlert:(NSString*)alertTitle :(NSString*)alertContent :(bool)delay
{
    if(delay)
        [NSThread sleepForTimeInterval:0.1f];
    
    // send a confirmation alert
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:alertTitle
                                 message:alertContent
                                 preferredStyle:UIAlertControllerStyleAlert];
    // create color for toolbar
    UIColor *backgroundColorAlert = [UIColor colorWithRed:130.0f/255.0f
                                                    green:130.0f/255.0f
                                                     blue:130.0f/255.0f
                                                    alpha:1.0f];
    UIView *firstSubview = alert.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    for (UIView *subSubView in alertContentView.subviews) { //This is main catch
        subSubView.backgroundColor = backgroundColorAlert;//Here you change background
    }
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"I am successful"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   
                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                   _btnSave.enabled = TRUE;
                                   _btnClock.enabled = TRUE;
                                   _btnTwitter.enabled = TRUE;
                                   _btnInfo.enabled = TRUE;
                                   _btnFacebook.enabled = TRUE;
                                   _btnInfoBooksToolbar.enabled = TRUE;
                                   _btnInfoMoviesToolbar.enabled = TRUE;
                                   
                               }];
    
    [alert addAction:okButton];
    
    [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                             green:165.0f/255.0f
                                              blue:0.0f/255.0f
                                             alpha:1.0f]];
    
    [self presentViewController:alert animated:YES completion:nil];
}
// *********************************************************************************

// ******************************************************** CALCULATE FONT SIZE
-(int) calculateFontSize:(NSString*) quote
{
    int font_size = 30;
    BOOL result = FALSE;
    
    // create aux text view and assign the quote
    UITextView *aux_text_view = [[UITextView alloc] initWithFrame:_textQuote.frame];
    aux_text_view.text = quote;
    
    while(result == FALSE)
    {
        // create the font
        UIFont *textViewfont = [UIFont fontWithName:@"Noteworthy-Bold" size:font_size];
        aux_text_view.font = textViewfont;
        
       [self adjustContentSize:aux_text_view];
        
        // check if heigh needed by text is bigger than the height
        CGSize text_size = aux_text_view.contentSize;
        float height_needed_by_text = text_size.height;
        
        if(height_needed_by_text > aux_text_view.frame.size.height)
            font_size--;
        else
        {
            result = TRUE;
        }
    }
    
    return font_size;
}

// ******************************************************** SHOW INITIAL INTRO 1
-(void) showInitialIntro_1
{
    
    NSString *intro = @"I’m the creator of this app. I just turned 24. Two years ago, driven by the desire to have a better life, I bought a self development book. I discovered something incredible in that book: you are the creator of your own life. This is how My Road To Success started. From that day, I committed to constant learning and growing, no more complaining and blaming, taking full responsibility for all aspects of my life and helping other people too. I implemented new habits in my life like getting up early and doing something productive before going to work (learning/ programming/ working out). I am also spending more time with the loved ones and helping others. I cut most of the bad habits like watching TV, sleeping too much, spending too much time on social networks. Results showed up and today I have a way better life, I am super healthy, I have a strong relationship with my girlfriend, I got a great new job in programming and my earnings increased with 50% (compared to two years ago) which allowed me to donate even more. This is not something huge but I am just getting started and many more will come. I invite you to join me and many others in this adventure to create our own lives. Trust me, your life will never be the same.\n\n P.S.: A year from now you wish you had started today.";
    
    // send a confirmation alert
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Hi, my name is Gabriel Tarpian..."
                                 message:intro
                                 preferredStyle:UIAlertControllerStyleAlert];
    // create color for toolbar
    UIColor *backgroundColorAlert = [UIColor colorWithRed:130.0f/255.0f
                                                    green:130.0f/255.0f
                                                     blue:130.0f/255.0f
                                                    alpha:1.0f];
    UIView *firstSubview = alert.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    for (UIView *subSubView in alertContentView.subviews) { //This is main catch
        subSubView.backgroundColor = backgroundColorAlert;//Here you change background
    }
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"I am successful ->"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle okButton
                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                   [self showInitialIntro_2];
                                   
                               }];
    
    [alert addAction:okButton];
    
    [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                             green:165.0f/255.0f
                                              blue:0.0f/255.0f
                                             alpha:1.0f]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// ******************************************************** SHOW INITIAL INTRO 2
-(void) showInitialIntro_2
{
    NSString *intro = @"From now on, I will assist you in Your Road To Success. Before you start using this app, you should define what success means to you. Success is not what society think it is. Success is yours! Sit down and think about all areas of life (health, relationships, career, personal development, financial, giving). At the “Info” section in this app, you will find a mini-guide on how to clearly define what success means to you. If you haven't found your passion yet, don't worry! You're not alone! In this app you will find interesting definitions of success, hope it will help you create yours!\n\n Thank you for downloading the app, let's reach our goals together!";
    
    // send a confirmation alert
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Hey, successful! It's me, Roady ..."
                                 message:intro
                                 preferredStyle:UIAlertControllerStyleAlert];
    // create color for toolbar
    UIColor *backgroundColorAlert = [UIColor colorWithRed:130.0f/255.0f
                                                    green:130.0f/255.0f
                                                     blue:130.0f/255.0f
                                                    alpha:1.0f];
    UIView *firstSubview = alert.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    for (UIView *subSubView in alertContentView.subviews) { //This is main catch
        subSubView.backgroundColor = backgroundColorAlert;//Here you change background
    }
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"I am successful ->"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                   [self showInitialIntro_3];
                               }];
    
    [alert addAction:okButton];
    
    [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                             green:165.0f/255.0f
                                              blue:0.0f/255.0f
                                             alpha:1.0f]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// ******************************************************** SHOW INITIAL INTRO 3
-(void) showInitialIntro_3
{
    NSString *intro = @"Every time you open the app, I will give you an advice about life. I gathered these advices from the best life coaches and experts of the world and I really want to share them with you. Take advantage of them!\n\n Thank you for downloading the app, let's reach our goals together!";
    
    // send a confirmation alert
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Hey, successful! Roady here ..."
                                 message:intro
                                 preferredStyle:UIAlertControllerStyleAlert];
    // create color for toolbar
    UIColor *backgroundColorAlert = [UIColor colorWithRed:130.0f/255.0f
                                                    green:130.0f/255.0f
                                                     blue:130.0f/255.0f
                                                    alpha:1.0f];
    UIView *firstSubview = alert.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    for (UIView *subSubView in alertContentView.subviews) { //This is main catch
        subSubView.backgroundColor = backgroundColorAlert;//Here you change background
    }
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"I am successful ->"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                   [self showInitialIntro_4];
                               }];
    
    [alert addAction:okButton];
    
    [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                             green:165.0f/255.0f
                                              blue:0.0f/255.0f
                                             alpha:1.0f]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// ******************************************************** SHOW INITIAL INTRO 4
-(void) showInitialIntro_4
{
    NSString *intro = @"There is a small add at the bottom of the screen. It will not bother you and will not interfere with our content. If you have the possibility, please use our app with an active internet connection. 50% of the earnings will be donated to different charities. I thank you in advance for your nobility. \n\n Thank you for downloading the app, let's reach our goals together!";
    
    // send a confirmation alert
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Hey, successful! Roady on air ..."
                                 message:intro
                                 preferredStyle:UIAlertControllerStyleAlert];
    // create color for toolbar
    UIColor *backgroundColorAlert = [UIColor colorWithRed:130.0f/255.0f
                                                    green:130.0f/255.0f
                                                     blue:130.0f/255.0f
                                                    alpha:1.0f];
    UIView *firstSubview = alert.view.subviews.firstObject;
    UIView *alertContentView = firstSubview.subviews.firstObject;
    for (UIView *subSubView in alertContentView.subviews) { //This is main catch
        subSubView.backgroundColor = backgroundColorAlert;//Here you change background
    }
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"I am successful"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                   
                                   [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"InitialAdviceDisplayed"];
                                   
                                   // request access to photo library
                                   [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                                       switch (status) {
                                           case PHAuthorizationStatusAuthorized:
                                           case PHAuthorizationStatusRestricted:
                                           case PHAuthorizationStatusDenied:
                                           default:
                                           {
                                               // register user for notification settings
                                               UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                                               [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                                                                     completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                                                     }];
                                               break;
                                           }
                                               
                                       }
                                   }];
                               }];
    
    [alert addAction:okButton];
    
    [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                             green:165.0f/255.0f
                                              blue:0.0f/255.0f
                                             alpha:1.0f]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// ******************************************************** CANCEL NOTIFICATION HOUR
-(void) cancelNotificationHour
{
    _btnClock.enabled = TRUE;
    _toolbarNotification.hidden = YES;
    _datePickerNotification.hidden = YES;
    
    // check if device is iPhone X and apply the offset
    int iPhoneXOffset = 0;
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
    {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 2436:
                iPhoneXOffset = 30;
                break;
            default:
                break;
        }
    }
    
    // unhide animated main toolbar by setting its Y position to 0
    [UIView animateWithDuration:0.6
                     animations:^(void)
     {
         // hide right arrow
         CGRect toolbarFrame = self.mainToolbar.frame;
         toolbarFrame.origin.y = 0 + iPhoneXOffset;
         self.mainToolbar.frame = toolbarFrame;
     }
                     completion:^(BOOL finished)
     {
     }];
}
// *********************************************************************************

// ******************************************************** HIDE THE STATUS BAR (time, battery, etc)
-(BOOL)prefersStatusBarHidden{
    return NO;
}
// *********************************************************************************

// Objective C
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    return [[Twitter sharedInstance] application:app openURL:url options:options];
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    NSLog(@"completed");
    _btnFacebook.enabled = YES;
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    NSLog(@"fail %@",error.description);
    _btnFacebook.enabled = YES;
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    NSLog(@"cancel");
    _btnFacebook.enabled = YES;
}

- (UIImage*)takeScreenshot
{
    _mainToolbar.hidden = YES;
    _bannerView.hidden = YES;
    _shareToolbar.hidden = YES;
    
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    _mainToolbar.hidden = NO;
    _bannerView.hidden = NO;
    _shareToolbar.hidden = NO;
    
    return image;
}

// ******************************************************** CENTER TEXT VIEW VERTICALLY (quote)
-(void)adjustContentSize:(UITextView*)tv{
    CGFloat deadSpace = ([tv bounds].size.height - [tv contentSize].height);
    CGFloat inset = MAX(0, deadSpace/2.0);
    tv.contentInset = UIEdgeInsetsMake(inset, tv.contentInset.left, inset, tv.contentInset.right);
}
// *********************************************************************************

-(IBAction)shareQuoteButtonPressed:(id)sender
{
    int posXForMainToolbar = self.shareToolbar.frame.origin.x;
    int posYForMainToolbar = self.shareToolbar.frame.origin.y;
    
    int posXForShareToolbar = self.mainToolbar.frame.origin.x;
    int posYForShareToolbar = self.mainToolbar.frame.origin.y;
    
    // create animation
    [UIView animateWithDuration:0.6
                     animations:^(void)
     {
         // hide main toolbar
         CGRect mainToolbarFrame = self.mainToolbar.frame;
         mainToolbarFrame.origin.x = posXForMainToolbar;
         mainToolbarFrame.origin.y = posYForMainToolbar;
         self.mainToolbar.frame = mainToolbarFrame;
         
         // show share toolbar
         CGRect shareToolbarFrame = self.shareToolbar.frame;
         shareToolbarFrame.origin.x = posXForShareToolbar;
         shareToolbarFrame.origin.y = posYForShareToolbar;
         self.shareToolbar.frame = shareToolbarFrame;
     }
                     completion:^(BOOL finished)
     {
     }];
}

-(IBAction)arrowUpButtonPressed:(id)sender
{
    int posXForMainToolbar = self.shareToolbar.frame.origin.x;
    int posYForMainToolbar = self.shareToolbar.frame.origin.y;
    
    int posXForShareToolbar = self.mainToolbar.frame.origin.x;
    int posYForShareToolbar = self.mainToolbar.frame.origin.y;
    
    // create animation
    [UIView animateWithDuration:0.6
                     animations:^(void)
     {
         // hide share toolbar
         CGRect shareToolbarFrame = self.shareToolbar.frame;
         shareToolbarFrame.origin.x = posXForShareToolbar;
         shareToolbarFrame.origin.y = posYForShareToolbar;
         self.shareToolbar.frame = shareToolbarFrame;
         
         // show main toolbar
         CGRect mainToolbarFrame = self.mainToolbar.frame;
         mainToolbarFrame.origin.x = posXForMainToolbar;
         mainToolbarFrame.origin.y = posYForMainToolbar;
         self.mainToolbar.frame = mainToolbarFrame;
     }
                     completion:^(BOOL finished)
     {
         _btnShare.enabled = YES;
     }];
}

-(IBAction)whatsAppButtonPressed:(id)sender
{
    _btnPlus.enabled = NO;
    displayAdvice = FALSE;
    
    UIImage *img = [self takeScreenshot];
    NSMutableArray *activityItems= [NSMutableArray arrayWithObjects:img, nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
    {
        _btnPlus.enabled = TRUE;
    };
    
    activityViewController.excludedActivityTypes = @[UIActivityTypePostToFacebook,
                                                     UIActivityTypePostToTwitter,
                                                     UIActivityTypePostToWeibo,
                                                     UIActivityTypePrint,
                                                     UIActivityTypeCopyToPasteboard,
                                                     UIActivityTypeAssignToContact,
                                                     UIActivityTypeSaveToCameraRoll,
                                                     UIActivityTypeAddToReadingList,
                                                     UIActivityTypePostToFlickr,
                                                     UIActivityTypePostToVimeo,
                                                     UIActivityTypePostToTencentWeibo,
                                                     UIActivityTypeOpenInIBooks,
                                                     UIActivityTypeMessage];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

-(IBAction)booksButtonPressed:(id)sender
{
    _btnBooks.enabled = NO;
    [self makeBooksTableView];
    
    // create the animation
    [UIView animateWithDuration:0.6
                     animations:^(void)
     {
         // show booksToolbar
         CGRect booksToolbarFrame = self.booksToolbar.frame;
         booksToolbarFrame.origin.x = 0;
         self.booksToolbar.frame = booksToolbarFrame;
         
         // show tableView
         CGRect tableViewFrame = _booksTableView.frame;
         tableViewFrame.origin.x = 0;
         _booksTableView.frame = tableViewFrame;
     }
                     completion:^(BOOL finished)
     {
     }];
}

-(IBAction)moviesButtonPressed:(id)sender
{
    _btnMovies.enabled = NO;
    
    [self makeMoviesTableView];
    
    // create the animation
    [UIView animateWithDuration:0.6
                     animations:^(void)
     {
         // show moviesToolbar
         CGRect booksToolbarFrame = self.moviesToolbar.frame;
         booksToolbarFrame.origin.x = 0;
         self.moviesToolbar.frame = booksToolbarFrame;
         
         // show tableView
         CGRect tableViewFrame = _moviesTableView.frame;
         tableViewFrame.origin.x = 0;
         _moviesTableView.frame = tableViewFrame;
     }
                     completion:^(BOOL finished)
     {
     }];
}

-(void)makeBooksTableView
{
    // Get screen dimension
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    int height = screenRect.size.height;
    CGRect tableFrame = CGRectMake(width, 40, width, height - 40);
    
    _booksTableView = [[UITableView alloc]initWithFrame:tableFrame style:UITableViewStylePlain];
    
    _booksTableView.rowHeight = 80;
    _booksTableView.sectionHeaderHeight = 60;
    _booksTableView.sectionFooterHeight = 20;
    _booksTableView.scrollEnabled = YES;
    _booksTableView.showsVerticalScrollIndicator = YES;
    _booksTableView.userInteractionEnabled = YES;
    _booksTableView.bounces = YES;
    
    // tableview color
    _booksTableView.backgroundView = nil;
    _booksTableView.backgroundColor = [UIColor blackColor];
    
    _booksTableView.allowsSelection = NO;
    
    _booksTableView.delegate = self;
    _booksTableView.dataSource = self;
    
    [self.view addSubview:_booksTableView];
}

-(void) makeMoviesTableView
{
    // Get screen dimension
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int width = screenRect.size.width;
    int height = screenRect.size.height;
    CGRect tableFrame = CGRectMake(width, 40, width, height - 40);
    
    _moviesTableView = [[UITableView alloc]initWithFrame:tableFrame style:UITableViewStylePlain];
    
    _moviesTableView.rowHeight = 80;
    _moviesTableView.sectionHeaderHeight = 60;
    _moviesTableView.sectionFooterHeight = 20;
    _moviesTableView.scrollEnabled = YES;
    _moviesTableView.showsVerticalScrollIndicator = YES;
    _moviesTableView.userInteractionEnabled = YES;
    _moviesTableView.bounces = YES;
    
    // tableview color
    _moviesTableView.backgroundView = nil;
    _moviesTableView.backgroundColor = [UIColor blackColor];
    
    _moviesTableView.allowsSelection = NO;
    
    _moviesTableView.delegate = self;
    _moviesTableView.dataSource = self;
    
    [self.view addSubview:_moviesTableView];
}

// ########################################################################## table view specifics
#pragma mark - Table View Data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:
(NSInteger)section
{
    if( tableView == _booksTableView )
        return [_bookTitles count];
    else return [_moviesTitle count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    // Reuse and create cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // text color
    UIColor *textColor = [UIColor colorWithRed:255.0f/255.0f
                                         green:165.0f/255.0f
                                          blue:0.0f/255.0f
                                         alpha:1.0f];
    
    // Update cell data contents
    if( tableView == _booksTableView)
    {
        cell.textLabel.text = [_bookTitles objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = [_bookAuthors objectAtIndex:indexPath.row];
    }
    else
    {
        cell.textLabel.text = [_moviesTitle objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = [_moviesYear objectAtIndex:indexPath.row];
    }

    
    
    cell.backgroundColor = [UIColor blackColor];
    cell.textLabel.textColor = textColor;
    cell.detailTextLabel.textColor = textColor;
    
    // wrap text
    
    // set text label X position
    [cell setIndentationLevel:5];
    
    // create the font
    UIFont *textLabelFont;
    if( iphoneSE )
        textLabelFont = [UIFont fontWithName:@"Noteworthy-Bold" size:17];
    else textLabelFont = [UIFont fontWithName:@"Noteworthy-Bold" size:21];
    
    UIFont *detailedTextLabelFont;
    if( iphoneSE )
        detailedTextLabelFont = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
    else detailedTextLabelFont = [UIFont fontWithName:@"Noteworthy-Bold" size:17];
    
    cell.textLabel.font = textLabelFont;
    cell.detailTextLabel.font = detailedTextLabelFont;
    
    // Create image
    UIImageView *imv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 80)];
    if( tableView == _booksTableView )
    {
        imv.image=[UIImage imageNamed:[_bookImages objectAtIndex:indexPath.row]];
    }
    else imv.image=[UIImage imageNamed:[_moviesImages objectAtIndex:indexPath.row]];
    
    [cell addSubview:imv];
    
    return cell;
}

-(void)initializeBooksAndMovies
{
    _bookTitles = @[@"Secrets of the Millionaire Mind",
                    @"Think and Grow Rich",
                    @"Attitude is Everything",
                    @"Over the Top",
                    @"The Alchemist", // 5
                    @"The Leader Who Had No Title",
                    @"The Monk Who Sold His Ferrari",
                    @"A New Earth",
                    @"The Power of Now",
                    @"Life Without Limits", // 10
                    @"Way of the Peaceful Warrior", // 11
                    @"Rich Dad Poor Dad", // 12
                    @"Cashflow Quadrant", // 13
                    @"The Richest Man in Babylon", // 14
                    @"Emotional Intelligence", //15
                    @"Awaken the Giant Within", // 16
                    @"Unshakeable", // 17
                    @"Money: Master the Game", // 18
                    @"Unlimited Power", // 19
                    @"How Successful People Think", // 20
                    @"Make Today Count", // 21
                    @"The Diamond Cutter", // 22
                    @"The Karma of Love", // 23
                    @"The Secret", // 24
                    @"Eat That Frog", // 25
                    @"Maximum Achievement", // 26
                    @"Drumul tau catre succes", // 27
                    @"De la gradinar la business coach", // 28
                    @"Obiceiuri care fac toti banii", // 29
                    @"WOW Now" // 30
                   ];
    
    _bookAuthors = @[@"T. Harv Ekker",
                     @"Napoleon Hill",
                     @"Jeff Keller",
                     @"Zig Ziglar",
                     @"Paulo Coelho",
                     @"Robin Sharma",
                     @"Robin Sharma",
                     @"Eckhart Tolle",
                     @"Eckhart Tolle",
                     @"Nick Vujicic",
                     @"Dan Millman",
                     @"Robert T. Kiyosaki",
                     @"Robert T. Kiyosaki",
                     @"George S. Clason",
                     @"Daniel Goleman",
                     @"Tony Robbins",
                     @"Tony Robbins",
                     @"Tony Robbins",
                     @"Tony Robbins",
                     @"John C. Maxwell",
                     @"John C. Maxwell",
                     @"Geshe M. Roach and Christie McNally",
                     @"Geshe Michael Roach",
                     @"Rhonda Byrne",
                     @"Brian Tracy",
                     @"Brian Tracy",
                     @"Lorand Szasz and Brian Tracy",
                     @"Lorand Soares Szasz",
                     @"Liviu Pasat",
                     @"Florin Pasat"
                   ];
    
    _bookImages = @[@"SOTMM.png",
                    @"TAGR.png",
                    @"AIE.png",
                    @"OTT.png",
                    @"TA.png",
                    @"TLWHNT.png",
                    @"TMWSHF.png",
                    @"ANE.png",
                    @"TPON.png",
                    @"LWL.png",
                    @"WOTPW.png",
                    @"RDPD.png",
                    @"CQ.png",
                    @"TRMIB.png",
                    @"EI.png",
                    @"ATGW.png",
                    @"U.png",
                    @"MMTG.png",
                    @"UP.png",
                    @"HSPT.png",
                    @"MTC.png",
                    @"TDC.png",
                    @"TKOL.png",
                    @"TS.png",
                    @"ETF.png",
                    @"MA.png",
                    @"DTCS.png",
                    @"DLGLBC.png",
                    @"OCFTB.png",
                    @"WN.png"
                    ];
    
    _moviesTitle = @[@"The Pursuit of Happyness", // 1
                     @"Pay It Forward", // 2
                     @"Facing the Giants", // 3
                     @"Moneyball", // 4
                     @"Coach Carter", // 5
                     @"August Rush", // 6
                     @"The Green Mile", //7
                     @"Forrest Gump", // 8
                     @"The Shawshank Redemption", // 9
                     @"A Beautiful Mind", // 10
                     @"The Bucket List", // 11
                     @"The King's Speech", // 12
                     @"Peaceful Warrior", // 13
                     @"Gridiron Gang", // 14
                     @"Good Will Hunting", // 15
                     @"Cinderella Man", // 16
                     @"The Longest Yard", // 17
                     @"The Guardian", // 18
                     @"Million Dollar Baby", // 19
                     @"Soul Surfer", // 20
                     @"Remember the Titans", // 21
                     @"We Are Marshall", // 22
                     @"The Blind Side", // 23
                     @"Forever Strong", // 24
                     @"The Theory of Everything", // 25
                     @"Rush", // 26
                     @"Schindler's List", // 27
                     @"127 Hours", // 28
                     @"Invictus", // 29
                     @"Invincible", // 30
                     @"Hacksaw Ridge", // 31
                     @"Fury", // 32
                     @"Coco" // 33
                     ];
    
    _moviesYear = @[@"2006",
                    @"2000",
                    @"2006",
                    @"2011",
                    @"2005",
                    @"2007",
                    @"1999",
                    @"1994",
                    @"1994",
                    @"2001",
                    @"2007",
                    @"2010",
                    @"2006",
                    @"2006",
                    @"1997",
                    @"2005",
                    @"2005",
                    @"2006",
                    @"2004",
                    @"2011",
                    @"2000",
                    @"2006",
                    @"2009",
                    @"2008",
                    @"2014",
                    @"2013",
                    @"1993",
                    @"2010",
                    @"2009",
                    @"2006",
                    @"2016",
                    @"2014",
                    @"2017"
                    ];
    
    _moviesImages = @[@"M_TPOH.png",
                      @"M_PIF.png",
                      @"M_FTG.png",
                      @"M_M.png",
                      @"M_CC.png",
                      @"M_AR.png",
                      @"M_TGM.png",
                      @"M_FG.png",
                      @"M_TSR.png",
                      @"M_ABM.png",
                      @"M_TBL.png",
                      @"M_TKS.png",
                      @"M_PW.png",
                      @"M_GG.png",
                      @"M_GWH.png",
                      @"M_CM.png",
                      @"M_TLY.png",
                      @"M_TG.png",
                      @"M_MDB.png",
                      @"M_SS.png",
                      @"M_RTT.png",
                      @"M_WAM.png",
                      @"M_TBS.png",
                      @"M_FS.png",
                      @"M_TTOE.png",
                      @"M_R.png",
                      @"M_SL.png",
                      @"M_127H.png",
                      @"M_I.png",
                      @"M_II.png",
                      @"M_HR.png",
                      @"M_F.png",
                      @"M_C.png"
                      ];
}
@end
