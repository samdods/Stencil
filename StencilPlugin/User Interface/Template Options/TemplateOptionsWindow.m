//
//  TemplateOptionsWindow.m
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "TemplateOptionsWindow.h"
#import "TemplateConfig.h"
#import "ThingTypeToClassNamesMap.h"
#import "ProjectFile.h"
#import "TemplateFactory.h"

@interface TemplateConfig ()
@property (nonatomic, readwrite) TemplateProperties *properties;
@end



@interface TemplateOptionsWindow () <NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSPopUpButton *templateFromPopUpButton;
@property (weak) IBOutlet NSPopUpButton *inheritFromPopUpButton;
@property (weak) IBOutlet NSTextField *descriptionTextField;
@property (weak) IBOutlet NSTextField *templateNameTextField;
@property (weak) IBOutlet NSButton *okButton;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *findTextField;
@property (weak) IBOutlet NSTextField *replaceTextField;
@end

@implementation TemplateOptionsWindow

- (void)awakeFromNib
{
  [super awakeFromNib];
  [self enableOrDisableOKButton];
}

- (void)setTemplateConfig:(TemplateConfig *)templateConfig
{
  _templateConfig = templateConfig;
  [self createTemplateChoicePopUpMenu];
  [self updateInheritChoicePopUp];
  self.templateNameTextField.stringValue = self.inheritFromPopUpButton.title;
  self.findTextField.stringValue = self.inheritFromPopUpButton.title;
}

#pragma mark - menu creation

- (void)createTemplateChoicePopUpMenu
{
  NSMenu *menu = [NSMenu new];
  for (ThingTypeToClassNamesMap *map in self.templateConfig.thingTypeToNamesMaps) {
    NSString *title = [NSString stringWithFormat:@"%@ %@", map.thingTypeString, map.names.firstObject];
    [menu addItemWithTitle:title action:nil keyEquivalent:@""];
  }
  self.templateFromPopUpButton.menu = menu;
  [self.templateFromPopUpButton selectItemAtIndex:0];
}

- (void)createInheritChoicePopUpMenuFromMap:(ThingTypeToClassNamesMap *)map
{
  NSMenu *menu = [NSMenu new];
  for (NSString *title in map.names) {
    [menu addItemWithTitle:title action:nil keyEquivalent:@""];
  }
  self.inheritFromPopUpButton.menu = menu;
  [self.inheritFromPopUpButton selectItemAtIndex:0];
}

#pragma mark - actions

- (IBAction)didTapOK:(NSButton *)sender
{
  ThingTypeToClassNamesMap *map = self.templateConfig.thingTypeToNamesMaps[self.templateFromPopUpButton.indexOfSelectedItem];
  NSString *inheritFrom = self.inheritFromPopUpButton.selectedItem.title;
  NSDictionary *fileMap = [self templateFileMap];
  if (!fileMap) {
    [[TemplateFactory defaultFactory] showAlertWithMessage:@"Multiple files cannot be cast to the same output template filename."];
    return;
  }
  self.templateConfig.properties = [[TemplateProperties alloc] initWithName:self.templateNameTextField.stringValue thingType:map.thingType nameToReplace:map.names.firstObject inheritFrom:inheritFrom  description:self.descriptionTextField.stringValue templateFileMap:fileMap];
  [self.completionDelegate templateOptionsWindowDidCompleteOK:self];
}

- (IBAction)didTapCancel:(id)sender
{
  [self.completionDelegate templateOptionsWindowDidCancel:self];
}

#pragma mark - handling changes

- (IBAction)templateChoiceChanged:(NSPopUpButton *)popUpButton
{
  [self updateInheritChoicePopUp];
  ThingTypeToClassNamesMap *map = self.templateConfig.thingTypeToNamesMaps[self.templateFromPopUpButton.indexOfSelectedItem];
  self.findTextField.stringValue = map.names.firstObject;
}

- (IBAction)inheritChoiceChanged:(NSPopUpButton *)sender
{
  self.templateNameTextField.stringValue = sender.title;
}

- (IBAction)didChangeAdvanced:(NSButton *)advancedButton
{
  self.findTextField.enabled = advancedButton.state;
  self.replaceTextField.enabled = advancedButton.state;
}

- (void)updateInheritChoicePopUp
{
  if (self.templateFromPopUpButton.indexOfSelectedItem >= self.templateConfig.thingTypeToNamesMaps.count) {
    return;
  }
  ThingTypeToClassNamesMap *map = self.templateConfig.thingTypeToNamesMaps[self.templateFromPopUpButton.indexOfSelectedItem];
  [self createInheritChoicePopUpMenuFromMap:map];
  [self inheritChoiceChanged:self.inheritFromPopUpButton];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
  [self enableOrDisableOKButton];
}

- (void)enableOrDisableOKButton
{
  self.okButton.enabled = self.templateNameTextField.stringValue.length && self.templateFromPopUpButton.selectedItem != nil && self.inheritFromPopUpButton.selectedItem != nil && self.descriptionTextField.stringValue.length;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [self fileNamesWithoutExtension].count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  NSTextField *textField = [tableView makeViewWithIdentifier:@"cell" owner:self];
  if (!textField) {
    textField = [NSTextField new];
    textField.identifier = @"cell";
  }
  textField.editable = tableColumn.editable;
  textField.selectable = textField.editable;
  textField.bordered = NO;
  NSString *filename = self.fileNamesWithoutExtension[row];
  if ([tableColumn.identifier isEqualToString:@"template"]) {
    filename = @"___FILEBASENAME___";
  }
  textField.stringValue = filename;
  textField.toolTip = textField.stringValue;
  textField.drawsBackground = NO;
  return textField;
}

#pragma mark - multiple file support

- (NSDictionary *)templateFileMap
{
  NSMutableDictionary *map = [NSMutableDictionary new];
  for (NSUInteger rowIndex = 0; rowIndex < self.tableView.numberOfRows; rowIndex++) {
    NSTextField *originalFilenameTextField = [self.tableView viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
    NSTextField *templateFilenameTextField = [self.tableView viewAtColumn:1 row:rowIndex makeIfNecessary:NO];
    if ([map.allValues containsObject:templateFilenameTextField.stringValue]) {
      return nil;
    }
    map[originalFilenameTextField.stringValue] = templateFilenameTextField.stringValue;
  }
  return map;
}

- (NSArray *)fileNamesWithoutExtension
{
  NSArray *names = [self.templateConfig.fileRefs valueForKey:@"nameWithoutExtension"];
  NSSet *set = [NSSet setWithArray:names];
  return set.allObjects;
}

@end
