//
//  StencilWeakObjectWrapper.h
//  StencilPlugin
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StencilWeakObjectWrapper : NSObject

+ (instancetype) wrap:(NSObject *)object;

@property (nonatomic, weak, readonly) NSObject *wrappedObject;

@end
