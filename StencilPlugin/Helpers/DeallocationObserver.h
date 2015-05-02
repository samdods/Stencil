//
//  DeallocationObserver.h
//  StencilPlugin
//
//  Created by Sam Dods on 02/05/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeallocationObserver : NSObject

@property (nonatomic, weak) id observedObject;
@property (nonatomic, copy) void (^deallocBlock)(id observedObject);

@end
