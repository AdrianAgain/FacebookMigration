//
//  ViewController.m
//  FacebookMigration
//
//  Created by Adrian Hernandez on 5/12/15.
//  Copyright (c) 2015 Rokk3rlabs. All rights reserved.
//

#import "ViewController.h"

#import "RLFacebookManager.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet FBSDKLoginButton *facebookLogin;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure login
    [[RLFacebookManager shared] configureSessionWithFBSDKLoginButton:_facebookLogin withPermisions:@[@"email"] withLoginComplition:^(id result, NSError *error) {
        NSLog(@"Login with FBSDKLoginButton: %@, %@", result, error);
    } withLogoutComplition:^(id result, NSError *error) {
        NSLog(@"Logout with FBSDKLoginButton");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)facebookLoginSubmit:(id)sender
{
    [[RLFacebookManager shared] openSessionWithPermisions:@[@"email"] withLoginComplition:^(id result, NSError *error) {
        NSLog(@"Login with Manual Action: %@, %@", result, error);
    }];
}

- (IBAction)facebookLogoutSubmit:(id)sender
{
    [[RLFacebookManager shared] closeSession];
}

- (IBAction)facebookShareSubmit:(id)sender {
    [[RLFacebookManager shared] shareImageWithDescription:[UIImage imageNamed:@"hotfix"] withDescription:@"Hot fix man" withController:self andComplition:^(BOOL cancel, id result, NSError *error) {
        NSLog(@"Shared: Cancel?: %d <%@, %@>", cancel, result, error);
    }];
}

@end
