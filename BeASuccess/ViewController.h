//
//  ViewController.h
//  BeASuccess
//
//  Created by Tarpian Gabriel Lucian on 30/01/2017.
//  Copyright © 2017 Tarpian Gabriel Lucian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, retain) IBOutlet UITextView  *textQuote;
@property (nonatomic, retain) IBOutlet UITextView  *textAuthor;

// bar buttons for main toolbar
@property (nonatomic, retain) IBOutlet UIBarButtonItem   *barBtnSettings;
@property (nonatomic, retain) IBOutlet UIBarButtonItem   *barBtnSave;
@property (nonatomic, retain) IBOutlet UIBarButtonItem   *barBtnFacebook;

// bar buttons for right arrow toolbar
@property (nonatomic, retain) IBOutlet UIBarButtonItem   *barBtnArrowRight;
@property (nonatomic, retain) IBOutlet UIBarButtonItem   *barBtnArrowLeft;

// toolbar that contains the buttons for saving the quote, sharing it on facebook, notification time, etc
@property (nonatomic, retain) IBOutlet UIToolbar         *mainToolbar;

// toolbar that contains the right arrow
@property (nonatomic, retain) IBOutlet UIToolbar         *rightArrowToolbar;

@property (nonatomic, retain) IBOutlet UIDatePicker      *datePickerNotification;
@property (nonatomic, retain) IBOutlet UIToolbar         *toolbarNotification;

@end

