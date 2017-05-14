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

// used for random number generator
#include <time.h>
#include <stdlib.h>

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
    
    // generate a random number between 1 and 14 which represents the quote id
    int quoteId = arc4random_uniform(14) + 1;
    
    NSString *imageName = [[DBManager getSharedInstance] getCategoryByID:quoteId];
    
    // Create wallpaper
    UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    UIImage *image = [UIImage imageNamed:imageName];
    imageHolder.image = image;
    
    // create black overlay
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]];
    [imageHolder addSubview:overlay];
    [self.view addSubview:imageHolder];
    
    // create toolbars
    [self vCreateToolbars:width];
    
    // creating the quote text label
    int labelPosX = 5;
    int labelPosY = height / 10;
    int labelWidth = width - labelPosX * 2;
    int labelHeight = height - labelPosY * 2;
    _textQuote = [[UITextView alloc]initWithFrame:CGRectMake(labelPosX, labelPosY,labelWidth,labelHeight)];
    
    // get quote, author and create the final string
    NSString *quote = [[DBManager getSharedInstance] getQuoteByID:quoteId];
    NSString *author = [[DBManager getSharedInstance] getAuthorByID:quoteId];
    NSString *finalString = [NSString stringWithFormat:@"%@\n\n%@", quote, author];
    
    // create the font
    UIFont *textViewfont = [UIFont fontWithName:@"Noteworthy-Bold" size:25];
    
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
    
    // Get if this is the first time of running the app
    BOOL boSecondTime = [[NSUserDefaults standardUserDefaults] boolForKey:@"SecondTime"];
    if(boSecondTime == NO)
    {
        // create push notification when running app for first time
        [self createPushNotification:9 m:0 boAlert:NO];
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"SecondTime"];
    }
    
    // create positions for copyright text
    int textPosX = width - 120;
    int textPosY;
    if( height < 500)
        textPosY =  height - 35; // Air, Air 2, Pro ( 9.7 ),
    else textPosY = height - 40;
    int textWidth = width - textPosX;
    int textHeight = height - textPosY;
    _textAuthor = [[UITextView alloc]initWithFrame:CGRectMake(textPosX, textPosY,textWidth,textHeight)];
    
    // create the author text
    NSString *textCopyright = [NSString stringWithFormat:@"Be A Success\n%cGabriel Tarpian",169];
    _textAuthor.text = textCopyright;
    UIFont *textAuthorFont = [UIFont fontWithName:@"Noteworthy-Bold" size:10];
    _textAuthor.font = textAuthorFont;
    _textAuthor.textAlignment = NSTextAlignmentRight;
    _textAuthor.backgroundColor = [UIColor clearColor];
    _textAuthor.textColor = textColor;
    [_textAuthor setUserInteractionEnabled:NO];
    
    // create the banner
    int bannerPosX = 0;
    int bannerPosY = self.textQuote.frame.origin.y + self.textQuote.frame.size.height;
    int bannerWidth = width;
    int bannerHeight = height - bannerPosY;
    
    // create the banner view
    _bannerView = [[GADBannerView alloc]initWithFrame:CGRectMake(bannerPosX, bannerPosY,bannerWidth,bannerHeight)];
    
    self.bannerView.adUnitID = @"ca-app-pub-7014753020131070/3584035347";
    self.bannerView.rootViewController = self;
    GADRequest *request = [GADRequest request];
    
    // this is used only for testing the device
    request.testDevices = @[ @"4892eadeb8eaff1d5ecc53641d4e6cfe" ];
    
    [self.bannerView loadRequest:request];
    
    // add components to main view
    [self.view addSubview:_textQuote];
    [self.view addSubview:_textAuthor];
    [self.view addSubview:_bannerView];
    
    // display the initial animation
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
    // create the intro toolbar
    _rightArrowToolbar = [[UIToolbar alloc]init];
    _rightArrowToolbar.frame = CGRectMake(0, 0, width, 40);
    
    // ************* Settings button
    UIImage *imgArrowRight = [UIImage imageNamed:@"Settings.png"];
    
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
    _mainToolbar.frame = CGRectMake(-width, 0, width, 40);
    
    // ************* Right arrow button
    UIImage *imgArrowLeft = [UIImage imageNamed:@"arrowLeft.png"];
    
    UIButton *btnArrowLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnArrowLeft addTarget:self action:@selector(showArrowToolbar:) forControlEvents:UIControlEventTouchUpInside];
    btnArrowLeft.bounds = CGRectMake( 0, 5, 25, 25 );
    [btnArrowLeft setImage:imgArrowLeft forState:UIControlStateNormal];
    [btnArrowLeft setShowsTouchWhenHighlighted:TRUE];
    _barBtnArrowLeft = [[UIBarButtonItem alloc] initWithCustomView:btnArrowLeft];
    
    // ************* Settings button
    UIImage *imgSettings = [UIImage imageNamed:@"Clock.png"];
    
    UIButton *btnSettings = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSettings addTarget:self action:@selector(changeNotificationTime:) forControlEvents:UIControlEventTouchUpInside];
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
    btnFacebook.bounds = CGRectMake( 200, 5, 32, 32 );
    [btnFacebook setImage:imgFacebook forState:UIControlStateNormal];
    [btnFacebook setShowsTouchWhenHighlighted:TRUE];
    _barBtnFacebook = [[UIBarButtonItem alloc] initWithCustomView:btnFacebook];
    
    // ************ Twitter button
    UIImage *imgTwitter = [UIImage imageNamed:@"twitter.png"];
    
    UIButton *btnTwitter = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnTwitter addTarget:self action:@selector(twitterButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    btnTwitter.bounds = CGRectMake( 300, 5, 27, 27 );
    [btnTwitter setImage:imgTwitter forState:UIControlStateNormal];
    [btnTwitter setShowsTouchWhenHighlighted:TRUE];
    _barBtnTwitter = [[UIBarButtonItem alloc] initWithCustomView:btnTwitter];
    
    // make visible items on the toolbar
    UIBarButtonItem *flexibleSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *items2 = [NSArray arrayWithObjects: _barBtnArrowLeft, flexibleSpace2, _barBtnSettings, flexibleSpace2, _barBtnSave,flexibleSpace2,  _barBtnFacebook, flexibleSpace2,  _barBtnTwitter, nil];
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
    
    [self.view addSubview:_rightArrowToolbar];
    [self.view addSubview:_mainToolbar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// ******************************************************** CHANGE NOTIFICATION TIME BUTTON PRESSED
-(IBAction)changeNotificationTime:(id)sender
{
    NSLog(@"Settings button is pressed \n");
    
    // set up the date picker
    _datePickerNotification = [[UIDatePicker alloc] init];
    _datePickerNotification.datePickerMode = UIDatePickerModeTime;
    _datePickerNotification.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _datePickerNotification.frame = CGRectMake(0,400, self.view.frame.size.width, self.view.frame.size.height - 400);
    
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
    
    UIBarButtonItem* notifButton = [[UIBarButtonItem alloc] initWithTitle:@"Notification hour" style:UIBarButtonItemStyleDone target:self action:nil];
    [notifButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor orangeColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
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

// ******************************************************** NOTIFICATION HOUR CHANGED
-(void) notificationHourChanged
{
    NSLog(@"Notification hour changed");
    int currentHour = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"Hour"];
    int currentMinute  = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"Minute"];
    
    
    // get the date stored in _dateNotification
    NSDate *notificationDate = [_datePickerNotification date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:notificationDate];
    int nextHour = (int) [components hour];
    int nextMinute = (int) [components minute];
    
    if(currentHour != nextHour || currentMinute != nextMinute)
    {
        NSLog(@"Notification time changed from %02d:%02d to %02d:%02d \n", currentHour, currentMinute,nextHour,nextMinute);
        [self createPushNotification:nextHour m:nextMinute boAlert:YES];
    }
    
    _toolbarNotification.hidden = YES;
    _datePickerNotification.hidden = YES;
}
// *********************************************************************************

// ******************************************************** CREATE PUSH NOTIFICATION
-(void) createPushNotification:(int)hour m:(int)minute boAlert:(BOOL)alert
{
    // first of all, cancel all notifications
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
    
    NSDate *now = [NSDate date];
    NSCalendar *calendarN = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    // create the date from today at the desired hour
    NSDateComponents *componentsN = [calendarN components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    [componentsN setHour:hour];
    [componentsN setMinute:minute];
    
    // create the LocalNotification
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.hour = hour;
    dateComponents.minute = minute;
    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:YES];
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString localizedUserNotificationStringForKey:@"A new quote is available" arguments:nil];
    content.body = [NSString localizedUserNotificationStringForKey:@"Open the app to see it"
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
            
            NSLog(@"NotificationRequest succeeded!\n");
            
            // store the hour and the minute
            [[NSUserDefaults standardUserDefaults]setInteger:hour forKey:@"Hour"];
            [[NSUserDefaults standardUserDefaults]setInteger:minute forKey:@"Minute"];
            
            // send a confirmation alert only the current notification is not the default notification
            if( alert == YES )
            {
                NSString *message = [[NSString alloc]init];
                
                if(hour < 10 && minute < 10)
                    message = [NSString stringWithFormat:@"Notification time changed successfully to %02d:%02d",hour,minute];
                
                if(hour > 9 && minute > 9)
                    message = [NSString stringWithFormat:@"Notification time changed successfully to %d:%d", hour, minute];
                
                if(hour < 10 && minute > 9)
                    message = [NSString stringWithFormat:@"Notification time changed successfully to %02d:%d",hour,minute];
                
                if(hour > 9 && minute < 10)
                    message = [NSString stringWithFormat:@"Notification time changed successfully to %d:%02d",hour,minute];
                
                // send a confirmation alert
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:@"Confirmation"
                                             message:message
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
                                           actionWithTitle:@"Great"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               //Handle no, thanks button
                                           }];
                
                [alert addAction:okButton];
                [self presentViewController:alert animated:YES completion:nil];
                [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                                         green:165.0f/255.0f
                                                          blue:0.0f/255.0f
                                                         alpha:1.0f]];
            }
            
        }
        else
        {
            NSLog(@"NotificationRequest failed!\n");
            
            // send a confirmation alert
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Confirmation"
                                         message:@"Failed to change the notification time. Please try again"
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
                                       actionWithTitle:@"OK"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           //Handle no, thanks button
                                       }];
            
            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
            [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                                     green:165.0f/255.0f
                                                      blue:0.0f/255.0f
                                                     alpha:1.0f]];
            
            
        }
    }];
    
}
// *********************************************************************************

