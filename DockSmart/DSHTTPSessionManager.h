//
//  DSHTTPSessionManager.h
//  DockSmart
//
//  Singleton subclass of AFHTTPSessionManager.
//
//  Created by John Penning on 2/1/14.
//  Copyright (c) 2014 John Penning. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface DSHTTPSessionManager : AFHTTPSessionManager

+ (DSHTTPSessionManager *)sharedInstance; // Singleton method

@end
