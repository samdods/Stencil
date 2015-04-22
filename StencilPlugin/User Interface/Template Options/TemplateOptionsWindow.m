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

@interface TemplateConfig ()
@property (nonatomic, readwrite) TemplateProperties *properties;
@end



@interface TemplateOptionsWindow () <NSTextFieldDelegate>
@property (weak) IBOutlet NSPopUpButton *templateFromPopUpButton;
@property (weak) IBOutlet NSPopUpButton *inheritFromPopUpButton;
@property (weak) IBOutlet NSTextField *descriptionTextField;
@property (weak) IBOutlet NSTextField *templateNameTextField;
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
  self.templateNameTextField.stringValue = self.inheritFromPopUpButton.title;
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
  self.templateConfig.properties = [[TemplateProperties alloc] initWithName:self.templateNameTextField.stringValue thingType:map.thingType nameToReplace:map.names.firstObject inheritFrom:inheritFrom  description:self.descriptionTextField.stringValue];
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

- (IBAction)inheritChoiceChanged:(NSPopUpButton *)sender
{
  self.templateNameTextField.stringValue = sender.title;
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
  self.okButton.enabled = self.templateNameTextField.stringValue.length && self.templateFromPopUpButton.selectedItem != nil && self.inheritFromPopUpButton.selectedItem != nil && self.descriptionTextField.stringValue.length;
}

@end
