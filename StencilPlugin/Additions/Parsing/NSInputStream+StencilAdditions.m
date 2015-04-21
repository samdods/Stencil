//
//  NSInputStream+StencilAdditions.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "NSInputStream+StencilAdditions.h"

@implementation NSInputStream (StencilAdditions)

- (NSString *)stc_nextReadLine
{
  uint8_t inputCharacter;
  NSMutableString *outputString = nil;
  
  while ([self read:&inputCharacter maxLength:1] == 1) {
    if (!outputString) {
      outputString = [NSMutableString new];
    }
    [outputString appendFormat:@"%c", inputCharacter];
    if (inputCharacter == '\n') {
      break;
    }
  }
  
  return [outputString copy];
}

@end
