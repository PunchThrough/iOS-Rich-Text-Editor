//
//  MyRichTextEditorParser.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/25/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditorParser.h"
#import "MyRichTextEditorHelper.h"

typedef enum {
	CommentStateSlashSlash = 1,
    CommentStateSlashStar,
    CommentStateStarSlash,
    CommentStateReturn,
    CommentStateSlashNone
} CommentState;

typedef enum {
	StringStateTick = 1,
    StringStateQuote,
    StringStateNone
} StringState;


@interface MyRichTextEditorParser()
@property (nonatomic, strong) MyRichTextEditorHelper *helper;
@end

@implementation MyRichTextEditorParser

- (id)init {
    self = [super init];
    if (self) {
        self.helper = [[MyRichTextEditorHelper alloc] init];
    }
    return self;
}

// parses the text into segments based on comment symbols

- (void)parseText:(NSString*)text segment:(NSMutableDictionary*)segments segmentKeys:(NSMutableArray*)segmentKeys  {
    [segments removeAllObjects];
    [segmentKeys removeAllObjects];
    
    [self parseCommentsText:text segments:segments];
    NSMutableDictionary *nonCommentTokens = [self parseNonCommentsText:text segments:segments];
    [self parseStringText:text nonCommentSegments:nonCommentTokens];
    
    [segments addEntriesFromDictionary:nonCommentTokens];
    NSArray *sortedKeys = [[[segments allKeys] sortedArrayUsingSelector: @selector(compare:)] mutableCopy];
    [segmentKeys addObjectsFromArray:sortedKeys];
}

