//
//  VNFacebookAccountManager.h
//  Vanish
//
//  Created by Adrian Hernandez on 7/17/14.
//  Modified by Jorge Osorio May 25 - 2015
//  Copyright (c) 2014 Reyneiro Hernandez. All rights reserved.
//

#import "FacebookAccountManager.h"

// ___ <START CLASS HELPER> ___
@interface RLFacebookManager() <FBSDKLoginButtonDelegate, FBSDKSharingDelegate, FBSDKAppInviteDialogDelegate>
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

-(void)shareLink:(NSString*)url withComplition:(FacebookManagerShareComplition)complition
{
    [self _shareObject:^{
        _share = complition;
        [self _shareLink:url];
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

-(void)shareVideo:(NSURL*)videoURL withComplition:(FacebookManagerShareComplition)complition
{
    [self _shareObject:^{
        _share = complition;
        [self _shareVideo:videoURL];
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

- (void)_shareDialog:(id)content {
    FBSDKShareDialog *shareDialog = [[FBSDKShareDialog alloc] init];
    shareDialog.shareContent = content;
    shareDialog.delegate = self;
    [shareDialog show];
}

-(void)_shareLink:(NSString*)url
{
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:url];
    [self _shareDialog:content];
}

-(void)_shareImage:(UIImage*)image {
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[[FBSDKSharePhoto photoWithImage:image userGenerated:NO]];
    [FBSDKShareAPI shareWithContent:content delegate:self];
}

-(void)_shareVideo:(NSURL*)videoURL
{
    FBSDKShareVideo *video = [[FBSDKShareVideo alloc] init];
    video.videoURL = videoURL;
    FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
    content.video = video;
    [FBSDKShareAPI shareWithContent:content delegate:self];
}

-(void)_shareObject:(void(^)(void))shareCallAction witComplition:(FacebookManagerShareComplition)__strong complition
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
                        complition(false, result, error);
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
                    complition(false, result, error);
                }
            }
        }];
    }
}

// @@@ INVITES @@@

#pragma mark - ********** Invites **********

-(void)appInvites:(NSString*)url andInviteImageURL:(NSString*)imageInvite witComplition:(FacebookManagerShareComplition)__strong complition
{
    _share = complition;
    FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:url];
    content.previewImageURL = [NSURL URLWithString:imageInvite];
    [FBSDKAppInviteDialog showWithContent:content delegate:self];
}

