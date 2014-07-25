//
//  MyRichTextEditorHelper.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

typedef enum {
	CommentStateUnknown = 1,
	CommentStateSlashSlash,
    CommentStateSlashStar,
    CommentStateStarSlash,
    CommentStateReturn,
    CommentStateSlashNone
} CommentState;

#import "MyRichTextEditorHelper.h"

@interface MyRichTextEditorHelper()
@property (nonatomic, strong) NSMutableDictionary *tokens;
@property (nonatomic, strong) NSMutableArray *tokenKeys;
@property (nonatomic, weak) MyRichTextEditor *myRichTextEditor;
@end

@implementation MyRichTextEditorHelper 

- (id)initWithMyRichTextEditor:(MyRichTextEditor *)myRichTextEditor {
    self = [super init];
    if (self) {
        self.tokens = [@{} mutableCopy];
        self.indentation = @"    ";
        self.myRichTextEditor = myRichTextEditor;
        self.commentColor = [UIColor redColor];
    }
    return self;
}

// formats the input text

- (void)formatText {
    [self parseText:self.myRichTextEditor.text];
    [self applyCommentText];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([text isEqualToString:@"\n"]) {
        NSString *beginningText = [textView.text substringToIndex:range.location];
        NSUInteger leftBrackers = [self occurancesOfString:@[@"{"] text:beginningText].count;
        NSUInteger rightBrackers = [self occurancesOfString:@[@"}"] text:beginningText].count;
        int indentationCt = leftBrackers - rightBrackers;
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
        
        return NO;
    }
    else {
        NSRange selectedRange = textView.selectedRange;
        // old range used to calculate how much text we need to process
        NSDictionary *oldToken = [self tokenForRange:range];
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
        [self parseText:self.myRichTextEditor.text];
        NSDictionary *newToken = [self tokenForRange:range];
        NSRange newRange = NSMakeRange([newToken[@"location"] integerValue], [newToken[@"length"] integerValue]);
        
        // apply all tokens
        NSRange bothRanges = NSUnionRange(oldRange, newRange);
        NSArray *tokens = [self tokensForRange:bothRanges];
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

- (NSDictionary*)tokenForRange:(NSRange)range {
    NSUInteger min = NSUIntegerMax;
    NSNumber *keyToken;
    for (NSNumber *key in self.tokens) {
        NSUInteger diff = abs([key integerValue] - range.location);
        if (([key integerValue] <= range.location) && (diff <= min)) {
            min = diff;
            keyToken = key;
        }
    }
    if (keyToken) {
        NSDictionary *token = self.tokens[keyToken];
        NSUInteger location = [token[@"location"] integerValue];
        NSUInteger length = [token[@"length"] integerValue];
        // handles case where NSIntersectionRange returns false positive
        if (range.location == 0 && range.length == 0) {
            if (location == 0) {
                return token;
            }
        }
        else {
            NSRange intersectionRange = NSIntersectionRange(range, NSMakeRange(location, length));
            if (intersectionRange.length != 0 || intersectionRange.location != 0) {
                return token;
            }
        }
    }
    return nil;
}

- (NSMutableArray*)tokensForRange:(NSRange)wholeRange {
    NSMutableArray *retArr = nil;
    for (NSNumber *key in self.tokenKeys) {
        NSDictionary *token = self.tokens[key];
        NSRange tokenRange = NSMakeRange([token[@"location"] integerValue], [token[@"length"] integerValue]);
        NSRange intersectionRange = NSIntersectionRange(wholeRange, tokenRange);
        if (intersectionRange.length!= 0 || intersectionRange.location != 0) {
            if (!retArr) {
                retArr =  [@[] mutableCopy];
            }
            [retArr addObject:token];
        }
    }
    return retArr;
}

// parses the text into tokens based on comment symbols

- (void)parseText:(NSString*)text {
    [self.tokens removeAllObjects];
    
    NSDictionary *commentsDic = [self occurancesOfString:@[@"//",@"/*",@"*/",@"\n"] text:text];
    NSArray *commentKeys = [[commentsDic allKeys] sortedArrayUsingSelector: @selector(compare:)];
    CommentState state = CommentStateUnknown;
    NSNumber *prevKey;
    NSNumber *key;
    for (int j=0; j<commentKeys.count; j++) {
        key = commentKeys[j];
        NSString *symbol = commentsDic[key];
        if ([symbol isEqualToString:@"/*"]) {
            state = CommentStateSlashStar;
            prevKey = key;
            continue;
        }
        else if ([symbol isEqualToString:@"*/"]) {
            if (state == CommentStateSlashStar) {
                // found /* */
                self.tokens[prevKey] = @{@"comment":@1, @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"*/".length)};
                state = CommentStateStarSlash;
            }
        }
        else if ([symbol isEqualToString:@"//"]) {
            if (state != CommentStateSlashStar) {
                state = CommentStateSlashSlash;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"\n"]) {
            if (state == CommentStateSlashSlash) {
                state = CommentStateReturn;
                self.tokens[prevKey] = @{@"comment":@1, @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
            }
        }
    }
    
    if (state == CommentStateSlashStar) {
        key = @(text.length);
        self.tokens[prevKey] = @{@"comment":@1, @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
    else if (state == CommentStateSlashSlash) {
        key = @(text.length);
        self.tokens[prevKey] = @{@"comment":@1, @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
    
    // calculate non comment spaces
    NSMutableDictionary *nonCommentTokens = [@{} mutableCopy];
    self.tokenKeys = [[[self.tokens allKeys] sortedArrayUsingSelector: @selector(compare:)] mutableCopy];
    for (int i=0;i<self.tokenKeys.count;i++) {
        if (i == 0) {
            NSNumber *key = self.tokenKeys[i];
            NSDictionary *token = self.tokens[key];
            if ([token[@"location"] integerValue] > 0) {
                int length = [token[@"location"] integerValue];
                if (length>0) {
                    nonCommentTokens[@0] = @{@"comment":@0, @"location":@(0), @"length":@(length)};
                }
                else {
                    continue;
                }
            }
        }
        else if (i == self.tokenKeys.count-1) {
            NSNumber *key = self.tokenKeys[i];
            NSDictionary *token = self.tokens[key];
            if ([token[@"location"] integerValue]+[token[@"length"] integerValue] < text.length) {
                NSUInteger location = [token[@"location"] integerValue] + [token[@"length"] integerValue];
                NSUInteger length = text.length-location;
                if (length==0) {
                    continue;
                }
                else {
                    nonCommentTokens[@(location)] = @{@"comment":@0, @"location":@(location), @"length":@(length)};
                }
            }
        }
        else {
            NSNumber *secondKey = self.tokenKeys[i];
            NSDictionary *secondToken = self.tokens[secondKey];
            NSNumber *firstKey = self.tokenKeys[i-1];
            NSDictionary *firstToken = self.tokens[firstKey];
            NSUInteger location = [firstToken[@"location"] integerValue] + [firstToken[@"length"] integerValue];
            NSUInteger length = [secondToken[@"location"] integerValue] - location;
            if (length==0) {
                continue;
            }
            else {
                nonCommentTokens[@(location)] = @{@"comment":@0, @"location":@(location), @"length":@(length-1)};
            }
        }
    }
    
    [self.tokens addEntriesFromDictionary:nonCommentTokens];
    self.tokenKeys = [[[self.tokens allKeys] sortedArrayUsingSelector: @selector(compare:)] mutableCopy];
}

- (void)applyToken:(NSDictionary*)token {
    if (token) {
        NSRange range = NSMakeRange([token[@"location"] integerValue], [token[@"length"] integerValue]);
        if ([token[@"comment"] isEqualToNumber:@YES]) {
            [self.myRichTextEditor applyAttributes:self.commentColor forKey:NSForegroundColorAttributeName atRange:range];
        }
        else {
            [self.myRichTextEditor removeAttributeForKey:NSForegroundColorAttributeName atRange:range];
        }
    }
}

//- (void)applyOldToken:(NSDictionary*)oldToken newToken:(NSDictionary*)newToken {
//    if (oldToken) {
//        NSRange oldRange = NSMakeRange([oldToken[@"location"] integerValue], [oldToken[@"length"] integerValue]);
//        [self.myRichTextEditor removeAttributeForKey:NSForegroundColorAttributeName atRange:oldRange];
//    }
//
//    if (newToken) {
//        NSRange range = NSMakeRange([newToken[@"location"] integerValue], [newToken[@"length"] integerValue]);
//        if ([newToken[@"comment"] isEqualToNumber:@YES]) {
//            [self.myRichTextEditor applyAttributes:self.commentColor forKey:NSForegroundColorAttributeName atRange:range];
//        }
//        else {
//            [self.myRichTextEditor removeAttributeForKey:NSForegroundColorAttributeName atRange:range];
//        }
//    }
//}

- (void)applyCommentText {
    [self.myRichTextEditor removeAttributeForKey:NSForegroundColorAttributeName atRange:NSMakeRange(0, self.myRichTextEditor.text.length)];
    for (NSNumber *tokenKey in self.tokens) {
        NSDictionary *newToken = self.tokens[tokenKey];
        [self applyToken:newToken];
    }
}

- (BOOL)text:(NSString*)text range:(NSRange)range leftNeighbor:(NSString*)left rightNeighbor:(NSString*)right  {
    if (text.length < range.location+range.length+1) {
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
