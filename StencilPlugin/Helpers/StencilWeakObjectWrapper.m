//
//  StencilWeakObjectWrapper.m
//  StencilPlugin
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "StencilWeakObjectWrapper.h"

@interface StencilWeakObjectWrapper ()
@property (nonatomic, weak) NSObject *wrappedObject;
@end

@implementation StencilWeakObjectWrapper

+ (instancetype)wrap:(NSObject *)object
{
  StencilWeakObjectWrapper *wrapper = [self new];
  wrapper.wrappedObject = object;
  return wrapper;
}

- (NSUInteger)hash
{
  return self.wrappedObject.hash;
}

@end
