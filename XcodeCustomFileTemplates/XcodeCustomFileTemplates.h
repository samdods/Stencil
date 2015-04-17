//
//  XcodeCustomFileTemplates.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 17/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface XcodeCustomFileTemplates : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end