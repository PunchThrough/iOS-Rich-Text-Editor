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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeight;
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

    [self observeKeyboard];
}

// override in use custom menu items (in addition to cut, copy, paste, ..)
- (void)setupMenuItems
{
}

#pragma mark UITextViewTextDidChangeNotification

// http://www.think-in-g.net/ghawk/blog/2012/09/practicing-auto-layout-an-example-of-keyboard-sensitive-layout/

// The callback for frame-changing of keyboard
- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    
    CGFloat height = keyboardFrame.size.height;
    
    NSLog(@"Updating constraints.");
    // Because the "space" is actually the difference between the bottom lines of the 2 views,
    // we need to set a negative constant value here.
    self.keyboardHeight.constant = height;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight.constant = 0;
    [UIView animateWithDuration:0.01 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
