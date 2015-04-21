//
//  NSOutputStream+StencilAdditions.m
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "NSOutputStream+StencilAdditions.h"

@implementation NSOutputStream (StencilAdditions)

- (void)stc_writeString:(NSString *)string
{
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  [self write:[data bytes] maxLength:[data length]];
}

@end
