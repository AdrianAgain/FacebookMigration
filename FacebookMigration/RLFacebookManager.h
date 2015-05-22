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

typedef void (^FacebookManagerComplition)(__strong id result, NSError *error);
typedef void (^FacebookManagerShareComplition)(BOOL cancel, id result, NSError *error);

@interface PhotoObject : NSObject

+ (instancetype)photoWithObjectURL:(NSURL *)objectURL
                             title:(NSString *)title
                            rating:(NSUInteger)rating
                             image:(UIImage *)image;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *objectURL;
@property (nonatomic, assign) NSUInteger rating;
@property (nonatomic, strong) NSString *title;

@end

@interface RLFacebookManager : NSObject

// --- Sessions ---

-(void)configureSessionWithFBSDKLoginButton:(FBSDKLoginButton*)loginButton withPermisions:(NSArray*)permisions withLoginComplition:(FacebookManagerComplition)login withLogoutComplition:(FacebookManagerComplition)logout;

-(void)openSessionWithPermisions:(NSArray*)permissions withLoginComplition:(FacebookManagerComplition)complition;

-(void)closeSession;

-(BOOL)activeSession;

// --- Shares ---

-(void)shareImage:(PhotoObject*)photo andComplition:(FacebookManagerShareComplition)complition;

-(void)shareImage:(UIImage*)image withComplition:(FacebookManagerShareComplition)complition;

// --- Shared ---

+(id)shared;

@end
