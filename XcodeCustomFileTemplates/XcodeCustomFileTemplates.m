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

static NSString *const MenuItemTitleNewFileFromCustomTemplate = @"New File from Custom Template…";
static NSString *const MenuItemTitleFileFromCustomTemplate = @"File from Custom Template…";
static NSString *const PluginNameAndCorrespondingDirectory = @"Stencil";
static NSString *const FileTemplatesDirectoryPath = @"File Templates/Custom";
static XcodeCustomFileTemplates *sharedPlugin;

@interface NSObject (IDETemplate_Additions)
+ (id)availableTemplatesOfTemplateKind:(id)kind;
@end

@interface XcodeCustomFileTemplates()
@property (nonatomic, strong) NSBundle *pluginBundle;
@property (nonatomic, assign) BOOL shouldShowNewDocumentCustomTemplatesOnly;
@property (nonatomic, weak) NSMenuItem *menuItemNewFile;
@property (nonatomic, weak) NSMenuItem *menuItemNewFromCustomTemplate;
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
  self.pluginBundle = pluginBundle;
  
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

@interface NSMenu (Additions)
- (void)_HandlePopUpMenuSelectionWithDictionary:(NSDictionary *)dictionary;
- (void)_popUpContextMenu:(id)menu withEvent:(id)event forView:(id)view withFont:(id)font;
@end

@implementation_combine(NSMenu, Additions)

- (instancetype)initWithTitle:(NSString *)aTitle
{
  if ([XcodeCustomFileTemplates canCreateFromCustomTemplate]) {
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate.action = [XcodeCustomFileTemplates sharedPlugin].menuItemNewFile.action;
  } else {
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate.action = nil;
  }
  return dzlSuper(initWithTitle:aTitle);
}

- (void)addItem:(NSMenuItem *)menuItemBeingAddedByXcode
{
  BOOL shouldAdd = ([self.title isEqualToString:@"Project navigator contextual menu"] && [menuItemBeingAddedByXcode.title isEqualToString:@"New File…"]);
  
  if (shouldAdd) {
    NSMenuItem *customMenuItem = [[NSMenuItem alloc] initWithTitle:MenuItemTitleNewFileFromCustomTemplate action:menuItemBeingAddedByXcode.action keyEquivalent:@""];
    dzlSuper(addItem:customMenuItem);
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate = customMenuItem;
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFile = menuItemBeingAddedByXcode;
    if (![XcodeCustomFileTemplates canCreateFromCustomTemplate]) {
      customMenuItem.action = nil;
    }
  }
  
  dzlSuper(addItem:menuItemBeingAddedByXcode);
}

@end



@interface NSObject (IDEAdditions)
+ (id)availableTemplatesOfTemplateKind:(id)kind;
+ (void)_processChildrenOfFilePath:(id)path enumerator:(id)enumerator;
- (char)_testOrDeleteItems:(char)items useContextualMenuSelection:(char)selection;
- (void)contextMenu_newDocument:(NSMenuItem *)item;
- (void)newDocument:(NSMenuItem *)menuItem;
@end



@interface IDETemplate_Additions : NSObject
@end

@implementation IDETemplate_Additions

+ (void)load
{
  dzl_implementationCombine(NSClassFromString(@"IDETemplate"), self, dzl_no_assert);
}

+ (id)availableTemplatesOfTemplateKind:(id)kind
{
  NSArray *templates = dzlSuper(availableTemplatesOfTemplateKind:kind);
  
  if (![XcodeCustomFileTemplates sharedPlugin].shouldShowNewDocumentCustomTemplatesOnly) {
    return templates;
  }
  
  templates = [templates filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id template, NSDictionary *bindings) {
    BOOL isDataModel = [[template valueForKey:@"templateName"] isEqualToString:@"Data Model"];
    BOOL isMappingModel = [[template valueForKey:@"templateName"] isEqualToString:@"Mapping Model"];
    return !isDataModel && !isMappingModel;
  }]];
  return [[NSSet setWithArray:templates] allObjects];
}

+ (void)_processChildrenOfFilePath:(id)path enumerator:(id)enumerator
{
  if ([XcodeCustomFileTemplates sharedPlugin].shouldShowNewDocumentCustomTemplatesOnly && [[path valueForKey:@"pathString"] containsString: @"Templates"]) {
    NSString *pathString = [[XcodeCustomFileTemplates projectRootPath] stringByAppendingPathComponent:PluginNameAndCorrespondingDirectory];
    SEL factorySel = NSSelectorFromString(@"filePathForPathString:");
    path = objc_msgSend([path class], factorySel, pathString);
  }
  
  dzlSuper(_processChildrenOfFilePath:path enumerator:enumerator);
}

@end



@interface IDEStructureNavigator_Additions : NSObject
@end

@implementation IDEStructureNavigator_Additions

+ (void)load
{
  dzl_implementationCombine(NSClassFromString(@"IDEStructureNavigator"), self, dzl_no_assert);
}

