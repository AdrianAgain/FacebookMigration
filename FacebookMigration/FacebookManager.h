//
//  FacebookManager.h
//  FacebookMigration
//
//  Created by Adrian Hernandez on 5/12/15.
//  Copyright (c) 2015 Rokk3rlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FacebookManager : NSObject

/**
 *  Do login with facebook.
 *
 *  @param complition Block to execute after log in action ends.
 */
-(void)openSessionWithComplition:(void(^)(NSError *error, BOOL done))complition;

/**
 *  Calls FBSDKLoginManager logout
 */
-(void)logout;

/**
 *  Asks for publish permissions.
 *  @param complition Complition block.
 */
-(void)requestPublishPermissionsWithComplition:(void(^)(NSError *error, BOOL granted))complition;

@end
