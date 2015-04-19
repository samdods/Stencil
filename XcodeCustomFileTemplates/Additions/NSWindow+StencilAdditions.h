//
//  NSWindow+StencilAdditions.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectGroup.h"

@interface StencilProjectStructureNavigator : NSObject
@property (nonatomic, readonly) ProjectGroup *selectedGroup;
@end


@interface NSWindow (StencilAdditions)

+ (instancetype)mainWindow;

@property (nonatomic, weak) StencilProjectStructureNavigator *projectStructureNavigator;

@end
