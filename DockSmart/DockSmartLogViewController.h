//
//  DockSmartLogViewController.h
//  DockSmart
//
//  View to display a running debug log in the app, on a separate tab. Only for testing purposes.
//
//  Created by John Penning on 5/25/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>

// NSNotification name for sending a log to the text view
extern NSString * const kLogToTextViewNotif;
// NSNotification userInfo key for obtaining the log text
extern NSString * const kLogTextKey;

@interface DockSmartLogViewController : UIViewController

//text view where log data is displayed
@property (weak, nonatomic) IBOutlet UITextView *settingsTextView;

@end
