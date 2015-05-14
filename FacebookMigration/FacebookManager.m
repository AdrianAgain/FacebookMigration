//
//  FacebookManager.m
//  FacebookMigration
//
//  Created by Adrian Hernandez on 5/12/15.
//  Copyright (c) 2015 Rokk3rlabs. All rights reserved.
//

#import "FacebookManager.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "FBSDKLoginManager.h"
#import "FBSDKLoginManagerLoginResult.h"


@interface FacebookManager()
@property (nonatomic, strong) FBSDKLoginManager *loginManager;

@end

@implementation FacebookManager


#pragma mark - Login
-(void)openSessionWithComplition:(void(^)(NSError *error, BOOL done))complition{
    
    if (!_loginManager) {
        _loginManager = [[FBSDKLoginManager alloc] init];
    }

    [_loginManager logInWithReadPermissions:@[@"email, public_profile, user_friends"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            // Process error
            if (complition) {
                complition(error,NO);
            }
        } else if (result.isCancelled) {
            // Handle cancellations
            if (complition) {
                complition(error,NO);
            }
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            NSInteger rejectedPermissions = 0;
            if (![result.grantedPermissions containsObject:@"email"]) {
                // Email permission not granted.
                NSLog(@"Email permission not granted.");
                rejectedPermissions ++;
            }
            if (![result.grantedPermissions containsObject:@"public_profile"]) {
                // Public profile permissions not granted.
                NSLog(@"Public profile permissions not granted.");
                rejectedPermissions ++;
            }
            if (![result.grantedPermissions containsObject:@"user_friends"]) {
                // User friends permissions not granted.
                NSLog(@"User friends permissions not granted.");
                rejectedPermissions ++;
            }
            
            BOOL success = rejectedPermissions < 3;
            if (complition) {
                complition(nil,success);
            }
        }
    }];

}

#pragma mark - Logout

-(void)logout{
    if (_loginManager) {
        [_loginManager logOut];
    }
}

#pragma mark - Permissions

-(void)requestPublishPermissionsWithComplition:(void(^)(NSError *error, BOOL granted))complition{


}



@end
