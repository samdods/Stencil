//
//  NSOutputStream+StencilAdditions.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOutputStream (StencilAdditions)

- (void)stc_writeString:(NSString *)string;

@end
