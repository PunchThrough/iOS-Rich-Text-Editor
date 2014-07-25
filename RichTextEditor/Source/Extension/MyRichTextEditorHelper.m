//
//  MyRichTextEditorHelper.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditorHelper.h"
#import "MyRichTextEditor.h"

@interface MyRichTextEditorHelper()
@property (nonatomic, strong) NSMutableDictionary *comment;
@end

typedef enum {
	LeftTextCommentStateUnknown = 1,
	LeftTextCommentStateSlashSlash,
    LeftTextCommentStateSlashStar,
    LeftTextCommentStateStarSlash,
    LeftTextCommentStateReturn,
    LeftTextCommentStateSlashNone
} LeftTextCommentState;

@implementation MyRichTextEditorHelper 

- (id)init {
    self = [super init];
    if (self) {
        self.comment = [@{} mutableCopy];
        self.indentation = @"    ";
    }
    return self;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    for (int i=0; i<=range.length; i++) {
        int len;
        if (range.length == 0) {
            len = 0;
        }
        else {
            len = 1;
        }
        [self textView:textView shouldChangeCharInRange:NSMakeRange(range.location, len) replacementChar:text];
    }
    return NO;
}

- (void)textView:(UITextView *)textView shouldChangeCharInRange:(NSRange)range replacementChar:(NSString *)text {
    // newline pressed
    if ([text isEqualToString:@"\n"]) {
        // indentation is left brackets minus right brackets up to the point of the cursor
        NSString *beginningText = [textView.text substringToIndex:range.location];
        NSDictionary *leftBrackers = [self occurancesOfString:@[@"{"] text:beginningText];
        NSDictionary *rightBrackers = [self occurancesOfString:@[@"}"] text:beginningText];
        int indentationCt = leftBrackers.count - rightBrackers.count;
        if (indentationCt<0) {
            indentationCt = 0;
        }
        
        BOOL inBrackets = [self text:textView.text range:range leftNeighbor:@"{" rightNeighbor:@"}"];
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
    }
    // backspace pressed
    else if ([text isEqualToString:@""]) {
        NSString *deletedStr = [textView.text substringWithRange:range];
        [textView deleteBackward];
        if ([deletedStr isEqualToString:@"/"] || [deletedStr isEqualToString:@"*"] || [deletedStr isEqualToString:@"\n"]) {
            [self processCommentRange:range textView:textView];
        }
    }
    // character pressed
    else {
        // insert the character
        [textView insertText:text];
        [self processCommentRange:range textView:textView];
    }
}

