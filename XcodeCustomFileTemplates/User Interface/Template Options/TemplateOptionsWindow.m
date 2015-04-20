//
//  TemplateOptionsWindow.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "TemplateOptionsWindow.h"
#import "TemplateConfig.h"

@interface TemplateOptionsWindow () <NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *templateNameTextField;
@property (weak) IBOutlet NSTextField *descriptionTextField;
@property (weak) IBOutlet NSButton *okButton;
@end

@implementation TemplateOptionsWindow

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.okButton.enabled = self.templateNameTextField.stringValue.length && self.descriptionTextField.stringValue.length;
}

- (IBAction)didTapOK:(NSButton *)sender
{
  TemplateConfig *config = [[TemplateConfig alloc] initWithSuperclassName:self.templateNameTextField.stringValue description:self.descriptionTextField.stringValue];
  [self.completionDelegate templateOptionsWindow:self didCompleteWithConfig:config];
}

- (IBAction)didTapCancel:(id)sender
{
  [self.completionDelegate templateOptionsWindowDidCancel:self];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
  self.okButton.enabled = self.templateNameTextField.stringValue.length && self.descriptionTextField.stringValue.length;
}

@end
