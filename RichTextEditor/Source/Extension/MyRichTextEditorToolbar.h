//
//  MyRichTextEditorToolbar.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditorToolbar.h"
#import "RichTextEditorToolbar+Protected.h"
#import "MyRichTextEditorMacroPicker.h"

@protocol MyRichTextEditorToolbarDataSource <RichTextEditorToolbarDataSource>
- (void)insertText:(NSString *)text cursorOffset:(NSUInteger)cursorOffset;
@end

@interface MyRichTextEditorToolbar : RichTextEditorToolbar
@property (nonatomic, weak) id <MyRichTextEditorToolbarDataSource> dataSource;

@end


