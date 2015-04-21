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

- (void)templateOptionsWindowDidCompleteOK:(TemplateOptionsWindow *)window;
- (void)templateOptionsWindowDidCancel:(TemplateOptionsWindow *)window;

@end


@interface TemplateOptionsWindow : NSWindow

@property (nonatomic, weak) id<TemplateOptionsWindowDelegate> completionDelegate;

@property (nonatomic, strong) TemplateConfig *templateConfig;

@end

