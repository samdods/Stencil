//
//  XcodeCustomFileTemplates.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 17/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>

FOUNDATION_EXPORT NSString *const MenuItemTitleNewFileFromCustomTemplate;
FOUNDATION_EXPORT NSString *const MenuItemTitleFileFromCustomTemplate;
FOUNDATION_EXPORT NSString *const PluginNameAndCorrespondingDirectory;
FOUNDATION_EXPORT NSString *const FileTemplatesDirectoryPath;


@interface Stencil : NSObject <NSMenuDelegate>

+ (instancetype)sharedPlugin;

@property (nonatomic, readonly) BOOL canCreateFromCustomTemplate;

@property (nonatomic, readonly) NSString *projectRootPath;

@property (nonatomic, strong, readonly) NSBundle *pluginBundle;

@property (nonatomic, weak) NSMenuItem *menuItemNewFile;
@property (nonatomic, weak) NSMenuItem *menuItemNewFromCustomTemplate;

@property (nonatomic, weak) NSMenuItem *menuItemDelete;
@property (nonatomic, weak) NSMenuItem *menuItemCreateTemplateFromGroup;

@property (nonatomic, readonly) BOOL showCustomTemplatesOnly;
@property (nonatomic, assign) BOOL beginCreateTemplateFromGroup;

- (void)showTemplateOptionsInWindow:(NSWindow *)window;

@end
