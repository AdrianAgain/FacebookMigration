//
//  VNFacebookAccountManager.h
//  Vanish
//
//  Created by Adrian Hernandez on 7/17/14.
//  Modified by Jorge Osorio May 25 - 2015
//  Copyright (c) 2014 Reyneiro Hernandez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ___ <START CLASS HELPER> ___

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <AssetsLibrary/ALAsset.h>

typedef void (^FacebookManagerComplition)(__strong id result, NSError *error);
typedef void (^FacebookManagerShareComplition)(BOOL cancel, id result, NSError *error);

@interface RLFacebookManager : NSObject

// --- Sessions ---

-(void)configureSessionWithFBSDKLoginButton:(FBSDKLoginButton*)loginButton withPermisions:(NSArray*)permisions withLoginComplition:(FacebookManagerComplition)login withLogoutComplition:(FacebookManagerComplition)logout;

-(void)openSessionWithPermisions:(NSArray*)permissions withLoginComplition:(FacebookManagerComplition)complition;

-(void)closeSession;

-(BOOL)activeSession;

// --- Shares ---

-(void)shareLink:(NSString*)url withComplition:(FacebookManagerShareComplition)complition;

-(void)shareImage:(UIImage*)image withComplition:(FacebookManagerShareComplition)complition;

-(void)shareVideo:(NSURL*)video withComplition:(FacebookManagerShareComplition)complition;

// -- Invites --

-(void)appInvites:(NSString*)url andInviteImageURL:(NSString*)imageInvite witComplition:(FacebookManagerShareComplition)__strong complition;

// -- Profile --

-(void)requestProfileInformation:(FacebookManagerComplition)complition;

-(void)requestFriends:(FacebookManagerComplition)complition;

// --- Shared ---

+(id)shared;

@end

// ___ <END CLASS HELPER> ___












@interface FacebookAccountManager : NSObject

+(instancetype)sharedInstance;

/** Will create and open a session if there is none already open.
 */
-(void)openSessionWithComplition:(void(^)(NSError *error, BOOL done))complition;

/** Closes the active session if it is open and clears any persited cache
 *  related to the account.
 */
-(void)closeSessionWithComplition:(void(^)(void))complition;

/** Asks for publish permissions.
 */
-(void)requestPublishPermissionsWithComplition:(void(^)(NSError *error, BOOL granted))permissionGranted;

/** Open a session and post an image with a message in the user wall.
 *  @param (UIImage*)image The image to be posted. If it is nil the method does nothing.
 *  @param (NSString*)text The message to be shown with the image. This parameter can be nil.
 */
-(void)openSessionAndPostImage:(UIImage *)image andText:(NSString *)text withComplition:(void (^)(NSError *error, BOOL status))complition;

/**
 *  Check if the active session is open.
 *
 *  @return Bool value indicating whether the session is open or not.
 */
-(BOOL)activeSessionIsOpen;

/**
 *  <#Description#>
 *
 *  @param image                    <#image description#>
 *  @param text                     <#text description#>
 *  @param appShare                 <#appShare description#>
 *  @param warningMessage           <#warningMessage description#>
 *  @param presentingViewController <#presentingViewController description#>
 *  @param complition               <#complition description#>
 */

#pragma  mark - Post

-(void)postImageUsingSharingDialogue:(UIImage *)image andText:(NSString *)text fromShareApp:(BOOL)appShare warningMessage:(NSString *)warningMessage presentingViewController:(UIViewController *)presentingViewController withComplition:(void (^)(NSError *error, BOOL completed))complition;

/**
 *  Publish a video on the user's wall. Requires publish_actions permission. Requires an open FBSession.
 *
 *  @param videoData    The video, encoded as form data. This field is 
                        required.
 *  @param description  The description of the video, used as the accompanying
                        status message in any feed story.
 *  @param title        The title of the video.
 *  @param successBlock <#successBlock description#>
 *  @param failureBlock <#failureBlock description#>
 */
-(void)publishVideoWithPath:(NSString *)videoPath
                description:(NSString *)description
                      title:(NSString *)title
               successBlock:(void(^)(NSString *videoID))successBlock
               failureBlock:(void(^)(NSError *error))failureBlock;

/**
 *  Open a session if needed, request publish_actions permission and publish a video on the user's wall.
 *
 *  @param videoData    The video, encoded as form data. This field is 
                        required.
 *  @param description  The description of the video, used as the accompanying
                        status message in any feed story.
 *  @param title        The title of the video.
 *  @param successBlock <#successBlock description#>
 *  @param failureBlock <#failureBlock description#>
 */
-(void)openSessionAndPublishVideoWithPath:(NSString *)videoPath
                              description:(NSString *)description
                                    title:(NSString *)title
                             successBlock:(void(^)(NSString *videoID))successBlock
                             failureBlock:(void(^)(NSError *error))failureBlock;


/**
 *  Retrieve the list of friends for the user in session
 *
 *  @param complition Complition block.
 */
-(void)getFriendsForUserInSession:(void(^)(NSArray *graphUsersArray))complition;

/**
 *  Open FB web dialog to send invitations to FB friends.
 *
 *  @param parameters <#parameters description#>
 *  @param complition <#complition description#>
 */
- (void)sendRequest:(NSDictionary *)parameters complition:(void(^)(BOOL done ,NSError *error))complition;

@end
