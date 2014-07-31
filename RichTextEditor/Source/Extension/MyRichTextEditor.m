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
@property (nonatomic, strong) NSMutableDictionary *segments;
@property (nonatomic, strong) NSMutableArray *segmentKeys;
@property (nonatomic, strong) NSMutableDictionary *textReplaceDic;
@property (nonatomic, strong) NSMutableDictionary *keywordsDic;
@property (nonatomic, strong) NSMutableDictionary *keywordColorsDic;
@property (nonatomic, strong) NSMutableArray *lines;
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
    
    self.helper = [[MyRichTextEditorHelper alloc] init];
    self.parser = [[MyRichTextEditorParser alloc] init];
    self.delegate = self;

    self.indentation = @"    ";
    
    self.segments = [@{} mutableCopy];
    self.segmentKeys = [@[] mutableCopy];
    self.lines = [@[] mutableCopy];
    
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
    
    filePath = [[NSBundle mainBundle] pathForResource:@"keywords" ofType:@"txt"];
    if (filePath) {
        NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
        NSArray *arr = [myText componentsSeparatedByString:@"\n"];
        self.keywordsDic = [@{} mutableCopy];
        for (NSString *line in arr) {
            if ([line hasPrefix:@"#"]) {
                continue;
            }
            
            NSArray *words = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (words.count >= 2) {
                if (((NSString*)words[1]).length == 0 && words.count>=3) {
                    self.keywordsDic[words[0]] = words[2];
                }
                else {
                    self.keywordsDic[words[0]] = words[1];
                }
            }
        }
    }

    filePath = [[NSBundle mainBundle] pathForResource:@"textColors" ofType:@"json"];
    if (filePath) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (!data) {
            NSLog(@"textColors file not found");
        }
        NSError *error;
        NSDictionary *textColors = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error)
            NSLog(@"JSONObjectWithData error: %@", error);
        NSArray *temp = textColors[@"comments"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            self.commentColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"invalid-string"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            self.invalidStringColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"string"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            self.stringColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"keywords"];
        if (temp) {
            self.keywordColorsDic = [@{} mutableCopy];
            for (NSDictionary *dic in temp) {
                for (NSString *key in dic) {
                    NSArray *val = dic[key];
                    self.keywordColorsDic[key] = [UIColor colorWithRed:[val[0] floatValue] green:[val[1] floatValue] blue:[val[2] floatValue] alpha:1];
                }
            }
        }
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
        NSDictionary *oldToken = [self.helper tokenForRange:range fromTokens:self.segments];
        NSRange oldRange = NSMakeRange([oldToken[@"location"] integerValue], [oldToken[@"length"] integerValue]);
        
        // backspace pressed
        if ([text isEqualToString:@""]) {
            [textView deleteBackward];
        }
        // newline entered
        else if ([text isEqualToString:@"\n"]) {
            NSString *beginningText = [textView.text substringToIndex:range.location];
            NSUInteger leftBrackers = [self.helper occurancesOfString:@[@"\\{"] text:beginningText addCaptureParen:YES].count;
            NSUInteger rightBrackers = [self.helper occurancesOfString:@[@"\\}"] text:beginningText addCaptureParen:YES].count;
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
        [self.parser parseText:self.text segment:self.segments segmentKeys:self.segmentKeys keywords:self.keywordsDic];
        NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:date];
        NSLog(@"XXX %f",t);
        
        NSDictionary *newToken = [self.helper tokenForRange:range fromTokens:self.segments];
        NSRange newRange = NSMakeRange([newToken[@"location"] integerValue], [newToken[@"length"] integerValue]);
        
        // apply all tokens
        NSRange bothRanges;
        if ((oldRange.length>0 || oldRange.location>0) && (newRange.length>0 || newRange.location>0)) {
            bothRanges = NSUnionRange(oldRange, newRange);
        }
        else if (newRange.length>0 || newRange.location>0) {
            bothRanges = newRange;
        }
        else if (oldRange.length>0 || oldRange.location>0) {
            bothRanges = oldRange;
        }
        else {
            // should never get here
        }
    
        date = [NSDate date];

        NSArray *tokens = [self.helper tokensForRange:bothRanges fromTokens:self.segments tokenKeys:self.segmentKeys];
        for (NSDictionary *token in tokens) {
            [self applySegment:token disableScroll:YES];
        }
        t = [[NSDate date] timeIntervalSinceDate:date];
        NSLog(@"YYY %f",t);
    
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

// scroll fix from http://stackoverflow.com/questions/16716525/replace-uitextviews-text-with-attributed-string

- (void)applySegment:(NSDictionary*)segment disableScroll:(BOOL)disableScroll {

    if (disableScroll) {
        self.scrollEnabled = NO;
    }
    if (segment) {
        NSRange range = NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue]);
        if ([segment[@"type"] isEqualToString:@"comment"]) {
            [self applyAttributes:self.commentColor forKey:NSForegroundColorAttributeName atRange:range];
        }
        else if ([segment[@"type"] isEqualToString:@"string"]) {
            [self applyAttributes:self.stringColor forKey:NSForegroundColorAttributeName atRange:range];
        }
        else if ([segment[@"type"] isEqualToString:@"invalid-string"]) {
            [self applyAttributes:self.invalidStringColor forKey:NSForegroundColorAttributeName atRange:range];
        }
        else if ([segment[@"type"] isEqualToString:@"code"]) {
           [self removeAttributeForKey:NSForegroundColorAttributeName atRange:range];
            if (segment[@"keywords"]) {
                for (NSDictionary *keyword in segment[@"keywords"]) {
                    NSRange r = NSMakeRange([keyword[@"location"] integerValue]+range.location, [keyword[@"length"] integerValue]);
                    [self applyAttributes:[UIColor purpleColor] forKey:NSForegroundColorAttributeName atRange:r];
                }
            }
            if (segment[@"numbers"]) {
                for (NSDictionary *keyword in segment[@"numbers"]) {
                    NSRange r = NSMakeRange([keyword[@"location"] integerValue]+range.location, [keyword[@"length"] integerValue]);
                    [self applyAttributes:[UIColor blueColor] forKey:NSForegroundColorAttributeName atRange:r];
                }
            }
        }
    }
    if (disableScroll) {
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
    [self.parser parseText:self.text segment:self.segments segmentKeys:self.segmentKeys keywords:self.keywordsDic];
    [self removeAttributeForKey:NSForegroundColorAttributeName atRange:NSMakeRange(0, self.text.length)];
    for (NSNumber *segmentKey in self.segments) {
        NSDictionary *newToken = self.segments[segmentKey];
        [self applySegment:newToken disableScroll:NO];
    }
    
    NSMutableArray *arr = [@[] mutableCopy];
    [self.parser parseLineNumText:self.text width:self.frame.size.width lines:arr];
    
}

@end
