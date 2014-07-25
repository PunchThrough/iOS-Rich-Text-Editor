//
//  MyRichTextEditorHelper.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditor.h"

@interface MyRichTextEditorHelper : NSObject <UITextViewDelegate>
@property (nonatomic, strong) NSString *indentation;

- (id)initWithMyRichTextEditor:(MyRichTextEditor *)myRichTextEditor;
- (void)formatText;

@property (nonatomic, strong) UIColor *commentColor;

@end
