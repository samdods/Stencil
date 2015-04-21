//
//  TemplateOptionsWindow.h
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TemplateConfig;
@class TemplateOptionsWindow;

@protocol TemplateOptionsWindowDelegate <NSWindowDelegate>

- (void)templateOptionsWindow:(TemplateOptionsWindow *)window didCompleteWithConfig:(TemplateConfig *)config;
- (void)templateOptionsWindowDidCancel:(TemplateOptionsWindow *)window;

@end


@interface TemplateOptionsWindow : NSWindow

@property (nonatomic, weak) id<TemplateOptionsWindowDelegate> completionDelegate;

@property (nonatomic, copy) NSString *defaultSuperclassName;

@property (nonatomic, copy) NSDictionary *fileRefsByType;

@end

