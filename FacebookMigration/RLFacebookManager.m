//
//  FacebookManager.m
//  FacebookMigration
//
//  Created by Adrian Hernandez on 5/12/15.
//  Copyright (c) 2015 Rokk3rlabs. All rights reserved.
//

#import "RLFacebookManager.h"

@interface RLFacebookManager() <FBSDKLoginButtonDelegate, FBSDKSharingDelegate>
{
    
}

@property (copy) FacebookManagerComplition login;

@property (copy) FacebookManagerComplition logout;

@property (copy) FacebookManagerShareComplition share;

@property (nonatomic, strong) FBSDKLoginManager *loginManager;

@end

@implementation RLFacebookManager

- (id)init
{
    if (self = [super init]) {
        _loginManager = [[FBSDKLoginManager alloc] init];
    }
    return self;
}

#pragma mark - Login

-(void)configureSessionWithFBSDKLoginButton:(FBSDKLoginButton*)loginButton withPermisions:(NSArray*)permisions withLoginComplition:(FacebookManagerComplition)login withLogoutComplition:(FacebookManagerComplition)logout
{
    if (!loginButton) {
        @throw [NSException
                exceptionWithName:@"FBSDKLoginButton not found"
                reason:@"Instance of FBSDKLoginButton NIL"
                userInfo:nil];
    } else {
        _login = login;
        _logout = logout;
        loginButton.delegate = self;
        loginButton.readPermissions = permisions;
    }
}

-(void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error
{
    if (_login) {
        _login(result, error);
    }
}

-(void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
    if (_logout) {
        _logout(nil, nil);
    }
}

-(void)openSessionWithPermisions:(NSArray*)permissions withLoginComplition:(FacebookManagerComplition)complition
{
    [_loginManager logInWithReadPermissions:permissions handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (complition) {
            complition(result, error);
        }
        
        if (!error && !result.isCancelled) {
            NSInteger rejectedPermissions = 0;
            for (NSString *permision in permissions) {
                if (![result.grantedPermissions containsObject:permision]) {
                    rejectedPermissions++;
                }
            }
        }
        
        //        // TODO: Better implementation
        //        // If you ask for multiple permissions at once, you
        //        // should check if specific permissions missing
        //        NSInteger rejectedPermissions = 0;
        //        if (![result.grantedPermissions containsObject:@"email"]) {
        //            // Email permission not granted.
        //            NSLog(@"Email permission not granted.");
        //            rejectedPermissions ++;
        //        }
        //        if (![result.grantedPermissions containsObject:@"public_profile"]) {
        //            // Public profile permissions not granted.
        //            NSLog(@"Public profile permissions not granted.");
        //            rejectedPermissions ++;
        //        }
        //        if (![result.grantedPermissions containsObject:@"user_friends"]) {
        //            // User friends permissions not granted.
        //            NSLog(@"User friends permissions not granted.");
        //            rejectedPermissions ++;
        //        }
        //        //        BOOL success = rejectedPermissions < 3;
    }];
}

#pragma mark Logout

-(void)closeSession
{
    if ([self activeSession]) {
        [_loginManager logOut];
    }
}

#pragma mark Facebook

-(void)requestProfileInformation:(FacebookManagerComplition)complition
{
    if ([FBSDKAccessToken currentAccessToken]) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (complition) {
                 complition(result, error);
             }
         }];
    }
}

-(void)shareImageWithDescription:(UIImage*)imageToPost withDescription:(NSString*)description withController:(UIViewController*)controller andComplition:(FacebookManagerShareComplition)complition
{
    if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
        [self _shareImageWithDescription:imageToPost withDescription:description withController:controller andComplition:complition];
    } else {
        FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
        [loginManager logInWithPublishPermissions:@[@"publish_actions"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            [self _shareImageWithDescription:imageToPost withDescription:description withController:controller andComplition:complition];
        }];
    }
}

-(void)_shareImageWithDescription:(UIImage*)imageToPost withDescription:(NSString*)description withController:(UIViewController*)controller andComplition:(FacebookManagerShareComplition)complition {
    
    //TODO: If not support
    //    2015-05-21 12:41:54.956 FacebookMigration[7085:1261599] Shared: Cancel?: 0 <(null), Error Domain=com.facebook.sdk.share Code=2 "The operation couldn’t be completed. (com.facebook.sdk.share error 2.)" UserInfo=0x7fe562f46e60 {com.facebook.sdk:FBSDKErrorArgumentValueKey=<FBSDKSharePhotoContent: 0x7fe562e9c980>, com.facebook.sdk:FBSDKErrorDeveloperMessageKey=Feed share dialogs support FBSDKShareLinkContent., com.facebook.sdk:FBSDKErrorArgumentNameKey=shareContent}>
    
    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
    photo.image = imageToPost;
    
    // User has permisions to publish Content right ®
    photo.userGenerated = YES;
    
    NSDictionary *properties = @{
                                 @"og:type": @"article",
                                 // @"og:title": @"A Game of Thrones",
                                 @"og:description": description //,
                                 // @"books:isbn": @"0-553-57340-3",
                                 };
    FBSDKShareOpenGraphObject *object = [FBSDKShareOpenGraphObject objectWithProperties:properties];
    
    // Create an action
    FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
    [action setObject:object forKey:@"books:book"];
    [action setArray:@[photo] forKey:@"image"];
    
    // Create the content
    FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
    content.action = action;
    content.previewPropertyName = @"article";
    
    // Share
    _share = complition;
    [FBSDKShareDialog showFromViewController:controller withContent:content delegate:self];
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    if (_share) {
        _share(false, results, nil);
    }
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    if (_share) {
        _share(false, nil, error);
    }
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    if (_share) {
        _share(true, sharer, nil);
    }
}

#pragma mark Sessions

-(BOOL)activeSession
{
    if ([FBSDKAccessToken currentAccessToken]) {
        return YES;
    }
    return NO;
}

#pragma mark Singleton Methods

+ (id)shared
{
    static RLFacebookManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

@end
