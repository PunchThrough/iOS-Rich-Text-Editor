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
#import "MyRichTextEditorHelper.h"

@interface MyRichTextEditor() <MyRichTextEditorToolbarDataSource>
@property (nonatomic, strong) MyRichTextEditorHelper *helper;
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
    
    self.commentColor = [UIColor redColor];
    self.helper = [[MyRichTextEditorHelper alloc] initWithMyRichTextEditor:self];
    self.delegate = self.helper;
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

- (void)loadWithText:(NSString *)text
{
    self.text = text;
    [self.helper formatText];
}

@end
