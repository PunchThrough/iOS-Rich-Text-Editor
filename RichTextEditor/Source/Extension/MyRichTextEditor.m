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
@property (nonatomic, strong) NSMutableDictionary *textReplaceDic;
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
    self.stringColor = [UIColor blueColor];
    self.invalidStringColor = [UIColor orangeColor];
    self.helper = [[MyRichTextEditorHelper alloc] init];
    self.parser = [[MyRichTextEditorParser alloc] init];
    self.delegate = self;

    self.indentation = @"    ";
    
    self.tokens = [@{} mutableCopy];
    self.tokenKeys = [@[] mutableCopy];
    
    [self observeKeyboard];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"text" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        // do something useful
    }
    NSError *error;
    NSArray *textJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error)
        NSLog(@"JSONObjectWithData error: %@", error);
    
    self.textReplaceDic = [@{} mutableCopy];
    for (NSDictionary *dic  in textJson) {
        self.textReplaceDic[dic[@"text"]] = dic;
    }
}

// override in use custom menu items (in addition to cut, copy, paste, ..)
- (void)setupMenuItems
{
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
        NSRange selectedRange = textView.selectedRange;

        // old range used to calculate how much text we need to process
        NSDictionary *oldToken = [self.helper tokenForRange:range fromTokens:self.tokens];
        NSRange oldRange = NSMakeRange([oldToken[@"location"] integerValue], [oldToken[@"length"] integerValue]);
        
        // backspace pressed
        if ([text isEqualToString:@""]) {
            [textView deleteBackward];
        }
        // newline entered
        else if ([text isEqualToString:@"\n"]) {
            NSString *beginningText = [textView.text substringToIndex:range.location];
            NSUInteger leftBrackers = [self.helper occurancesOfString:@[@"\\{"] text:beginningText].count;
            NSUInteger rightBrackers = [self.helper occurancesOfString:@[@"\\}"] text:beginningText].count;
            NSInteger indentationCt = leftBrackers - rightBrackers;
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
                selectedRange = range;
            }
            else {
                selectedRange = textView.selectedRange;
            }
        }
        // anything else entered
        else {
            // when single char typed, check for replace { for {} , ...
            if (text.length == 1) {
                NSDictionary *dic = [self.textReplaceDic objectForKey:text];
                    if (dic) {
                        [textView insertText:dic[@"value"]];
                    }
                    else {
                        [textView insertText:text];
                    }
            }
            else {
                [textView insertText:text];                
            }
        }
        
        NSDate *date = [NSDate date];
        [self.parser parseText:self.text segment:self.tokens segmentKeys:self.tokenKeys];
        NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:date];
        NSLog(@"XXX %f",t);
        
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
        else if ([text isEqualToString:@"\n"]) {
            textView.selectedRange = selectedRange;
        }
        else {
            textView.selectedRange = NSMakeRange(selectedRange.location+text.length, 0);
        }
        
        return NO;
}

- (void)applyToken:(NSDictionary*)token {
    if (token) {
        // scroll fix from http://stackoverflow.com/questions/16716525/replace-uitextviews-text-with-attributed-string
        self.scrollEnabled = NO;
        NSRange range = NSMakeRange([token[@"location"] integerValue], [token[@"length"] integerValue]);
        if ([token[@"type"] isEqualToString:@"comment"]) {
            [self applyAttributes:self.commentColor forKey:NSForegroundColorAttributeName atRange:range];
        }
        else if ([token[@"type"] isEqualToString:@"code"]) {
           [self removeAttributeForKey:NSForegroundColorAttributeName atRange:range];
            NSArray *strArr = token[@"strings"];
            for (NSDictionary *strToken in strArr) {
                NSRange r = NSMakeRange([strToken[@"location"] integerValue]+range.location, [strToken[@"length"] integerValue]);
                if ([strToken[@"type"] isEqualToString:@"string"]) {
                    [self applyAttributes:self.stringColor forKey:NSForegroundColorAttributeName atRange:r];
                }
                else if ([strToken[@"type"] isEqualToString:@"invalid-string"]) {
                    [self applyAttributes:self.invalidStringColor forKey:NSForegroundColorAttributeName atRange:r];
                }
            }
        }
        self.scrollEnabled = YES;
    }
}

#pragma mark UITextViewTextDidChangeNotification

// http://www.think-in-g.net/ghawk/blog/2012/09/practicing-auto-layout-an-example-of-keyboard-sensitive-layout/

// The callback for frame-changing of keyboard
- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
 
    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat height = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
    
    // Because the "space" is actually the difference between the bottom lines of the 2 views,
    // we need to set a negative constant value here.
    self.keyboardHeight.constant = height;
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
    [self textView:self shouldChangeTextInRange:self.selectedRange replacementText:text];
}

- (void)didDismissKeyboard
{
    [self resignFirstResponder];
}

- (void)loadWithText:(NSString *)text
{
    self.text = text;
    [self.parser parseText:self.text segment:self.tokens segmentKeys:self.tokenKeys];
    [self removeAttributeForKey:NSForegroundColorAttributeName atRange:NSMakeRange(0, self.text.length)];
    for (NSNumber *tokenKey in self.tokens) {
        NSDictionary *newToken = self.tokens[tokenKey];
        [self applyToken:newToken];
    }
}

@end
