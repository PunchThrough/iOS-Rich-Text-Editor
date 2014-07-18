//
//  RichTextEditor+Protected.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#define RICHTEXTEDITOR_TOOLBAR_HEIGHT 40

@interface RichTextEditor(Protected) <RichTextEditorToolbarDelegate, RichTextEditorToolbarDataSource>
- (CGRect)currentScreenBoundsDependOnOrientation;
- (void)initializeToolbar;
- (void)setupMenuItems;
- (void)populateToolbar;
- (void)setText:(NSString *)text;
@property (nonatomic, strong) RichTextEditorToolbar *toolBar;
@end
