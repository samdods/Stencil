//
//  XcodeCustomFileTemplates.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 17/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "Stencil.h"
#import "DZLImplementationCombine.h"
#import "NSMenu+StencilAdditions.h"
#import "TemplateOptionsWindow.h"

NSString *const MenuItemTitleNewFileFromCustomTemplate = @"New File from Custom Template…";
NSString *const MenuItemTitleFileFromCustomTemplate = @"File from Custom Template…";
NSString *const PluginNameAndCorrespondingDirectory = @"Stencil";
NSString *const FileTemplatesDirectoryPath = @"File Templates/Custom";

static Stencil *sharedPlugin;
static BOOL ForceShowTemplatesOnly = NO;

@interface NSObject (IDETemplate_Additions)
+ (id)availableTemplatesOfTemplateKind:(id)kind;
@end


@interface Stencil () <TemplateOptionsWindowDelegate>
@property (nonatomic, assign) BOOL projectNavigatorContextualMenuIsOpened;
@property (nonatomic, readwrite) BOOL showCustomTemplatesOnly;
@end

@implementation Stencil

+ (instancetype)sharedPlugin
{
  return sharedPlugin;
}

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

- (id)initWithBundle:(NSBundle *)pluginBundle
{
  if (!(self = [super init])) {
    return nil;
  }
  _pluginBundle = pluginBundle;
  [self updateMainMenuItems];
  return self;
}

- (void)updateMainMenuItems
{
  NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
  [[menuItem submenu] itemWithTitle:@"New"];
  
  NSMenu *menuNew = [[[menuItem submenu] itemWithTitle:@"New"] submenu];
  menuNew.delegate = self;
  [menuNew duplicateItemWithTitle:@"File…" duplicateTitle:@"File from Custom Template…"];
}

- (BOOL)canCreateFromCustomTemplate
{
  NSString *projectRootPath = [self projectRootPath];
  NSString *stencilDirectory = [projectRootPath stringByAppendingPathComponent:PluginNameAndCorrespondingDirectory];
  NSString *customTemplatesDirectory = [stencilDirectory stringByAppendingPathComponent:FileTemplatesDirectoryPath];
  
  NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:customTemplatesDirectory error:nil];
  for (NSString *fileOrDir in contents) {
    if ([fileOrDir hasSuffix:@".xctemplate"]) {
      NSString *path = [customTemplatesDirectory stringByAppendingPathComponent:fileOrDir];
      return [self hasAvailableTemplatesAtPath:path];
    }
  }
  
  return NO;
}

- (BOOL)hasAvailableTemplatesAtPath:(NSString *)path
{
  BOOL isDir = NO;
  if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
    id kind = [NSClassFromString(@"IDETemplateKind") valueForKey:@"fileTemplateKind"];
    ForceShowTemplatesOnly = YES;
    BOOL result = [[NSClassFromString(@"IDETemplate") availableTemplatesOfTemplateKind:kind] count] > 0;
    ForceShowTemplatesOnly = NO;
    return result;
  }
  return NO;
}

- (NSString *)projectRootPath
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


#pragma mark - NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu
{
  BOOL isContextualMenu = [menu.title isEqualToString:ProjectNavigatorContextualMenu];
  if (isContextualMenu) {
    NSWindowController *result = [[NSApplication sharedApplication] keyWindow].windowController;
    if ([result isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {

    }
  }
}

- (void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{
  self.showCustomTemplatesOnly = ([item.title isEqualToString:MenuItemTitleFileFromCustomTemplate] || [item.title isEqualToString:MenuItemTitleNewFileFromCustomTemplate]);
  self.beginCreateTemplateFromGroup = (item == self.menuItemCreateTemplateFromGroup);
}

- (BOOL)showCustomTemplatesOnly
{
  return ForceShowTemplatesOnly || _showCustomTemplatesOnly;
}

#pragma mark - displaying template options

- (void)showTemplateOptionsInWindow:(NSWindow *)window
{
  NSArray *topLevelObjects = nil;
  [self.pluginBundle loadNibNamed:@"STCTemplateOptionsWindow" owner:self topLevelObjects:&topLevelObjects];
  TemplateOptionsWindow *templateOptionsWindow = topLevelObjects.firstObject;
  BOOL isTemplateOptionsWindow = [templateOptionsWindow isKindOfClass:[TemplateOptionsWindow class]];
  NSAssert(isTemplateOptionsWindow, @"Error loading from nib");
  if (!isTemplateOptionsWindow) {
    return;
  }
  
  templateOptionsWindow.completionDelegate = self;
  
  [NSApp beginSheet:templateOptionsWindow modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)templateOptionsWindowDidCancel:(TemplateOptionsWindow *)window
{
  [[NSApp mainWindow] endSheet:window];
  [window orderOut:self];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
}

@end
