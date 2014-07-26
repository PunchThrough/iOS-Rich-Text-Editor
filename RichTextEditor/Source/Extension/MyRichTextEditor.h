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
- (void)loadWithText:(NSString *)text;
@property (nonatomic, strong) UIColor *commentColor;
@property (nonatomic, strong) NSString *indentation;
@end
