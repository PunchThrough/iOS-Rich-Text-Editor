//
//  MyRichTextEditor.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditor.h"
#import "RichTextEditor+Protected.h"

@interface MyRichTextEditor : RichTextEditor
- (id)initWithLineNumbers:(BOOL)lineNumbers;
- (void)loadWithText:(NSString *)text;
@property (nonatomic, strong) UIColor *commentColor;
@property (nonatomic, strong) UIColor *stringColor;
@property (nonatomic, strong) UIColor *invalidStringColor;
@property (nonatomic, strong) NSString *indentation;
@end
