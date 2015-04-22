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

@interface TemplateOptionsWindow () <NSTextFieldDelegate>
@property (weak) IBOutlet NSPopUpButton *templateFromPopUpButton;
@property (weak) IBOutlet NSPopUpButton *inheritFromPopUpButton;
@property (weak) IBOutlet NSTextField *descriptionTextField;
@property (weak) IBOutlet NSButton *okButton;
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
  self.templateConfig.thingNameToReplace = map.names.firstObject;
  self.templateConfig.templateDescription = self.descriptionTextField.stringValue;
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
}

- (void)updateInheritChoicePopUp
{
  ThingTypeToClassNamesMap *map = self.templateConfig.thingTypeToNamesMaps[self.templateFromPopUpButton.indexOfSelectedItem];
  [self createInheritChoicePopUpMenuFromMap:map];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
  [self enableOrDisableOKButton];
}

- (void)enableOrDisableOKButton
{
  self.okButton.enabled = self.templateFromPopUpButton.selectedItem != nil && self.inheritFromPopUpButton.selectedItem != nil && self.descriptionTextField.stringValue.length;
}

@end
