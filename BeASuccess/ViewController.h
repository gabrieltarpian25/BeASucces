//
//  ViewController.h
//  BeASuccess
//
//  Created by Tarpian Gabriel Lucian on 30/01/2017.
//  Copyright © 2017 Tarpian Gabriel Lucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

// Google ads
@import GoogleMobileAds;
@class GADBannerView;

///    Notification become independent from UIKit
@import UserNotifications;

@interface ViewController : UIViewController <ADBannerViewDelegate>

// text for displaying the quote and text for displaying the copyright
@property (nonatomic, strong) IBOutlet UITextView  *textQuote;
@property (nonatomic, strong) IBOutlet UITextView  *textAuthor;

// test property for ad banner
@property (nonatomic, strong) IBOutlet GADBannerView  *bannerView;

// toolbar that contains the buttons for notificationTime, saving the photo, sharing, info
@property (nonatomic, strong) IBOutlet UIToolbar         *mainToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnArrowLeft;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnClock;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnSave;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnShare;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnBooks;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnMovies;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnInfo;

// toolbar that contains the right arrow
@property (nonatomic, strong) IBOutlet UIToolbar         *rightArrowToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnSettings;

// toolbar
@property (nonatomic, strong) IBOutlet UIToolbar         *shareToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnArrowUp;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnFacebook;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnTwitter;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnPlus;

@property (nonatomic, strong) IBOutlet UIDatePicker      *datePickerNotification;
@property (nonatomic, strong) IBOutlet UIToolbar         *toolbarNotification;

// buttons used in toolbar
@property (nonatomic, strong) UIButton *btnSave;
@property (nonatomic, strong) UIButton *btnClock;
@property (nonatomic, strong) UIButton *btnFacebook;
@property (nonatomic, strong) UIButton *btnTwitter;
@property (nonatomic, strong) UIButton *btnInfo;
@property (nonatomic, strong) UIButton *btnShare;
@property (nonatomic, strong) UIButton *btnArrowUp;
@property (nonatomic, strong) UIButton *btnPlus;
@property (nonatomic, strong) UIButton *btnBooks;
@property (nonatomic, strong) UIButton *btnMovies;

// used for creating the screenshot image
@property (nonatomic, strong) NSMutableString *strQuoteAndAuthor;
@property  int fontSize;
@property (nonatomic, strong) UIImageView *imageHolder;

// sharing photo on whatsapp
@property (retain) UIDocumentInteractionController * documentInteractionController;

// recommended books toolbar
@property (nonatomic, strong) IBOutlet UIToolbar         *booksToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnHideBooksToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnInfoBooksToolbar;
@property (nonatomic, strong) UIButton *btnHideBooksToolbar;
@property (nonatomic, strong) UIButton *btnInfoBooksToolbar;

@property (nonatomic, strong) UITableView *booksTableView;

// recommended movies toolbar
@property (nonatomic, strong) IBOutlet UIToolbar         *moviesToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnHideMoviesToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem   *barBtnInfoMoviesToolbar;
@property (nonatomic, strong) UIButton *btnHideMoviesToolbar;
@property (nonatomic, strong) UIButton *btnInfoMoviesToolbar;

@property (nonatomic, strong) UITableView *moviesTableView;

@end

