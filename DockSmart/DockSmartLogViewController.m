//
//  DockSmartLogViewController.m
//  DockSmart
//
//  View to display a running debug log in the app, on a separate tab. Only for testing purposes.
//
//  Created by John Penning on 5/25/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "DockSmartLogViewController.h"

// NSNotification name for sending a log to the text view
NSString * const kLogToTextViewNotif = @"LogToTextViewNotif";

// NSNotification userInfo key for obtaining the log text
NSString * const kLogTextKey = @"LogTextKey";

@interface DockSmartLogViewController ()

//String to store text that needs to be logged in the text view as soon as the view is first loaded.
@property (nonatomic, copy) NSString* preloadText;

- (void)logToTextView:(NSNotification*)notif;

@end

@implementation DockSmartLogViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logToTextView:)
                                                 name:kLogToTextViewNotif
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //TODO: if we care before deleting this debug view, fix the top/bottom insets due to the status bar and tab bar
    self.automaticallyAdjustsScrollViewInsets = YES;

    NSString *oldText = [self.settingsTextView text];
    [self.settingsTextView setText:[NSString stringWithFormat:@"%@\n%@", oldText, self.preloadText]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setSettingsTextView:nil];
    [self setPreloadText:nil];
    [super viewDidUnload];
}

//Log text to the text view, adding it to the bottom of the text that has already been logged.
- (void)logToTextView:(NSNotification*)notif
{
    NSString *oldText = [self.settingsTextView text];
    NSString *newText = [[notif userInfo] valueForKey:kLogTextKey];
    if ([self isViewLoaded])
        [self.settingsTextView setText:[NSString stringWithFormat:@"%@\n%@ %@", oldText, [NSDate date], newText]];
    else
    {
        self.preloadText = [NSString stringWithFormat:@"%@\n%@ %@", self.preloadText, [NSDate date], newText];
    }
}

#pragma mark - State Restoration

- (void)applicationFinishedRestoringState
{
    //Called on restored view controllers after other object decoding is complete.
    
    
}

@end
