//
//  StencilPlugin.m
//  StencilPlugin
//
//  Created by Sam Dods on 17/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "Stencil.h"
#import "DZLImplementationCombine.h"
#import "NSMenu+StencilAdditions.h"
#import "TemplateOptionsWindow.h"
#import "TemplateFactory.h"
#import "StencilWeakObjectWrapper.h"
#import "DeallocationObserver.h"

static void *StencilMenuObserver = &StencilMenuObserver;

NSString *const MenuItemTitleNewFileFromCustomTemplate = @"New File from Custom Template…";
NSString *const MenuItemTitleFileFromCustomTemplate = @"File from Custom Template…";
NSString *const PluginNameAndCorrespondingDirectory = @"StencilPlugin";
NSString *const FileTemplatesDirectoryPath = @"File Templates/Custom";

static Stencil *sharedPlugin;
static BOOL ForceShowTemplatesOnly = NO;

@interface NSObject (IDETemplate_Additions)
+ (id)availableTemplatesOfTemplateKind:(id)kind;
@end


@interface Stencil () <TemplateOptionsWindowDelegate>
@property (nonatomic, assign) BOOL projectNavigatorContextualMenuIsOpened;
@property (nonatomic, readwrite) BOOL showCustomTemplatesOnly;
@property (nonatomic, strong) NSMutableSet *observedMenus;
@end

@implementation Stencil

+ (instancetype)sharedPlugin
{
  return sharedPlugin;
}

- (NSMutableSet *)observedMenus
{
  return _observedMenus ?: (_observedMenus = [NSMutableSet new]);
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
  [self observeHighlightedItemForMenu:menuNew];
  [menuNew duplicateItemWithTitle:@"File…" duplicateTitle:MenuItemTitleFileFromCustomTemplate];
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
    if ([[controller valueForKey:@"window"] isEqual:[NSApp mainWindow]]) {
      workSpace = [controller valueForKey:@"_workspace"];
    }
  }
  
  return [[[workSpace valueForKey:@"representingFilePath"] valueForKey:@"pathString"] stringByDeletingLastPathComponent];
}

#pragma mark - NSMenu observing

- (void)observeHighlightedItemForMenu:(NSMenu *)menu
{
  StencilWeakObjectWrapper *wrapper = [StencilWeakObjectWrapper wrap:menu];
  if ([self.observedMenus containsObject:wrapper]) {
    return;
  }
  [menu addObserver:self forKeyPath:@"highlightedItem" options:NSKeyValueObservingOptionNew context:StencilMenuObserver];
  [self.observedMenus addObject:wrapper];
  
  DeallocationObserver *observer = [DeallocationObserver new];
  observer.observedObject = menu;
  __unsafe_unretained NSMenu *unsafeMenu = menu;
  observer.deallocBlock = ^(NSMenu *deallocatedMenu) {
    [unsafeMenu removeObserver:self forKeyPath:@"highlightedItem" context:StencilMenuObserver];
    [self.observedMenus removeObject:wrapper];
  };
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSMenu *)menu change:(NSDictionary *)change context:(void *)context
{
  if (context != StencilMenuObserver) {
    return;
  }
  
  NSMenuItem *item = change[NSKeyValueChangeNewKey];
  if (![item isKindOfClass:[NSMenuItem class]]) {
    return;
  }
  self.showCustomTemplatesOnly = ([item.title isEqualToString:MenuItemTitleFileFromCustomTemplate] || [item.title isEqualToString:MenuItemTitleNewFileFromCustomTemplate]);
  self.beginCreateTemplateFromGroup = (item == self.menuItemCreateTemplateFromGroup);
  
  if (item == self.menuItemNewFromCustomTemplate) {
    item.action = self.menuItemNewFile.action;
  }
}

- (BOOL)showCustomTemplatesOnly
{
  return ForceShowTemplatesOnly || _showCustomTemplatesOnly;
}

#pragma mark - displaying template options

- (void)showTemplateOptionsInWindow:(NSWindow *)window defaultTemplateConfig:(TemplateConfig *)config
{
  NSArray *topLevelObjects = nil;
  [self.pluginBundle loadNibNamed:@"StencilTemplateWindow" owner:self topLevelObjects:&topLevelObjects];
  TemplateOptionsWindow *templateOptionsWindow = [[topLevelObjects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [evaluatedObject isKindOfClass:[TemplateOptionsWindow class]];
  }]] firstObject];
  
  BOOL isTemplateOptionsWindow = [templateOptionsWindow isKindOfClass:[TemplateOptionsWindow class]];
  NSAssert(isTemplateOptionsWindow, @"Error loading from nib");
  if (!isTemplateOptionsWindow) {
    return;
  }
  
  templateOptionsWindow.templateConfig = config;
  templateOptionsWindow.completionDelegate = self;
  
  [NSApp beginSheet:templateOptionsWindow modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)templateOptionsWindowDidCompleteOK:(TemplateOptionsWindow *)window
{
  [[TemplateFactory defaultFactory] generateTemplateFromConfig:window.templateConfig];
  [[NSApp mainWindow] endSheet:window];
}

- (void)templateOptionsWindowDidCancel:(TemplateOptionsWindow *)window
{
  [[NSApp mainWindow] endSheet:window];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
  [sheet orderOut:self];
}

@end
