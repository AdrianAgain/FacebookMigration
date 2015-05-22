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

#pragma mark - ********** Sessions **********

// @@@ SESSIONS @@@

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
    }];
}

-(BOOL)activeSession
{
    if ([FBSDKAccessToken currentAccessToken]) {
        return YES;
    }
    return NO;
}

-(void)closeSession
{
    if ([self activeSession]) {
        [_loginManager logOut];
    }
}

#pragma mark - Sessions Delegates

// @@@ SESSIONS DELEGATES @@@

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

#pragma mark - ********** Shares **********

// @@@ SHARES @@@

-(void)shareImage:(PhotoObject*)photo andComplition:(FacebookManagerShareComplition)complition
{
    if (!photo) {
        @throw [NSException
                exceptionWithName:@"shareImage PhotoObject not found"
                reason:@"Provide a PhotoObject with photo information"
                userInfo:nil];
        return;
    }
    [self _shareObject:^{
        [self _shareImage:photo andComplition:^(BOOL cancel, id result, NSError *error) {
            if (complition) {
                complition(cancel, result, error);
            }
        }];
    } witComplition:^(BOOL cancel, id result, NSError *error) {
        if (complition) {
            complition(cancel, result, error);
        }
    }];
}

-(void)shareImage:(UIImage*)image withComplition:(FacebookManagerShareComplition)complition
{
    [self _shareObject:^{
        _share = complition;
        [self _shareImage:image];
    } witComplition:^(BOOL cancel, id result, NSError *error) {
        if (complition) {
            complition(cancel, result, error);
        }
    }];
}

#pragma mark - Shares Delegates

// @@@ SHARES DELEGATES @@@

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

#pragma mark - Shares Privates

// @@@ SHARES PRIVATES @@@

- (FBSDKShareLinkContent *)_getShareLinkContentWithContentURL:(NSURL *)objectURL
{
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = objectURL;
    return content;
}

- (FBSDKShareDialog *)_getShareDialogWithContentURL:(NSURL *)objectURL
{
    FBSDKShareDialog *shareDialog = [[FBSDKShareDialog alloc] init];
    shareDialog.shareContent = [self _getShareLinkContentWithContentURL:objectURL];
    return shareDialog;
}

- (FBSDKMessageDialog *)_getMessageDialogWithContentURL:(NSURL *)objectURL
{
    FBSDKMessageDialog *shareDialog = [[FBSDKMessageDialog alloc] init];
    shareDialog.shareContent = [self _getShareLinkContentWithContentURL:objectURL];
    return shareDialog;
}

-(void)_shareImage:(PhotoObject*)photo andComplition:(FacebookManagerShareComplition)complition
{
    _share = complition;
    FBSDKShareDialog *shareDialog = [self _getShareDialogWithContentURL:photo.objectURL];
    shareDialog.delegate = self;
    [shareDialog show];
}

-(void)_shareImage:(UIImage*)image {
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[[FBSDKSharePhoto photoWithImage:image userGenerated:YES]];
    [FBSDKShareAPI shareWithContent:content delegate:self];
}

-(void)_shareObject:(void(^)(void))shareCallAction witComplition:(FacebookManagerShareComplition)complition
{
    if (!shareCallAction) {
        @throw [NSException exceptionWithName:@"_shareObject <shareCallAction> not found" reason:@"Provide a shareCallAction" userInfo:nil];
        return;
    }
    void (^_share_)(void) = ^{
        if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
            shareCallAction();
        } else {
            [_loginManager logInWithPublishPermissions:@[@"publish_actions"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                if (!error) {
                    shareCallAction();
                } else {
                    if (complition) {
                        complition(result, nil, error);
                    }
                }
            }];
        }
    };
    if ([self activeSession]) {
        _share_();
    } else {
        [_loginManager logInWithPublishPermissions:@[@"publish_actions"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (!error) {
                shareCallAction();
            } else {
                if (complition) {
                    complition(result, nil, error);
                }
            }
        }];
    }
}

#pragma mark - ********** Profile **********

// @@@ PROFILE @@@

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

#pragma mark ********** Singleton **********

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
