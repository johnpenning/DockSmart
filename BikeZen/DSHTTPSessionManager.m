//
//  DSHTTPSessionManager.m
//  DockSmart
//
//  Created by John Penning on 2/1/14.
//  Copyright (c) 2014 John Penning. All rights reserved.
//

#import "DSHTTPSessionManager.h"

@implementation DSHTTPSessionManager

#pragma mark - Singleton implementation in ARC
+ (DSHTTPSessionManager *)sharedInstance
{
    static DSHTTPSessionManager *sharedDSHTTPSessionManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedDSHTTPSessionManagerInstance = [[self alloc] init];
    });
    return sharedDSHTTPSessionManagerInstance;
}

@end
