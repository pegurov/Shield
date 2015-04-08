//
//  LogViewController.m
//  SHIELD
//
//  Created by Pavel Gurov on 06/04/15.
//  Copyright (c) 2015 Andrey Ogrenich. All rights reserved.
//

#import "LogViewController.h"

@interface LogViewController () <BTManagerDelegate, ShieldDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textViewLog;
@property (weak, nonatomic) IBOutlet UITextField *textFieldASCIICommand;
@property (weak, nonatomic) IBOutlet UITextField *textFieldHEXCommand;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControlMode;

- (IBAction)modeChanged:(UISegmentedControl *)sender;
- (IBAction)closeKeyboardTap:(UIButton *)sender;

@end

@implementation LogViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.title = @"Log";
    [self.segmentedControlMode setSelectedSegmentIndex:0];
    [self modeChanged:self.segmentedControlMode];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [BTManager sharedInstance].delegate = self;
    [[BTManager sharedInstance].connectedShield setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [BTManager sharedInstance].delegate = self;
    [[BTManager sharedInstance].connectedShield setDelegate:self];
}

- (IBAction)modeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self.textViewLog setText:[BTManager sharedInstance].connectedShield.ASCIIlog];
    }
    else {
        [self.textViewLog setText:[BTManager sharedInstance].connectedShield.HEXlog];
    }
}

- (IBAction)closeKeyboardTap:(UIButton *)sender {
    [self.textFieldHEXCommand endEditing:YES];
    [self.textFieldASCIICommand endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag == 1) {
        // ASCII
        [[BTManager sharedInstance] sendATCommandToHM11:textField.text timeout:2 completionBlock:^(BOOL successful, NSString *response) {
           
        }];
    }
    else {
        
    }
    
    textField.text = @"AT+";
    return YES;
}


// ----------------------------------------------------------------------
#pragma mark - SHield delegete

- (void)shieldDidUpdateASCIILog:(Shield *)shield
{
    if (self.segmentedControlMode.selectedSegmentIndex == 0) {
        [self.textViewLog setText:shield.ASCIIlog];
    }
}

- (void)shieldDidUpdateHEXLog:(Shield *)shield
{
    if (self.segmentedControlMode.selectedSegmentIndex == 1) {
        [self.textViewLog setText:shield.HEXlog];
    }
}

// ----------------------------------------------------------------------
#pragma mark - BT Manager delegete

- (void)btManagerDidDisconnectFromShield:(BTManager *)manager {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