- (BOOL)processCommentRange:(NSRange)range textView:(UITextView*)textView {
    range = textView.selectedRange;
    // get the comment symbols for all text before the insert
    NSDictionary *tokensDic = [self occurancesOfString:@[@"//",@"/*",@"*/",@"\n"] text:textView.text];
    NSArray *tokensKeys = [[tokensDic allKeys] sortedArrayUsingSelector: @selector(compare:)];

    NSMutableArray *leftTokenKeys = [@[] mutableCopy];
    NSMutableArray *rightTokenKeys = [@[] mutableCopy];
    for (NSString *key in tokensKeys) {
        if ([key intValue] < range.location) {
            [leftTokenKeys addObject:key];
        }
        else {
            [rightTokenKeys addObject:key];
        }
    }
    
    LeftTextCommentState leftState = LeftTextCommentStateUnknown;
    // index of the left symbol being checked
    NSNumber *leftKey = @0;
    // index of the right symbol being checked
    NSNumber *rightKey = @(textView.text.length);
    
    // iterate backwards through the left symbols, checking for comments. if in a state where forward search is needed
    // it is done right in that block
    for (int i=leftTokenKeys.count-1; i>=0; i--) {
        leftKey = leftTokenKeys[i];
        NSString *token = tokensDic[leftKey];
        if ([token isEqualToString:@"//"]) {
            // a // \n was encountered, no comment. set the leftKey so we know where the no comment starts
            if (leftState == LeftTextCommentStateReturn) {
                leftState = LeftTextCommentStateSlashNone;
                leftKey = leftTokenKeys[i+1];
            }
            // ignore // when in /* state
            else {
                BOOL slashStarFound = NO;
                for (int x=i;x>=0;x--) {
                    NSNumber *tempToken = leftTokenKeys[x];
                    NSString *token = tokensDic[tempToken];
                    if ([token isEqualToString:@"*/"]) {
                        break;
                    }
                    else if ([token isEqualToString:@"/*"]) {
                        leftKey = tempToken;
                        leftState = LeftTextCommentStateSlashStar;
                        for (int j=0; j<rightTokenKeys.count; j++) {
                            rightKey = rightTokenKeys[j];
                            NSString *token = tokensDic[rightKey];
                            if ([token isEqualToString:@"*/"]) {
                                rightKey = @([rightKey intValue]+2);
                                break;
                            }
                        }

                        slashStarFound = YES;
                        break;
                    }
                }
                if (slashStarFound) {
                    break;
                }
            }

            leftState = LeftTextCommentStateSlashSlash;
            // finding where the comment or no comment ends
            for (int j=0; j<rightTokenKeys.count; j++) {
                rightKey = rightTokenKeys[j];
                NSString *token = tokensDic[rightKey];
                if ([token isEqualToString:@"\n"]) {
                    rightKey = @([rightKey intValue]+2);
                    break;
                }
            }
            break;
        }
        // a /* comment was encountered
        else if ([token isEqualToString:@"/*"]) {
            // need to go forward and find the comment end
            if (leftState == LeftTextCommentStateStarSlash) {
                for (int j=leftTokenKeys.count-1; j>=0; j--) {
                    rightKey = leftTokenKeys[j];
                    NSString *token = tokensDic[rightKey];
                    if ([token isEqualToString:@"*/"]) {
                        rightKey = @([rightKey intValue]+2);
                        break;
                    }
                }
            }
            else {
                // finding where the comment ends
                for (int j=0; j<rightTokenKeys.count; j++) {
                    rightKey = rightTokenKeys[j];
                    NSString *token = tokensDic[rightKey];
                    if ([token isEqualToString:@"*/"]) {
                        rightKey = @([rightKey intValue]+2);
                        break;
                    }
                }
            }
            
            leftState = LeftTextCommentStateSlashStar;
            
            break;
        }
        // a */ comment was encountered
        else if ([token isEqualToString:@"*/"]) {
            // if user just typed */, treat as end of commented text
            if ([leftKey intValue] + @"*/".length == range.location) {
                leftState = LeftTextCommentStateStarSlash;
            }
            // if */ then stuff typed, treat as not a comment
            else {
                leftKey = @([leftKey intValue]+2);
                for (int j=0; j<rightTokenKeys.count; j++) {
                    rightKey = rightTokenKeys[j];
                    rightKey = @([rightKey intValue]+2);
                    NSString *token = tokensDic[rightKey];
                    if ([token isEqualToString:@"/*"] || [token isEqualToString:@"//"]) {
                        break;
                    }
                }
                leftState = LeftTextCommentStateSlashNone;
                break;
            }
        }
        // \n can be the end of a comment, so remember it and keep looping
        else if ([token isEqualToString:@"\n"]) {
            leftState = LeftTextCommentStateReturn;
        }
    }
    
    if (leftState == LeftTextCommentStateReturn) {
        // do
    }
    
    if (leftState == LeftTextCommentStateUnknown) {
        leftState = LeftTextCommentStateSlashNone;
    }
    
    MyRichTextEditor *myTextEditor = (MyRichTextEditor *)textView;
    switch (leftState) {
        case LeftTextCommentStateSlashSlash:
        case LeftTextCommentStateSlashStar: {
            NSRange adjustedRange = NSMakeRange([leftKey intValue], [rightKey intValue] - [leftKey intValue]);
            [myTextEditor removeAttributeForKey:NSForegroundColorAttributeName atRange:adjustedRange];
            [myTextEditor applyAttributes:[UIColor redColor] forKey:NSForegroundColorAttributeName atRange:adjustedRange];
            myTextEditor.selectedRange = range;
            break;
        }
        case LeftTextCommentStateSlashNone: {
            NSRange adjustedRange = NSMakeRange([leftKey intValue], [rightKey intValue] - [leftKey intValue]);
            [myTextEditor removeAttributeForKey:NSForegroundColorAttributeName atRange:adjustedRange];
            myTextEditor.selectedRange = range;
            break;
        }
        default:
            break;
    }
    return NO;
}

// usage is to see when the cursor surrounded by {}

- (BOOL)text:(NSString*)text range:(NSRange)range leftNeighbor:(NSString*)left rightNeighbor:(NSString*)right  {
    if (text.length < range.location+range.length+1) {
        return NO;
    }
    
    if (range.location == 0) {
        return NO;
    }
    
    NSString *l = [text substringWithRange:NSMakeRange(range.location-1, 1)];
    NSString *r = [text substringWithRange:NSMakeRange(range.location+range.length, 1)];
    if ([left isEqualToString:l] && [right isEqualToString:r]) {
        return YES;
    }
    return NO;
}

// inspired from http://stackoverflow.com/questions/2166809/number-of-occurrences-of-a-substring-in-an-nsstring
// returns a dic where the key is the index and value being the found string

- (NSMutableDictionary*)occurancesOfString:(NSArray*)strArray text:(NSString*)text {
    NSMutableDictionary *retDic = [@{} mutableCopy];
    NSUInteger length = [text length];
    for (NSString *str in strArray) {
        NSRange range = NSMakeRange(0, length);
        while(range.location != NSNotFound)
        {
            range = [text rangeOfString: str options:0 range:range];
            if(range.location != NSNotFound)
            {
                retDic[[NSNumber numberWithInteger:range.location]] = str;
                range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
                continue;
            }
        }
    }
    return retDic;
}

@end