#pragma mark - Invites Delegates

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results
{
    if (_share) {
        if ([results[@"completionGesture"] isEqualToString:@"cancel"]) {
            _share(true, results, nil);
        } else {
            _share(false, results, nil);
        }
    }
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error {
    if (_share) {
        _share(false, nil, error);
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

-(void)requestFriends:(FacebookManagerComplition)complition
{
    void (^_requestFriends_)(void) = ^{
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/me/friends"
                                      parameters:nil
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            if (complition) {
                complition(result, error);
            }
        }];
    };
    void (^_askForRequestsFriendsPermisions_)(void) = ^{
        if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"user_friends"]) {
            _requestFriends_();
        } else {
            [_loginManager logInWithReadPermissions:@[@"user_friends"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                if (!error) {
                    _requestFriends_();
                } else {
                    if (complition) {
                        complition(result, error);
                    }
                }
            }];
        }
    };
    if ([self activeSession]) {
        _askForRequestsFriendsPermisions_();
    } else {
        [_loginManager logInWithReadPermissions:@[@"user_friends"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (!error) {
                _requestFriends_();
            } else {
                if (complition) {
                    complition(result, error);
                }
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
// ___ <END CLASS HELPER> ___













@implementation FacebookAccountManager

+(instancetype)sharedInstance{
    
    static FacebookAccountManager *instance = nil;
    
    if (instance) {
        return instance;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FacebookAccountManager alloc] init];
    });
    
    return instance;
}

#pragma mark - Log In

- (void)doLoginWithFacebookWithComplition:(void(^)(NSError *error, BOOL done))complition {
    
//    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id<FBGraphUser> user, NSError *error) {
//        
//        if(!error){
//            //get user information
//            complition(nil, YES);
//        }
//    }];
    [[RLFacebookManager shared] openSessionWithPermisions:@[@"email", @"public_profile"] withLoginComplition:^(id result, NSError *error) {
        if (complition) {
            complition(error, YES);
        }
    }];
}

#pragma mark - Session

-(void)openSessionWithComplition:(void(^)(NSError *error, BOOL done))complition
{
//    if (!([FBSession activeSession].state == FBSessionStateOpen || [FBSession activeSession].state == FBSessionStateOpenTokenExtended)) {
//        [FBSession openActiveSessionWithReadPermissions:@[@"email,public_profile, user_friends"]
//                                           allowLoginUI:YES
//                                      completionHandler:
//         ^(FBSession *session,
//           FBSessionState state, NSError *error) {
//             
//             [self sessionStateChanged:session state:state error:error complition:^(NSError *error, BOOL done) {
//                 if (done) {
//                     if (complition) {
//                         complition(nil, YES);
//                     }
//                 }
//                 else{
//                     if (complition) {
//                         complition(error, NO);
//                     }
//                 }
//             }];
//         }];
//        
//    }
//    else
//        {
//        //session is already open
//        if (complition) {
//            complition(nil,YES);
//        }
//        }
    [self doLoginWithFacebookWithComplition:complition];
}

-(void)closeSessionWithComplition:(void(^)(void))complition
{
//    if (FBSession.activeSession.isOpen)
//        {
//        //close session
//        [[FBSession activeSession] close];
//        [[FBSession activeSession] closeAndClearTokenInformation];
//        FBSession.activeSession = nil;
//        NSLog(@"Facebook session was closed");
//        if (complition) {
//            complition();
//        }
//        }
    [[RLFacebookManager shared] closeSession];
}

//- (void)sessionStateChanged:(FBSession *)session
//                      state:(FBSessionState) state
//                      error:(NSError *)error
//                 complition:(void(^)(NSError *error, BOOL done))complition
//{
//    
//    switch (state) {
//        case FBSessionStateOpen: {
//            
//            [self doLoginWithFacebookWithComplition:^(NSError *error, BOOL done) {
//                if (done) {
//                    if (complition) {
//                        complition(nil, YES);
//                    }
//                }
//            }];
//        }
//            break;
//        case FBSessionStateClosed:
//            break;
//        case FBSessionStateClosedLoginFailed:{
//            
//            [FBSession.activeSession closeAndClearTokenInformation];
//            
//            ACAccountStore *store = [[ACAccountStore alloc] init];
//            ACAccountType *FBAccType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
//            if(!FBAccType.accessGranted){
//                if (complition) {
//                    complition(error, NO);
//                }
//            }
//            
//        }
//            break;
//        default:
//            break;
//    }
//}

-(BOOL)activeSessionIsOpen{
//    return [FBSession activeSession].isOpen;
    return [[RLFacebookManager shared] activeSession];
}

#pragma mark - Post

-(void)postImageUsingSharingDialogue:(UIImage *)image andText:(NSString *)text fromShareApp:(BOOL)appShare warningMessage:(NSString *)warningMessage presentingViewController:(UIViewController *)presentingViewController withComplition:(void (^)(NSError *error, BOOL completed))complition{
    
//    SLComposeViewController *composerViewController = [self composerControllerWithImage:image andText:text];
//    
//    [composerViewController setCompletionHandler:^(SLComposeViewControllerResult result) {
//        
//        /*if (result == SLComposeViewControllerResultCancelled) {
//         
//         } else*/
//        if (result == SLComposeViewControllerResultDone){
//            NSLog(@"Share Sucessful");
//            //            NSString *messageAlert = [@"The record has been successfully shared" uppercaseString];
//            //            if (appShare) {
//            //                messageAlert = [@"The app has been successfully shared" uppercaseString];
//            //            }
//            if (complition) {
//                complition(nil, YES);
//            }
//        } else {
//            if (complition) {
//                complition(nil, NO);
//            }
//        }
//    }];
//    
//    /*if (composerViewController) {
//     //        [presentingViewController presentViewController:composerViewController animated:YES completion:^{
//     //            if (complition) {
//     //                complition();
//     //            }
//     //        }];
//     }
//     else*/
//    if([FBDialogs canPresentShareDialogWithPhotos]){
//        [self postUsingFacebookDialogImage:image andText:text withComplition:complition];
//    } else{
//        //        RLAlertView *av = [[RLAlertView alloc] initWithTitle:@"FACEBOOK" message:warningMessage okButtonTitle:@"YES" cancelButtonTitle:@"NO"];
//        //        [av setConfirmBlock:^{
//        [self openSessionAndPostImage:image andText:text withComplition:complition];
//        //        }];
//        //        [av setCancelBlock:^{}];
//        //        [av show];
//    }
    [[RLFacebookManager shared] shareImage:image withComplition:^(BOOL cancel, id result, NSError *error) {
        BOOL completed = NO;
        if (!error && !cancel) {
            completed = YES;
        }
        if (complition) {
            complition(result, completed);
        }
    }];
}

//-(SLComposeViewController *)composerControllerWithImage:(UIImage *)image andText:(NSString *)text
//{
//    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
//        
//        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
//        [controller addImage:image];
//        
//        [controller setInitialText:text ? text : @""];
//        return controller;
//    }
//    return nil;
//}

-(void)postUsingFacebookDialogImage:(UIImage *)image andText:(NSString *)text withComplition:(void (^)(NSError *error, BOOL status))complition
{
//    FBPhotoParams *params = [[FBPhotoParams alloc] init];
//    params.photos = @[image];
//    [FBDialogs presentShareDialogWithPhotoParams:params
//                                     clientState:nil
//                                         handler:^(FBAppCall *call,
//                                                   NSDictionary *results,
//                                                   NSError *error) {
//                                             
//                                             if(error) {
//                                                 NSLog(@"Error publishing story.");
//                                                 NSLog(@"Error: %@",
//                                                       error.description);
//                                                 if (complition) {
//                                                     complition(error, NO);
//                                                 }
//                                             } else if (results[@"completionGesture"] && [results[@"completionGesture"] isEqualToString:@"cancel"]) {
//                                                 NSLog(@"User canceled story publishing.");
//                                                 if (complition) {
//                                                     complition(nil, NO);
//                                                 }
//                                             } else {
//                                                 NSLog(@"Success!");
//                                                 if (complition) {
//                                                     complition(nil, YES);
//                                                 }
//                                             }
////                                             if (error) {
////                                                 
////                                             } else {
////                                                 NSLog(@"Success!");
////                                                 if (complition) {
////                                                     complition(nil, YES);
////                                                 }
////                                             }
//                                         }];
    
    [[RLFacebookManager shared] shareImage:image withComplition:^(BOOL cancel, id result, NSError *error) {
        BOOL completed = NO;
        if (!error && !cancel) {
            completed = YES;
        }
        if (complition) {
            complition(result, completed);
        }
    }];
}

-(void)postImage:(UIImage *)image andText:(NSString *)text withComplition:(void (^)(NSError *error, BOOL status))complition
{
    
//    NSData *imageData = UIImageJPEGRepresentation(image, 90);
//    
//    if (!imageData) {
//        return;
//    }
//    
//    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                    text ? text : @"", @"message",
//                                    imageData, @"source",
//                                    nil];
//    
//    [FBRequestConnection startWithGraphPath:@"me/photos"
//                                 parameters:params
//                                 HTTPMethod:@"POST"
//                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//                              if (complition) {
//                                  complition(error, !error);
//                              }
//                          }];
    [[RLFacebookManager shared] shareImage:image withComplition:^(BOOL cancel, id result, NSError *error) {
        BOOL completed = NO;
        if (!error && !cancel) {
            completed = YES;
        }
        if (complition) {
            complition(result, completed);
        }
    }];
}

- (void)testShareApp{
}


-(void)openSessionAndPostImage:(UIImage *)image andText:(NSString *)text withComplition:(void (^)(NSError *error, BOOL status))complition
{
//    [self openSessionWithComplition:^(NSError *error, BOOL done) {
//        if (done && !error) {
//            
//            if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
//                
//                // permission does not exist. Ask for permissions
//                
//                [self requestPublishPermissionsWithComplition:^(NSError *error, BOOL granted) {
//                    if (granted && !error) {
//                        [self postImage:image andText:text withComplition:complition];
//                    }
//                    else{
//                        //                        RLAlertView *av = [[RLAlertView alloc] initWithTitle:@"Error" message:@"Facebook Publish Permission Error" okButtonImage:[UIImage imageNamed:@"ok-button"] cancelButtonImage:nil];
//                        //                        [av show];
//                        if (complition) {
//                            complition(nil, NO);
//                        }
//                    }
//                }];
//            }
//            else {
//                
//                // permission exists
//                [self postImage:image andText:text withComplition:complition];
//            }
//        }
//        else{
//            
//            // Could not open session.
//            
//            //            RLAlertView *av = [[RLAlertView alloc] initWithTitle:@"Error" message:@"Facebook Attempt to Open Session Error" okButtonImage:[UIImage imageNamed:@"ok-button"] cancelButtonImage:nil];
//            //            [av show];
//            
//            if (complition) {
//                complition(error, NO);
//            }
//        }
//    }];
    [[RLFacebookManager shared] shareImage:image withComplition:^(BOOL cancel, id result, NSError *error) {
        BOOL completed = NO;
        if (!error && !cancel) {
            completed = YES;
        }
        if (complition) {
            complition(result, completed);
        }
    }];
}

-(void)openSessionAndPublishVideoWithPath:(NSString *)videoPath description:(NSString *)description title:(NSString *)title successBlock:(void(^)(NSString *videoID))successBlock failureBlock:(void(^)(NSError *error))failureBlock{
    
//    __weak typeof(self) weakSelf = self;
//    void (^publishBlock)(void) = ^(void){
//        [weakSelf publishVideoWithPath:videoPath description:description title:title successBlock:^(NSString *videoID) {
//            if (successBlock) {
//                successBlock(videoID);
//            }
//        } failureBlock:^(NSError *error) {
//            if (error && failureBlock) {
//                failureBlock(error);
//            }
//        }];
//    };
//    
//    if (![self activeSessionIsOpen]) {
//        [self openSessionWithComplition:^(NSError *error, BOOL done) {
//            if (done) {
//                //Request Publish permissions if needed.
//                if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound){
//                    
//                    [self requestPublishPermissionsWithComplition:^(NSError *error, BOOL granted) {
//                        if (granted) {
//                            //Publish video
//                            publishBlock();
//                        }
//                        else if (failureBlock){
//                            //Permissions not granted
//                            failureBlock(error);
//                        }
//                    }];
//                }else{
//                    //Already Have permissions.
//                    publishBlock();
//                }
//            }
//            else if (failureBlock){
//                //Open session failed
//                failureBlock(error);
//            }
//        }];
//    }
//    else{
//        //Active session is open.
//        [self requestPublishPermissionsWithComplition:^(NSError *error, BOOL granted) {
//            if (granted) {
//                //Already Have permissions.
//                publishBlock();
//            }
//            else if (failureBlock){
//                //Publish permissions not granted.
//                failureBlock(error);
//            }
//        }];
//    }
    __block ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:videoPath] completionBlock:^(NSURL *assetURL, NSError *error) {
        [[RLFacebookManager shared] shareVideo:assetURL withComplition:^(BOOL cancel, id result, NSError *error) {
//            NSLog(@"Shared: %@, E: %@, C: %d", result, error, cancel);
            if (error) {
                if (failureBlock){
                    failureBlock(error);
                }
            } else {
                if (successBlock) {
                    successBlock(result[@"postId"]);
                }
            }
        }];
    }];
}

