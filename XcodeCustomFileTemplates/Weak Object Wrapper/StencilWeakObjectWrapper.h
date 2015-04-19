//
//  StencilWeakObjectWrapper.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StencilWeakObjectWrapper : NSObject

@property (nonatomic, weak) id wrappedObject;

@end
