//
//  NSInputStream+StencilAdditions.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInputStream (StencilAdditions)

@property (nonatomic, readonly) NSString *stc_nextReadLine;

@end
