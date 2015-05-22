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
    [[RLFacebookManager shared] shareImage:[UIImage imageNamed:@"share"] withComplition:^(BOOL cancel, id result, NSError *error) {
         NSLog(@"Shared: %@, E: %@, C: %d", result, error, cancel);
    }];
}

- (IBAction)shareWithLink:(id)sender {
    //    [[RLFacebookManager shared] shareImage:[PhotoObject photoWithObjectURL:[NSURL URLWithString:@"https://igcdn-photos-d-a.akamaihd.net/hphotos-ak-xpa1/t51.2885-15/914228_203457696505771_277488334_n.jpg"] title:@"FRS" rating:1 image:[UIImage imageNamed:@"share"]] andComplition:^(BOOL cancel, id result, NSError *error) {
    //        NSLog(@"Shared: %@, E: %@, C: %d", result, error, cancel);
    //    }];
}


@end