- (void)contextMenu_newDocument:(NSMenuItem *)menuItem
{
  [XcodeCustomFileTemplates sharedPlugin].shouldShowNewDocumentCustomTemplatesOnly = ([menuItem.title isEqualToString:MenuItemTitleNewFileFromCustomTemplate]);
  dzlSuper(contextMenu_newDocument:menuItem);
}

- (char)_testOrDeleteItems:(char)items useContextualMenuSelection:(char)selection
{
  id group = [self valueForKey:@"_itemFromContextualClickedRows"];
  if (![group isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
    return 0;
  }
  
  NSString *groupName = [group name];
  groupName = [self input:@"Enter templte name" defaultValue:groupName];
  if (!groupName) {
    return 0;
  }
  groupName = [groupName stringByAppendingString:@".xctemplate"];
  
  NSString *targetPath = [[[XcodeCustomFileTemplates projectRootPath] stringByAppendingPathComponent:PluginNameAndCorrespondingDirectory] stringByAppendingPathComponent:FileTemplatesDirectoryPath];
  targetPath = [targetPath stringByAppendingPathComponent:groupName];
  
  NSArray *groupFileRefs = [group valueForKey:@"childRepresentedObjects"];

  NSMutableArray *filePaths = [NSMutableArray new];
  for (id fileRef in groupFileRefs) {
    NSString *newFilePath = [self makeTemplateFromFileRef:fileRef withGroupName:groupName targetPath:targetPath];
    [filePaths addObject:newFilePath];
  }
  
  NSURL *sourceURL = [[XcodeCustomFileTemplates sharedPlugin].pluginBundle URLForResource:@"TemplateInfo" withExtension:@"plist"];
  NSString *targetFilePath = [targetPath stringByAppendingPathComponent:@"TemplateInfo.plist"];
  NSURL *targetURL = [NSURL fileURLWithPath:targetFilePath];
  [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:targetURL error:nil];
  
  NSArray *filesWithoutXIB = [filePaths filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *filePath, NSDictionary *bindings) {
    return ![filePath hasSuffix:@".xib"];
  }]];
  NSArray *filesOnlyXIB = [filePaths filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *filePath, NSDictionary *bindings) {
    return [filePath hasSuffix:@".xib"];
  }]];
  
  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFiles:filesWithoutXIB];
  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFiles:filesOnlyXIB];
  
  return dzlSuper(_testOrDeleteItems:items useContextualMenuSelection:selection);
}

- (NSString *)makeTemplateFromFileRef:(id)fileRef withGroupName:(NSString *)groupName targetPath:(NSString *)targetPath
{
  NSString *sourcePath = [fileRef valueForKeyPath:@"reference.resolvedAbsolutePath"];
  NSURL *sourceURL = [NSURL fileURLWithPath:sourcePath];
  
  NSString *filename = [sourceURL lastPathComponent];
  NSRange rangeOfDot = [filename rangeOfString:@"."];
  
  NSString *fileExtension = [filename substringFromIndex:rangeOfDot.location];
  
  
  [[NSFileManager defaultManager] createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:nil];
  filename = [@"___FILEBASENAME___" stringByAppendingString:fileExtension];
  targetPath = [targetPath stringByAppendingPathComponent:filename];
  NSURL *targetURL = [NSURL fileURLWithPath:targetPath];
  
  NSError *error = nil;
  BOOL success = [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:targetURL error:&error];

  return targetPath;
}

- (NSString *)input:(NSString *)prompt defaultValue:(NSString *)defaultValue
{
  NSAlert *alert = [NSAlert new];
  alert.messageText = prompt;
  [alert addButtonWithTitle:@"OK"];
  [alert addButtonWithTitle:@"Cancel"];
  alert.informativeText = @"";
  
  NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
  input.stringValue = defaultValue;
  alert.accessoryView = input;
  NSInteger button = [alert runModal];
  if (button == NSAlertFirstButtonReturn) {
    [input validateEditing];
    return [input stringValue];
  } else if (button == NSAlertSecondButtonReturn) {
    return nil;
  } else {
    NSAssert1(NO, @"Invalid input dialog button %zd", button);
    return nil;
  }
}

@end



@interface IDEApplicationCommands_Additions : NSObject
@end

@implementation IDEApplicationCommands_Additions

+ (void)load
{
  dzl_implementationCombine(NSClassFromString(@"IDEApplicationCommands"), self, dzl_no_assert);
}

- (void)newDocument:(NSMenuItem *)menuItem
{
  [XcodeCustomFileTemplates sharedPlugin].shouldShowNewDocumentCustomTemplatesOnly = ([menuItem.title isEqualToString:MenuItemTitleFileFromCustomTemplate]);
  dzlSuper(newDocument:menuItem);
}

@end



@implementation NSObject (PrintMethods)

+ (NSArray *)printMethods
{
  uint numberOfMethods;
  Method *methods = class_copyMethodList(self, &numberOfMethods);
  NSMutableArray *methodNames = [NSMutableArray new];
  for (uint m = 0; m < numberOfMethods; m++) {
    Method method = methods[m];
    SEL name = method_getName(method);
    [methodNames addObject:NSStringFromSelector(name)];
  }
  return methodNames.copy;
}


@end