//
//  TemplateOptionsWindow.m
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "TemplateOptionsWindow.h"
#import "TemplateConfig.h"

@interface TemplateOptionsWindow () <NSTextFieldDelegate>
@property (weak) IBOutlet NSPopUpButton *superclassNamePopupButton;
@property (weak) IBOutlet NSTextField *descriptionTextField;
@property (weak) IBOutlet NSButton *okButton;
@end

@implementation TemplateOptionsWindow

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.okButton.enabled = self.superclassNamePopupButton.selectedItem != nil && self.descriptionTextField.stringValue.length;
}

- (void)setTemplateConfig:(TemplateConfig *)templateConfig
{
  _templateConfig = templateConfig;
  NSMenu *menu = [NSMenu new];
  for (NSString *className in templateConfig.availableSuperclassNames) {
    [menu addItemWithTitle:className action:nil keyEquivalent:@""];
  }
  self.superclassNamePopupButton.menu = menu;
  [self.superclassNamePopupButton selectItem:[menu itemAtIndex:templateConfig.selectedSuperclassNameIndex]];
}

- (IBAction)didTapOK:(NSButton *)sender
{
  self.templateConfig.selectedSuperclassNameIndex = self.superclassNamePopupButton.indexOfSelectedItem;
  [self.completionDelegate templateOptionsWindowDidCompleteOK:self];
}

- (IBAction)didTapCancel:(id)sender
{
  [self.completionDelegate templateOptionsWindowDidCancel:self];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
  self.okButton.enabled = self.superclassNamePopupButton.selectedItem != nil && self.descriptionTextField.stringValue.length;
}

@end