//-(void)publishVideoWithPath:(NSString *)videoPath description:(NSString *)description title:(NSString *)title successBlock:(void(^)(NSString *videoID))successBlock failureBlock:(void(^)(NSError *error))failureBlock{
//    NSURL *pathURL = [[NSURL alloc] initFileURLWithPath:videoPath isDirectory:NO];
//    NSData *videoData = [NSData dataWithContentsOfFile:videoPath];
//    
//    NSString *path = @"/me/videos";
//    NSDictionary *params = @{
//                             [pathURL absoluteString]:videoData,
//                             @"description":description ? description : @"",
//                             @"title": title ? title : @""
//                             };
//    [FBRequestConnection startWithGraphPath:path parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        //TODO: Handle result.
//        if (!error && successBlock) {
//            successBlock(result);
//        }
//        else if (error && failureBlock){
//            failureBlock(error);
//        }
//    }];
//}

#pragma mark - Permissions

//-(void)requestPublishPermissionsWithComplition:(void(^)(NSError *error, BOOL granted))permissionGranted
//{
////    // Request publish_actions
////    [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
////                                          defaultAudience:FBSessionDefaultAudienceFriends
////                                        completionHandler:^(FBSession *session, NSError *error) {
////                                            
////                                            if (!error) {
////                                                if ([FBSession.activeSession.permissions
////                                                     indexOfObject:@"publish_actions"] == NSNotFound){
////                                                    // Permission not granted, tell the user we will not publish
////                                                    
////                                                    if (permissionGranted) {
////                                                        permissionGranted(nil,NO);
////                                                    }
////                                                } else {
////                                                    // Permission granted, publish the OG story
////                                                    if (permissionGranted) {
////                                                        permissionGranted(nil,YES);
////                                                    }
////                                                }
////                                                
////                                            } else {
////                                                // There was an error, handle it
////                                                // See https://developers.facebook.com/docs/ios/errors/
////                                                if (permissionGranted) {
////                                                    permissionGranted(error,NO);
////                                                }
////                                            }
////                                        }];
//}


