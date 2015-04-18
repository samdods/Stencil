//
//  NSMenu+StencilAdditions.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 18/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSMenu (StencilAdditions)

- (void)duplicateItemWithTitle:(NSString *)existingTitle duplicateTitle:(NSString *)duplicateTitle;

@end