- (void)parseCommentsText:(NSString*)text segments:(NSMutableDictionary*)segments {
    NSMutableDictionary *symbolsDic = [self.helper occurancesOfString:@[@"\\/\\/",@"\\/\\*",@"\\*\\/",@"\n", @"^\"",@"[^\\\\]\"",@"[^\\\\]'"] text:text];
    
    for (NSNumber *num in [symbolsDic copy]) {
        NSString *val = symbolsDic[num];
        if (val.length==2 && ([val hasSuffix:@"\'"] || [val hasSuffix:@"\""])) {
            [symbolsDic removeObjectForKey:num];
            symbolsDic[@([num intValue]+1)] = [val substringFromIndex:1];
        }
    }
    
    NSArray *symbolKeys = [[symbolsDic allKeys] sortedArrayUsingSelector: @selector(compare:)];
    CommentState commentState = CommentStateSlashNone;
    StringState stringState = StringStateNone;
    NSNumber *prevKey;
    NSNumber *key;
    NSNumber *prevNewline = @(0);
    
    // comment ruleset
    for (int j=0; j<symbolKeys.count; j++) {
        key = symbolKeys[j];
        NSString *symbol = symbolsDic[key];
        if ([symbol isEqualToString:@"/*"]) {
            if (commentState != CommentStateSlashSlash && commentState != CommentStateSlashStar) {
                commentState = CommentStateSlashStar;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"*/"]) {
            if (commentState == CommentStateSlashStar) {
                // found /* */
                segments[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"*/".length)};
                prevNewline = key;
                commentState = CommentStateSlashNone;
            }
        }
        else if ([symbol isEqualToString:@"//"]) {
            if (commentState != CommentStateSlashStar) {
                commentState = CommentStateSlashSlash;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"'"]) {
            if (stringState == StringStateQuote) {
                continue;
            }
            else if (stringState == StringStateTick) {
                segments[prevKey] = @{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\'".length)};
                stringState = StringStateNone;
            }
            else {
                stringState = StringStateTick;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"\""]) {
            if (stringState == StringStateTick) {
                continue;
            }
            else if (stringState == StringStateQuote) {
                // quote found
                segments[prevKey] = @{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\"".length)};
                stringState = StringStateNone;
            }
            else {
                stringState = StringStateQuote;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"\n"]) {
            if (commentState == CommentStateSlashSlash) {
                segments[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\n".length)};
                commentState = CommentStateSlashNone;
            }
            else if (commentState == CommentStateSlashNone) {
                segments[prevKey] = @{@"type":@"code-line", @"location":prevNewline, @"length":@([key integerValue]-[prevNewline integerValue]+@"\n".length)};
            }
            else if (stringState == StringStateQuote || stringState == StringStateTick) {
                segments[prevKey] = @{@"type":@"invalid-string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\"".length)};
                stringState = StringStateNone;
            }
            prevNewline = key;
        }
    }
    
    if (commentState == CommentStateSlashStar) {
        key = @(text.length);
        segments[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
    else if (commentState == CommentStateSlashSlash) {
        key = @(text.length);
        segments[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
}

- (NSMutableDictionary*)parseNonCommentsText:(NSString*)text segments:(NSMutableDictionary*)segments {
    NSMutableDictionary *nonCommentSegments = [@{} mutableCopy];
    NSArray *sortedKeys = [[segments allKeys] sortedArrayUsingSelector: @selector(compare:)];
    for (int i=0;i<sortedKeys.count;i++) {
        // case where BOF code /* comment
        if (i == 0) {
            NSNumber *key = sortedKeys[i];
            NSDictionary *segment = segments[key];
            if ([segment[@"location"] integerValue] > 0) {
                int length = [segment[@"location"] intValue];
                if (length>0) {
                    nonCommentSegments[@0] = @{@"type":@"code", @"location":@(0), @"length":@(length)};
                }
                else {
                    continue;
                }
            }
        }
        if (i == sortedKeys.count-1) {
            NSNumber *key = sortedKeys[i];
            NSDictionary *segment = segments[key];
            // case where /* comment */ code EOF
            if ([segment[@"location"] integerValue]+[segment[@"length"] integerValue] < (text.length-1)) {
                NSUInteger location = [segment[@"location"] integerValue] + [segment[@"length"] integerValue];
                NSUInteger length = (text.length)-location;
                if (length==0) {
                    continue;
                }
                else {
                    nonCommentSegments[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
                }
            }
            // case where /* comment */ EOF
            else if (i>0) {
                NSNumber *secondKey = sortedKeys[i];
                NSDictionary *secondSegment = segments[secondKey];
                NSNumber *firstKey = sortedKeys[i-1];
                NSDictionary *firstSegment = segments[firstKey];
                NSUInteger location = [firstSegment[@"location"] integerValue] + [firstSegment[@"length"] integerValue];
                NSUInteger length = [secondSegment[@"location"] integerValue] - location;
                if (length==0) {
                    continue;
                }
                else {
                    nonCommentSegments[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
                }
            }
        }
        
        // case where BOF /* first comment */ code and comments /* last comment */ EOF
        if (i > 0 && i < sortedKeys.count-1) {
            NSNumber *secondKey = sortedKeys[i];
            NSDictionary *secondSegment = segments[secondKey];
            NSNumber *firstKey = sortedKeys[i-1];
            NSDictionary *firstSegment = segments[firstKey];
            NSUInteger location = [firstSegment[@"location"] integerValue] + [firstSegment[@"length"] integerValue];
            NSUInteger length = [secondSegment[@"location"] integerValue] - location;
            if (length==0) {
                continue;
            }
            else {
                nonCommentSegments[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
            }
        }
    }
    
    if (sortedKeys.count == 0) {
        nonCommentSegments[@(0)] = @{@"type":@"code", @"location":@(0), @"length":@(text.length)};
    }
    
    return nonCommentSegments;
}

- (void)parseStringText:(NSString*)text nonCommentSegments:(NSMutableDictionary*)nonCommentSegments {
    NSArray *sortedKeys = [[nonCommentSegments allKeys] sortedArrayUsingSelector: @selector(compare:)];
    for (int j=0;j<sortedKeys.count;j++) {
        NSString *segmentKey = sortedKeys[j];
        NSDictionary *nonCommentSegment = nonCommentSegments[segmentKey];

        NSString *nonComment = [text substringWithRange:NSMakeRange([nonCommentSegment[@"location"] integerValue], [nonCommentSegment[@"length"] integerValue])];
        NSDictionary *incorrectNonCommentDic = [self.helper occurancesOfString:@[@"^\"",@"[^\\\\]\"",@"[^\\\\]'", @"\n"] text:nonComment];
        NSMutableDictionary *nonCommentDic = [@{} mutableCopy];
        for (NSNumber *num in incorrectNonCommentDic) {
            NSString *val = incorrectNonCommentDic[num];
            if (val.length>1) {
                nonCommentDic[@([num intValue]+1)] = [val substringFromIndex:1];
            }
            else {
                nonCommentDic[num] = val;
            }
        }
        
        NSArray *nonCommentKeys = [[nonCommentDic allKeys] sortedArrayUsingSelector: @selector(compare:)];
        NSNumber *prevKey;
        NSNumber *key;
        StringState stringState = StringStateNone;
        NSMutableArray *strArr = nil;
        // ruleset,
        for (int j=0; j<nonCommentKeys.count; j++) {
            key = nonCommentKeys[j];
            NSString *symbol = nonCommentDic[key];
            if ([symbol isEqualToString:@"'"]) {
                if (stringState == StringStateQuote) {
                    continue;
                }
                else if (stringState == StringStateTick) {
                    // quote found
                    if (!strArr) {
                        strArr = [@[] mutableCopy];
                    }
                    NSDictionary *str = @{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\'".length)};
                    [strArr addObject:str];
                    stringState = StringStateNone;
                }
                else {
                    stringState = StringStateTick;
                    prevKey = key;
                }
            }
            else if ([symbol isEqualToString:@"\""]) {
                if (stringState == StringStateTick) {
                    continue;
                }
                else if (stringState == StringStateQuote) {
                    // quote found
                    if (!strArr) {
                        strArr = [@[] mutableCopy];
                    }
                    NSDictionary *str = @{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\"".length)};
                    [strArr addObject:str];
                    stringState = StringStateNone;
                }
                else {
                    stringState = StringStateQuote;
                    prevKey = key;
                }
            }
            else if ([symbol isEqualToString:@"\n"]) {
                if (stringState == StringStateQuote || stringState == StringStateTick) {
                    // quote found
                    if (!strArr) {
                        strArr = [@[] mutableCopy];
                    }
                    NSDictionary *str = @{@"type":@"invalid-string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\"".length)};
                    [strArr addObject:str];
                    stringState = StringStateNone;
                }
            }
        }
        
        if (stringState == StringStateTick) {
            key = @(nonComment.length);
            if (!strArr) {
                strArr = [@[] mutableCopy];
            }
            [strArr addObject:@{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])}];
            
        }
        else if (stringState == StringStateQuote) {
            key = @(nonComment.length);
            if (!strArr) {
                strArr = [@[] mutableCopy];
            }
            [strArr addObject:@{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])}];
        }

        
        NSMutableDictionary *temp = [nonCommentSegment mutableCopy];
        if (strArr) {
            temp[@"strings"] = strArr;
            nonCommentSegments[segmentKey] = temp;
        }
    }
}
@end
