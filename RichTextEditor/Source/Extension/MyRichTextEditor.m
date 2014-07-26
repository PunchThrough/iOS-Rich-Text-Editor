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
#import "MyRichTextEditorParser.h"

@interface MyRichTextEditor() <MyRichTextEditorToolbarDataSource, UITextViewDelegate>
@property (nonatomic, strong) MyRichTextEditorHelper *helper;
@property (nonatomic, strong) MyRichTextEditorParser *parser;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeight;
@property (nonatomic, strong) NSMutableDictionary *tokens;
@property (nonatomic, strong) NSMutableArray *tokenKeys;

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
    self.helper = [[MyRichTextEditorHelper alloc] init];
    self.parser = [[MyRichTextEditorParser alloc] init];
    self.delegate = self;

    self.indentation = @"    ";
    self.commentColor = [UIColor redColor];
    
    self.tokens = [@{} mutableCopy];
    self.tokenKeys = [@[] mutableCopy];
    
    [self observeKeyboard];
}

// override in use custom menu items (in addition to cut, copy, paste, ..)
- (void)setupMenuItems
{
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([text isEqualToString:@"\n"]) {
        NSString *beginningText = [textView.text substringToIndex:range.location];
        NSUInteger leftBrackers = [self.helper occurancesOfString:@[@"{"] text:beginningText].count;
        NSUInteger rightBrackers = [self.helper occurancesOfString:@[@"}"] text:beginningText].count;
        int indentationCt = leftBrackers - rightBrackers;
        if (indentationCt<0) {
            indentationCt = 0;
        }
        BOOL inBrackets = [self.helper text:textView.text range:range leftNeighbor:@"{" rightNeighbor:@"}"];
        textView.selectedRange = range;
        
        [textView insertText:@"\n"];
        
        for (int i=0; i<indentationCt; i++) {
            [textView insertText:self.indentation];
        }
        
        if (inBrackets) {
            [textView insertText:@"\n"];
            for (int i=0; i<indentationCt-1; i++) {
                [textView insertText:self.indentation];
            }
            NSRange range = textView.selectedRange;
            range.location -= (1 + self.indentation.length*(indentationCt-1));
            textView.selectedRange = range;
        }
        
        return NO;
    }
    else {
        NSRange selectedRange = textView.selectedRange;
        // old range used to calculate how much text we need to process
        NSDictionary *oldToken = [self.helper tokenForRange:range fromTokens:self.tokens];
        NSRange oldRange = NSMakeRange([oldToken[@"location"] integerValue], [oldToken[@"length"] integerValue]);
        
        // backspace pressed
        if ([text isEqualToString:@""]) {
            [textView deleteBackward];
        }
        // character pressed
        else {
            [textView insertText:text];
        }
        
        // retokenize and get new range
        [self.parser parseText:self.text tokens:self.tokens tokenKeys:self.tokenKeys];
        NSDictionary *newToken = [self.helper tokenForRange:range fromTokens:self.tokens];
        NSRange newRange = NSMakeRange([newToken[@"location"] integerValue], [newToken[@"length"] integerValue]);
        
        // apply all tokens
        NSRange bothRanges = NSUnionRange(oldRange, newRange);
        NSArray *tokens = [self.helper tokensForRange:bothRanges fromTokens:self.tokens tokenKeys:self.tokenKeys];
        for (NSDictionary *token in tokens) {
            [self applyToken:token];
        }
        
        // backspace pressed
        if ([text isEqualToString:@""]) {
            if (selectedRange.location == 0) {
                textView.selectedRange = NSMakeRange(0, 0);
            }
            else {
                textView.selectedRange = NSMakeRange(selectedRange.location-1, 0);
            }
        }
        // character pressed
        else {
            textView.selectedRange = NSMakeRange(selectedRange.location+text.length, 0);
        }
        
        return NO;
    }
    
    return YES;
}

- (void)applyToken:(NSDictionary*)token {
    if (token) {
        NSRange range = NSMakeRange([token[@"location"] integerValue], [token[@"length"] integerValue]);
        if ([token[@"comment"] isEqualToNumber:@YES]) {
            [self applyAttributes:self.commentColor forKey:NSForegroundColorAttributeName atRange:range];
        }
        else {
            [self removeAttributeForKey:NSForegroundColorAttributeName atRange:range];
        }
    }
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
    [self.parser parseText:self.text tokens:self.tokens tokenKeys:self.tokenKeys];
    [self removeAttributeForKey:NSForegroundColorAttributeName atRange:NSMakeRange(0, self.text.length)];
    for (NSNumber *tokenKey in self.tokens) {
        NSDictionary *newToken = self.tokens[tokenKey];
        [self applyToken:newToken];
    }
}

@end
