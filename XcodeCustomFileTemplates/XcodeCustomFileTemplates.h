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

@interface XcodeCustomFileTemplates : NSObject

+ (instancetype)sharedPlugin;

+ (BOOL)canCreateFromCustomTemplate;

+ (NSString *)projectRootPath;

@property (nonatomic, strong, readonly) NSBundle *pluginBundle;

@property (nonatomic, assign) BOOL shouldShowNewDocumentCustomTemplatesOnly;

@property (nonatomic, weak) NSMenuItem *menuItemNewFile;
@property (nonatomic, weak) NSMenuItem *menuItemNewFromCustomTemplate;

@end