#pragma mark - Friends

-(void)getFriendsForUserInSession:(void(^)(NSArray *graphUsersArray))complition{
    
//    FBRequest *request = [FBRequest requestForGraphPath:@"/me/friends?fields=installed,id,name,first_name,last_name"];
//    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        
//        if (!error) {
//            NSArray *allFacebookFriends = [result objectForKey:@"data"];
//            NSLog(@"Found: %lu friends", (unsigned long)allFacebookFriends.count);
//            for (NSDictionary<FBGraphUser>* friend in allFacebookFriends) {
//                NSLog(@"I have a friend named %@ with id %@", friend.name, friend.objectID);
//            }
//            complition(allFacebookFriends);
//        }
//        else{
//            NSLog(@"getFriendsForUserInSession failed with error:%@",error);
//            //Return empty array.
//            complition(@[]);
//        }
//    }];
    
    [[RLFacebookManager shared] requestFriends:^(id result, NSError *error) {
        if (!error) {
            NSArray *allFacebookFriends = [result objectForKey:@"data"];
            complition(allFacebookFriends);
        }
    }];
    
}

#pragma mark - Invitation
- (void)sendRequest:(NSDictionary *)parameters complition:(void(^)(BOOL done ,NSError *error))complition{

    NSString *link =  @"https://itunes.apple.com/us/app/fitting-room-social/id659608202?mt=8", *logo = @"http://www.fittingroomsocial.com/assets/img/images/logo.png";
//    NSString *name =  @"Fitting Room Social";
//    NSString *caption = @"Join me on Fitting Room Social to find fashion that fits.";
////    NSString *caption =  @"Here's your invitation to join me on Fitting Room Social to find fashion that fits.";
//    
//    NSDictionary *paramet = @{
//                              @"name" : name,
//                              @"caption" : caption,
//                              @"link" : link
//                              };
//    
//    [FBWebDialogs presentFeedDialogModallyWithSession:nil parameters:paramet handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
//        if (error) {
//            // Error launching the dialog or sending the request.
//            NSLog(@"Error sending request.");
//            complition(NO, error);
//        } else {
//            if (result == FBWebDialogResultDialogNotCompleted) {
//                // User clicked the "x" icon
//                NSLog(@"User canceled request.");
//                complition(NO, nil);
//            } else {
//                // Handle the send request callback
//                NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
//                if (![urlParams valueForKey:@"request"]) {
//                    // User clicked the Cancel button
//                    NSLog(@"User canceled request.");
//                    complition(NO, nil);
//                } else {
//                    // User clicked the Send button
//                    NSString *requestID = [urlParams valueForKey:@"request"];
//                    NSLog(@"Request ID: %@", requestID);
//                    if (complition) {
//                        complition(YES,nil);
//                    }
//                }
//            }
//        }
//    }];
    [[RLFacebookManager shared] appInvites:link andInviteImageURL:logo witComplition:^(BOOL cancel, id result, NSError *error) {
        if (complition) {
            complition(YES,error);
        }
    }];
}

/*
 When a request is successfully sent, the request ID is part of the info returned to the FBWebDialogHandler handler you define. Specifically, the request ID is returned in the request parameter of the resultURL URL passed to your handler.
 */
// helper function to parse the dialog URL that's returned
//- (NSDictionary*)parseURLParams:(NSString *)query {
//    
//    NSArray *pairs = [query componentsSeparatedByString:@"&"];
//    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//    
//    for (NSString *pair in pairs) {
//        NSArray *kv = [pair componentsSeparatedByString:@"="];
//        NSString *val =
//        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        params[kv[0]] = val;
//    }
//    return params;
//}


@end
