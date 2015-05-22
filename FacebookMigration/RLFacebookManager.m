//
//  FacebookManager.m
//  FacebookMigration
//
//  Created by Adrian Hernandez on 5/12/15.
//  Copyright (c) 2015 Rokk3rlabs. All rights reserved.
//

#import "RLFacebookManager.h"

@implementation PhotoObject

+ (instancetype)photoWithObjectURL:(NSURL *)objectURL
                             title:(NSString *)title
                            rating:(NSUInteger)rating
                             image:(UIImage *)image
{
    PhotoObject *photo = [[self alloc] init];
    photo.objectURL = objectURL;
    photo.title = title;
    photo.rating = rating;
    photo.image = image;
    return photo;
}

@end

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
    [_loginManager logInWithPublishPermissions:permissions handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
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

-(void)shareImage:(PhotoObject*)photo andComplition:(FacebookManagerShareComplition)complition
{
    if (!photo) {
        @throw [NSException
                exceptionWithName:@"shareImage PhotoObject not found"
                reason:@"Provide a PhotoObject with photo information"
                userInfo:nil];
        return;
    }
    void (^_share_)(FacebookManagerShareComplition) = ^void(FacebookManagerShareComplition _complition) {
        if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
            [self _shareImage:photo andComplition:_complition];
        } else {
            FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
            [loginManager logInWithPublishPermissions:@[@"publish_actions"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                [self _shareImage:photo andComplition:_complition];
            }];
        }
    };
    if ([self activeSession]) {
        _share_(complition);
    } else {
        [self openSessionWithPermisions:@[@"publish_actions"] withLoginComplition:^(id result, NSError *error) {
            if (!error) {
                _share_(complition);
            } else {
                if (complition) {
                    complition(result, nil, error);
                }
            }
        }];
    }
}

#pragma mark Private


- (FBSDKShareLinkContent *)getShareLinkContentWithContentURL:(NSURL *)objectURL
{
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = objectURL;
    return content;
}

- (FBSDKShareDialog *)getShareDialogWithContentURL:(NSURL *)objectURL
{
    FBSDKShareDialog *shareDialog = [[FBSDKShareDialog alloc] init];
    shareDialog.shareContent = [self getShareLinkContentWithContentURL:objectURL];
    return shareDialog;
}

- (FBSDKMessageDialog *)getMessageDialogWithContentURL:(NSURL *)objectURL
{
    FBSDKMessageDialog *shareDialog = [[FBSDKMessageDialog alloc] init];
    shareDialog.shareContent = [self getShareLinkContentWithContentURL:objectURL];
    return shareDialog;
}

-(void)_shareImage:(PhotoObject*)photo andComplition:(FacebookManagerShareComplition)complition
{
    
    //    //TODO: If not support
    //    //    2015-05-21 12:41:54.956 FacebookMigration[7085:1261599] Shared: Cancel?: 0 <(null), Error Domain=com.facebook.sdk.share Code=2 "The operation couldn’t be completed. (com.facebook.sdk.share error 2.)" UserInfo=0x7fe562f46e60 {com.facebook.sdk:FBSDKErrorArgumentValueKey=<FBSDKSharePhotoContent: 0x7fe562e9c980>, com.facebook.sdk:FBSDKErrorDeveloperMessageKey=Feed share dialogs support FBSDKShareLinkContent., com.facebook.sdk:FBSDKErrorArgumentNameKey=shareContent}>
    //
    //    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
    //    photo.image = imageToPost;
    //
    //    // User has permisions to publish Content right ®
    //    photo.userGenerated = YES;
    //
    //    NSDictionary *properties = @{
    //                                 @"og:type": @"article",
    //                                 // @"og:title": @"A Game of Thrones",
    //                                 @"og:description": description //,
    //                                 // @"books:isbn": @"0-553-57340-3",
    //                                 };
    //    FBSDKShareOpenGraphObject *object = [FBSDKShareOpenGraphObject objectWithProperties:properties];
    //
    //    // Create an action
    //    FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
    //    [action setObject:object forKey:@"article"];
    //    [action setArray:@[photo] forKey:@"image"];
    //
    //    // Create the content
    //    FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
    //    content.action = action;
    //    content.previewPropertyName = @"article";
    //
    //    // Share
    //    _share = complition;
    //    [FBSDKShareDialog showFromViewController:controller withContent:content delegate:self];
    _share = complition;
    FBSDKShareDialog *shareDialog = [self getShareDialogWithContentURL:photo.objectURL];
    shareDialog.delegate = self;
    [shareDialog show];
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
