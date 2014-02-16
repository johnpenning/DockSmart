//
//  DockSmartSettingsViewController.h
//  DockSmart
//
//  Created by John Penning on 5/25/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kLogToTextViewNotif;
extern NSString * const kLogTextKey;

@interface DockSmartLogViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *settingsTextView;

@end
