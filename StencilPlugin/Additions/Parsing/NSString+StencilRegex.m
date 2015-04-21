//
//  NSString+StencilRegex.m
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "NSString+StencilRegex.h"

@implementation NSString (StencilRegex)

- (NSString *)stringByMatching:(NSString *)pattern replaceWith:(NSString *)template
{
  NSMutableString *mutableSelf = self.mutableCopy;
  NSUInteger matches = [mutableSelf matchPattern:pattern replaceWith:template];
  return matches ? mutableSelf.copy : nil;
}

@end



@implementation NSMutableString (StencilRegex)

- (NSUInteger)matchPattern:(NSString *)pattern replaceWith:(NSString *)template
{
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
  return [regex replaceMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:template];
}

@end