// ******************************************************** SAVE BUTTON PRESSED
-(IBAction)saveButtonPressed:(id)sender
{
    NSLog(@"Save button is pressed \n");
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(self.view.bounds.size);
    }
    
    _mainToolbar.hidden = YES;
    _bannerView.hidden = YES;
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _mainToolbar.hidden = NO;
    _bannerView.hidden = NO;
    
    NSData *imageData = UIImagePNGRepresentation(image);
    if (imageData)
    {
        //[imageData writeToFile:@"screenshot.png" atomically:YES];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        NSLog(@"Imaged saved succesfully \n");
        
        // send a confirmation alert
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Confirmation"
                                     message:@"Photo saved successfully. Please check your gallery"
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
                                   actionWithTitle:@"Great"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                                 green:165.0f/255.0f
                                                  blue:0.0f/255.0f
                                                 alpha:1.0f]];
    }
    else
    {
        NSLog(@"error while taking screenshot");
        
        // send a confirmation alert
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Error while saving the photo. Please try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                                 green:165.0f/255.0f
                                                  blue:0.0f/255.0f
                                                 alpha:1.0f]];
    }
}
// *********************************************************************************

// ******************************************************** FACEBOOK BUTTON PRESSED
-(IBAction)facebookButtonPressed:(id)sender
{
    NSLog(@"Facebook button is pressed\n");
    
    // get current quote screenshot
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(self.view.bounds.size);
    }
    
    _mainToolbar.hidden = YES;
    _bannerView.hidden = YES;
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _mainToolbar.hidden = NO;
    _bannerView.hidden = NO;
    
    // post on facebook
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *facebookShare = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        NSString *shareText = @"Quote of the day by 'BeASuccess' app! #BeASuccess";
        [facebookShare setInitialText:shareText];
        [facebookShare addImage:image];
        
        [facebookShare setCompletionHandler:^(SLComposeViewControllerResult result)
         {
             
             switch (result) {
                 case SLComposeViewControllerResultCancelled:
                     NSLog(@"Post Canceled");
                     break;
                 case SLComposeViewControllerResultDone:
                     NSLog(@"Post Sucessful");
                     break;
                 default:
                     break;
             }
             
             [self dismissViewControllerAnimated:YES completion:nil];
         }];
        
        [self presentViewController:facebookShare animated:YES completion:nil];
    }
    else
    {
        NSLog(@"Facebook app not installed");
        
        // send a confirmation alert
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Error while connecting to your Facebook account. Please try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                                 green:165.0f/255.0f
                                                  blue:0.0f/255.0f
                                                 alpha:1.0f]];
    }
}
// *********************************************************************************

