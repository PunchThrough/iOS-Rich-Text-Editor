//
//  MyRichTextEditorToolbar.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditorToolbar.h"
#import "RichTextEditorToolbar+Protected.h"

typedef enum {
	MyRichTextEditorLeftParen = 1 << 17,
	MyRichTextEditorRightParen = 1 << 18,
	MyRichTextEditorLeftBracket = 1 << 19,
	MyRichTextEditorRightBracket = 1 << 20,
	MyRichTextEditorLeftBrace = 1 << 21,
	MyRichTextEditorRightBrace = 1 << 22,
	MyRichTextEditorAll = 1 << 31,
} MyRichTextEditorFeature;

@protocol MyRichTextEditorToolbarDataSource <RichTextEditorToolbarDataSource>
- (void)insertText:(NSString*)text;
@end

@interface MyRichTextEditorToolbar : RichTextEditorToolbar

@property (nonatomic, weak) id <MyRichTextEditorToolbarDataSource> dataSource;

@end
