//
//  ViewController.h
//  BeASuccess
//
//  Created by Tarpian Gabriel Lucian on 30/01/2017.
//  Copyright © 2017 Tarpian Gabriel Lucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

///    Notification become independent from UIKit
@import UserNotifications;

@interface ViewController : UIViewController <ADBannerViewDelegate>

// text for displaying the quote and text for displaying the copyright
@property (nonatomic, strong) IBOutlet UITextView  *textQuote;
@property (nonatomic, strong) IBOutlet UITextView  *textAuthor;

// bar buttons for main toolbar
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnSettings;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnSave;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnFacebook;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnTwitter;

// bar buttons for right arrow toolbar
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnArrowRight;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnArrowLeft;

// toolbar that contains the buttons for saving the quote, sharing it on facebook, notification time, etc
@property (nonatomic, strong) IBOutlet UIToolbar         *mainToolbar;

// toolbar that contains the right arrow
@property (nonatomic, strong) IBOutlet UIToolbar         *rightArrowToolbar;

@property (nonatomic, strong) IBOutlet UIDatePicker      *datePickerNotification;
@property (nonatomic, strong) IBOutlet UIToolbar         *toolbarNotification;


@end

