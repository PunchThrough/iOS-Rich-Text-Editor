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
#import "LineNumberLayoutManager.h"
#import "NSAttributedString+MyRichTextEditor.h"

@interface MyRichTextEditor() <MyRichTextEditorToolbarDataSource, UITextViewDelegate>
@property (nonatomic, strong) MyRichTextEditorHelper *helper;
@property (nonatomic, strong) MyRichTextEditorParser *parser;
@property (nonatomic, strong) NSMutableDictionary *segments;
@property (nonatomic, strong) NSMutableArray *segmentKeys;
@property (nonatomic, strong) NSMutableDictionary *textReplaceDic;
@property (nonatomic, strong) NSMutableDictionary *keywordsDic;
@property (nonatomic, strong) NSMutableDictionary *colorsDic;
@property (nonatomic, strong) NSMutableArray *lines;
@property (nonatomic, readwrite) NSUInteger lineNumberGutterWidth;
@end

@implementation MyRichTextEditor

- (id)initWithLineNumbers:(BOOL)lineNumbers
{
    // block copied from https://github.com/alldritt/TextKit_LineNumbers/blob/master/TextKit_LineNumbers/LineNumberTextView.m
    if (lineNumbers) {
        NSTextStorage* ts = [[NSTextStorage alloc] init];
        LineNumberLayoutManager* lm = [[LineNumberLayoutManager alloc] init];
        NSTextContainer* tc = [[NSTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        
        //  Wrap text to the text view's frame
        tc.widthTracksTextView = YES;
        
        //  Exclude the line number gutter from the display area available for text display.
        tc.exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 40.0, CGFLOAT_MAX)]];
        
        [lm addTextContainer:tc];
        [ts addLayoutManager:lm];

        self.lineNumberGutterWidth = 40;
        
        if ((self = [super initWithFrame:CGRectZero textContainer:tc])) {
            self.contentMode = UIViewContentModeRedraw; // cause drawRect: to be called on frame resizing and divice rotation
            [self commonInitialization];
        }
    }
    else {
        self = [super initWithFrame:CGRectZero];
    }

    return self;
}

- (void)commonInitialization
{
    self.borderColor = [UIColor lightGrayColor];
    self.borderWidth = 1.0;
    
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
    NSError *error;
    NSArray *textJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error)
        NSLog(@"JSONObjectWithData error: %@", error);
    
    self.textReplaceDic = [@{} mutableCopy];
    for (NSDictionary *dic  in textJson) {
        self.textReplaceDic[dic[@"text"]] = dic;
    }
    
    filePath = [[NSBundle mainBundle] pathForResource:@"keywords" ofType:@"txt"];
    self.keywordsDic = [self.helper keywordsForPath:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"textColors" ofType:@"json"];
    self.colorsDic = [self.helper colorsForPath:filePath];
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    NSRange selectedRange = textView.selectedRange;

    // old range used to calculate how much text we need to process
    NSDictionary *oldSegment = [self.helper segmentForRange:range fromSegments:self.segments];
    NSRange oldRange = NSMakeRange([oldSegment[@"location"] integerValue], [oldSegment[@"length"] integerValue]);
    
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
    NSLog(@"parse %f",t);
    
    NSDictionary *newSegment = [self.helper segmentForRange:range fromSegments:self.segments];
    NSRange newRange = NSMakeRange([newSegment[@"location"] integerValue], [newSegment[@"length"] integerValue]);
        
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

    NSArray *segments = [self.helper segmentsForRange:bothRanges fromSegments:self.segments segmentKeys:self.segmentKeys];

    // scroll fix from http://stackoverflow.com/questions/16716525/replace-uitextviews-text-with-attributed-string
    self.scrollEnabled = NO;
    NSMutableAttributedString *attrString = [self.attributedText mutableCopy];
    [attrString applySegments:segments colorsDic:self.colorsDic];
    [self setAttributedText:attrString];
    self.scrollEnabled = YES;
    t = [[NSDate date] timeIntervalSinceDate:date];
    NSLog(@"attr strings %f",t);

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

#pragma mark UITextViewTextDidChangeNotification

// inspired by http://www.think-in-g.net/ghawk/blog/2012/09/practicing-auto-layout-an-example-of-keyboard-sensitive-layout/

// The callback for frame-changing of keyboard
- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
 
    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat height = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
    
    self.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
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
    
    NSMutableAttributedString *attrString = [self.attributedText mutableCopy];
    [attrString applySegments:[self.segments allValues] colorsDic:self.colorsDic];
    [self setAttributedText:attrString];
}

- (void) drawRect:(CGRect)rect {
    
    if (self.lineNumberGutterWidth == 0) {
        [super drawRect:rect];
    }
    else {
        //  Drag the line number gutter background.  The line numbers them selves are drawn by LineNumberLayoutManager.
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGRect bounds = self.bounds;
        
        CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
        CGContextFillRect(context, CGRectMake(bounds.origin.x, bounds.origin.y, self.lineNumberGutterWidth, bounds.size.height));
        
        CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
        CGContextSetLineWidth(context, 0.5);
        CGContextStrokeRect(context, CGRectMake(bounds.origin.x + 39.5, bounds.origin.y, 0.5, CGRectGetHeight(bounds)));
        
        [super drawRect:rect];
    }
}

@end
