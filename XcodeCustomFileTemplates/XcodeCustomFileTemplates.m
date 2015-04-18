//
//  XcodeCustomFileTemplates.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 17/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "XcodeCustomFileTemplates.h"
#import "DZLImplementationCombine.h"
#import <objc/message.h>

NSString *const MenuItemTitleNewFileFromCustomTemplate = @"New File from Custom Template…";
NSString *const MenuItemTitleFileFromCustomTemplate = @"File from Custom Template…";
NSString *const PluginNameAndCorrespondingDirectory = @"Stencil";
NSString *const FileTemplatesDirectoryPath = @"File Templates/Custom";

static XcodeCustomFileTemplates *sharedPlugin;

@interface NSObject (IDETemplate_Additions)
+ (id)availableTemplatesOfTemplateKind:(id)kind;
@end

@interface XcodeCustomFileTemplates()
@end

@implementation XcodeCustomFileTemplates

+ (void)pluginDidLoad:(NSBundle *)plugin
{
  static dispatch_once_t onceToken;
  NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
  if ([currentApplicationName isEqual:@"Xcode"]) {
    dispatch_once(&onceToken, ^{
      sharedPlugin = [[self alloc] initWithBundle:plugin];
    });
  }
}

+ (instancetype)sharedPlugin
{
  return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)pluginBundle
{
  if (!(self = [super init])) {
    return nil;
  }
  _pluginBundle = pluginBundle;
  
  NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
  [[menuItem submenu] itemWithTitle:@"New"];
  
  NSMenu *menuNew = [[[menuItem submenu] itemWithTitle:@"New"] submenu];
  NSUInteger index = [menuNew indexOfItemWithTitle:@"File…"];
  NSMenuItem *originalItem = [menuNew itemWithTitle:@"File…"];
  
  NSMenuItem *customNewMenuItem = [[NSMenuItem alloc] initWithTitle:@"File from Custom Template…" action:originalItem.action keyEquivalent:@""];
  [menuNew insertItem:customNewMenuItem atIndex:index];
  
  return self;
}

+ (BOOL)canCreateFromCustomTemplate
{
  NSString *projectRootPath = [self projectRootPath];
  NSString *stencilDirectory = [projectRootPath stringByAppendingPathComponent:PluginNameAndCorrespondingDirectory];
  NSString *customTemplatesDirectory = [stencilDirectory stringByAppendingPathComponent:FileTemplatesDirectoryPath];
  
  NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:customTemplatesDirectory error:nil];
  for (NSString *fileOrDir in contents) {
    if ([fileOrDir hasSuffix:@".xctemplate"]) {
      NSString *path = [customTemplatesDirectory stringByAppendingPathComponent:fileOrDir];
      BOOL isDir = NO;
      if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        id kind = [NSClassFromString(@"IDETemplateKind") valueForKey:@"fileTemplateKind"];
        [XcodeCustomFileTemplates sharedPlugin].shouldShowNewDocumentCustomTemplatesOnly = YES;
        BOOL result = [[NSClassFromString(@"IDETemplate") availableTemplatesOfTemplateKind:kind] count] > 0;
        [XcodeCustomFileTemplates sharedPlugin].shouldShowNewDocumentCustomTemplatesOnly = NO;
        return result;
      }
    }
  }
  
  return NO;
}

+ (NSString *)projectRootPath
{
  NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
  
  id workSpace;
  
  for (id controller in workspaceWindowControllers) {
    if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
      workSpace = [controller valueForKey:@"_workspace"];
    }
  }
  
  return [[[workSpace valueForKey:@"representingFilePath"] valueForKey:@"pathString"] stringByDeletingLastPathComponent];
}

@end
