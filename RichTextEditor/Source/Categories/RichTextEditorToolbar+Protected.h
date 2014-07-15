//
//  RichTextEditor+Protected.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#define RICHTEXTEDITOR_TOOLBAR_HEIGHT 40

#import "RichTextEditorToggleButton.h"

@interface RichTextEditorToolbar(Protected)
- (void)populateToolbar;
- (UIView *)separatorView;
- (void)addView:(UIView *)view afterView:(UIView *)otherView withSpacing:(BOOL)space;

@end
