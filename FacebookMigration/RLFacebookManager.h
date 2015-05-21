//
//  FacebookManager.h
//  FacebookMigration
//
//  Created by Adrian Hernandez on 5/12/15.
//  Copyright (c) 2015 Rokk3rlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

typedef void (^FacebookManagerComplition)(id result, NSError *error);
typedef void (^FacebookManagerShareComplition)(BOOL cancel, id result, NSError *error);

@interface RLFacebookManager : NSObject

// --- Login ---

-(void)configureSessionWithFBSDKLoginButton:(FBSDKLoginButton*)loginButton withPermisions:(NSArray*)permisions withLoginComplition:(FacebookManagerComplition)login withLogoutComplition:(FacebookManagerComplition)logout;

-(void)openSessionWithPermisions:(NSArray*)permissions withLoginComplition:(FacebookManagerComplition)complition;

// --- Logout ---

-(void)closeSession;

// --- Sessions ---

-(BOOL)activeSession;

// --- Facebook ---

-(void)shareImageWithDescription:(UIImage*)imageToPost withDescription:(NSString*)description withController:(UIViewController*)controller andComplition:(FacebookManagerShareComplition)complition;

// --- Shared ---

+(id)shared;

@end