// ******************************************************** TWITTER BUTTON PRESSED
-(IBAction)twitterButtonPressed:(id)sender
{
    NSLog(@"Twitter button is pressed\n");
    
    // get current quote screenshot
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(self.view.bounds.size);
    }
    
    _mainToolbar.hidden = YES;
    _bannerView.hidden = YES;
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _mainToolbar.hidden = NO;
    _bannerView.hidden = NO;
    
    // post on twitter
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        
        NSString *shareText = @"Quote of the day by 'BeASuccess' app! #BeASuccess";
        [tweet setInitialText:shareText];
        [tweet addImage:image];
        
        [tweet setCompletionHandler:^(SLComposeViewControllerResult result)
         {
             
             switch (result) {
                 case SLComposeViewControllerResultCancelled:
                     NSLog(@"Post Canceled");
                     break;
                 case SLComposeViewControllerResultDone:
                     NSLog(@"Post Sucessful");
                     break;
                 default:
                     break;
             }
             
             // [self dismissViewControllerAnimated:YES completion:nil];
         }];
        
        [self presentViewController:tweet animated:YES completion:nil];
    }
    
    else
    {
        NSLog(@"Twitter app not installed");
        
        // send a confirmation alert
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Error while connecting to your Twitter account. Please try again"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        [alert.view setTintColor:[UIColor colorWithRed:255.0f/255.0f
                                                 green:165.0f/255.0f
                                                  blue:0.0f/255.0f
                                                 alpha:1.0f]];
    }
}
// *********************************************************************************

// ******************************************************** CANCEL NOTIFICATION HOUR
-(void) cancelNotificationHour
{
    NSLog(@"Notification hour canceled \n");
    
    _toolbarNotification.hidden = YES;
    _datePickerNotification.hidden = YES;
}
// *********************************************************************************

// ******************************************************** HIDE THE STATUS BAR (time, battery, etc)
-(BOOL)prefersStatusBarHidden{
    return NO;
}
// *********************************************************************************

// ******************************************************** CENTER TEXT VIEW VERTICALLY (quote)
-(void)adjustContentSize:(UITextView*)tv{
    CGFloat deadSpace = ([tv bounds].size.height - [tv contentSize].height);
    CGFloat inset = MAX(0, deadSpace/2.0);
    tv.contentInset = UIEdgeInsetsMake(inset, tv.contentInset.left, inset, tv.contentInset.right);
}
// *********************************************************************************

@end
