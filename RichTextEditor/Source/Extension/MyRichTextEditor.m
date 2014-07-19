//
//  MyRichTextEditor.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditor.h"
#import "MyRichTextEditor.h"
#import "MyRichTextEditorToolbar.h"

@interface MyRichTextEditor() <MyRichTextEditorToolbarDataSource>
@end

@implementation MyRichTextEditor

// override in use custom toolbar
- (void)initializeToolbar
{
	self.toolBar = [[MyRichTextEditorToolbar alloc] initWithFrame:CGRectMake(0, 0, [self currentScreenBoundsDependOnOrientation].size.width, RICHTEXTEDITOR_TOOLBAR_HEIGHT)
													   delegate:self
													 dataSource:self];

    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.spellCheckingType = UITextSpellCheckingTypeNo;
}

// override in use custom menu items (in addition to cut, copy, paste, ..)
- (void)setupMenuItems
{
}

#pragma mark MyRichTextEditorToolbarDataSource

- (void)insertText:(NSString *)text cursorOffset:(NSUInteger)cursorOffset
{
    [super insertText:text];
    NSRange selectedRange = self.selectedRange;
    selectedRange.location -= text.length;
    selectedRange.location += cursorOffset;
    self.selectedRange = selectedRange;
}

@end
