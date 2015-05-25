//
//  ViewController.m
//  FacebookMigration
//
//  Created by Adrian Hernandez on 5/12/15.
//  Copyright (c) 2015 Rokk3rlabs. All rights reserved.
//

#import "ViewController.h"

#import "FacebookAccountManager.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <AssetsLibrary/ALAsset.h>

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
    [[RLFacebookManager shared] shareLink:@"http://www.fittingroomsocial.com" withComplition:^(BOOL cancel, id result, NSError *error) {
        NSLog(@"Shared: %@, E: %@, C: %d", result, error, cancel);
    }];
}

- (IBAction)shareVideo:(id)sender {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *video = [mainBundle pathForResource: @"small" ofType: @"mp4"];
    // find out alAsset for that url and then do whatever you want with alAsset.
    __block ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:video] completionBlock:^(NSURL *assetURL, NSError *error) {
        [[RLFacebookManager shared] shareVideo:assetURL withComplition:^(BOOL cancel, id result, NSError *error) {
            NSLog(@"Shared: %@, E: %@, C: %d", result, error, cancel);
        }];
    }];
}

- (IBAction)appInvites:(id)sender {
    [[RLFacebookManager shared] appInvites:@"http://www.fittingroomsocial.com" andInviteImageURL:@"http://www.fittingroomsocial.com/assets/img/images/logo.png" witComplition:^(BOOL cancel, id result, NSError *error) {
        NSLog(@"Invites: %@, E: %@, C: %d", result, error, cancel);
    }];
}

- (IBAction)retrieveUserInfo:(id)sender {
    [[RLFacebookManager shared] requestProfileInformation:^(id result, NSError *error) {
        NSLog(@"R: %@, E: %@", result, error);
    }];
}

- (IBAction)getFriends:(id)sender {
    [[RLFacebookManager shared] requestFriends:^(id result, NSError *error) {
        NSLog(@"R: %@, E: %@", result, error);
    }];
}


@end
