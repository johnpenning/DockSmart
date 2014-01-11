//
//  DockSmartSettingsViewController.m
//  DockSmart
//
//  Created by John Penning on 5/25/13.
//  Copyright (c) 2013 John Penning. All rights reserved.
//

#import "DockSmartLogViewController.h"

// NSNotification name for sending a log to the text view
NSString *kLogToTextViewNotif = @"LogToTextViewNotif";

// NSNotification userInfo key for obtaining the log text
NSString *kLogTextKey = @"LogTextKey";

@interface DockSmartLogViewController ()

@property (nonatomic, copy) NSString* preloadText;

- (void)logToTextView:(NSNotification*)notif;

@end

@implementation DockSmartLogViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

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
    [super viewDidUnload];
}

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
