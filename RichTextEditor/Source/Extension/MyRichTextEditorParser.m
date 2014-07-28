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
	CommentStateUnknown = 1,
	CommentStateSlashSlash,
    CommentStateSlashStar,
    CommentStateStarSlash,
    CommentStateReturn,
    CommentStateSlashNone
} CommentState;

typedef enum {
	StringStateUnknown = 1,
	StringStateTick,
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

// parses the text into tokens based on comment symbols

- (void)parseText:(NSString*)text tokens:(NSMutableDictionary*)tokens tokenKeys:(NSMutableArray*)tokenKeys  {
    [tokens removeAllObjects];
    [tokenKeys removeAllObjects];
    
    [self parseCommentsText:text tokens:tokens];
    NSMutableDictionary *nonCommentTokens = [self parseNonCommentsText:text tokens:tokens tokenKeys:tokenKeys];
    [self parseStringText:text nonCommentTokens:nonCommentTokens];
}

- (void)parseCommentsText:(NSString*)text tokens:(NSMutableDictionary*)tokens {
    NSDictionary *commentsDic = [self.helper occurancesOfString:@[@"//",@"/*",@"*/",@"\n"] text:text];
    NSArray *commentKeys = [[commentsDic allKeys] sortedArrayUsingSelector: @selector(compare:)];
    CommentState commentState = CommentStateUnknown;
    NSNumber *prevKey;
    NSNumber *key;
    
    // comment ruleset
    for (int j=0; j<commentKeys.count; j++) {
        key = commentKeys[j];
        NSString *symbol = commentsDic[key];
        if ([symbol isEqualToString:@"/*"]) {
            if (commentState != CommentStateSlashSlash && commentState != CommentStateSlashStar) {
                commentState = CommentStateSlashStar;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"*/"]) {
            if (commentState == CommentStateSlashStar) {
                // found /* */
                tokens[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"*/".length)};
                commentState = CommentStateStarSlash;
            }
        }
        else if ([symbol isEqualToString:@"//"]) {
            if (commentState != CommentStateSlashStar) {
                commentState = CommentStateSlashSlash;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"\n"]) {
            if (commentState == CommentStateSlashSlash) {
                commentState = CommentStateReturn;
                tokens[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\n".length)};
            }
        }
    }
    
    if (commentState == CommentStateSlashStar) {
        key = @(text.length);
        tokens[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
    else if (commentState == CommentStateSlashSlash) {
        key = @(text.length);
        tokens[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
}

- (NSMutableDictionary*)parseNonCommentsText:(NSString*)text tokens:(NSMutableDictionary*)tokens tokenKeys:(NSMutableArray*)tokenKeys {
    NSMutableDictionary *nonCommentTokens = [@{} mutableCopy];
    NSArray *sortedKeys = [[tokens allKeys] sortedArrayUsingSelector: @selector(compare:)];
    for (int i=0;i<sortedKeys.count;i++) {
        // case where BOF code /* comment
        if (i == 0) {
            NSNumber *key = sortedKeys[i];
            NSDictionary *token = tokens[key];
            if ([token[@"location"] integerValue] > 0) {
                int length = [token[@"location"] intValue];
                if (length>0) {
                    nonCommentTokens[@0] = @{@"type":@"code", @"location":@(0), @"length":@(length)};
                }
                else {
                    continue;
                }
            }
        }
        if (i == sortedKeys.count-1) {
            NSNumber *key = sortedKeys[i];
            NSDictionary *token = tokens[key];
            // case where /* comment */ code EOF
            if ([token[@"location"] integerValue]+[token[@"length"] integerValue] < (text.length-1)) {
                NSUInteger location = [token[@"location"] integerValue] + [token[@"length"] integerValue];
                NSUInteger length = (text.length)-location;
                if (length==0) {
                    continue;
                }
                else {
                    nonCommentTokens[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
                }
            }
            // case where /* comment */ EOF
            else {
                NSNumber *secondKey = sortedKeys[i];
                NSDictionary *secondToken = tokens[secondKey];
                NSNumber *firstKey = sortedKeys[i-1];
                NSDictionary *firstToken = tokens[firstKey];
                NSUInteger location = [firstToken[@"location"] integerValue] + [firstToken[@"length"] integerValue];
                NSUInteger length = [secondToken[@"location"] integerValue] - location;
                if (length==0) {
                    continue;
                }
                else {
                    nonCommentTokens[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
                }
            }
        }
        
        // case where BOF /* first comment */ code and comments /* last comment */ EOF
        if (i > 0 && i < sortedKeys.count-1) {
            NSNumber *secondKey = sortedKeys[i];
            NSDictionary *secondToken = tokens[secondKey];
            NSNumber *firstKey = sortedKeys[i-1];
            NSDictionary *firstToken = tokens[firstKey];
            NSUInteger location = [firstToken[@"location"] integerValue] + [firstToken[@"length"] integerValue];
            NSUInteger length = [secondToken[@"location"] integerValue] - location;
            if (length==0) {
                continue;
            }
            else {
                nonCommentTokens[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
            }
        }
    }
    
    // TODO : handle case where only 1 key
    
    [tokens addEntriesFromDictionary:nonCommentTokens];
    
    sortedKeys = [[[tokens allKeys] sortedArrayUsingSelector: @selector(compare:)] mutableCopy];
    [tokenKeys addObjectsFromArray:sortedKeys];

    return nonCommentTokens;
}

- (void)parseStringText:(NSString*)text nonCommentTokens:(NSMutableDictionary*)nonCommentTokens {
    NSArray *sortedKeys = [[nonCommentTokens allKeys] sortedArrayUsingSelector: @selector(compare:)];
    for (int j=0;j<sortedKeys.count;j++) {
        NSString *segmentKey = sortedKeys[j];
        NSDictionary *nonCommentSegment = nonCommentTokens[segmentKey];
        NSString *nonComment = [text substringWithRange:NSMakeRange([nonCommentSegment[@"location"] integerValue], [nonCommentSegment[@"length"] integerValue])];
        NSDictionary *nonCommentDic = [self.helper occurancesOfString:@[@"\"",@"'"] text:nonComment];
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
                if (stringState == StringStateTick) {
                    // quote found
                    if (!strArr) {
                        strArr = [@[] mutableCopy];
                    }
                    NSDictionary *str = @{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
                    [strArr addObject:str];
                    stringState = StringStateNone;
                }
                stringState = StringStateTick;
                prevKey = key;
            }
            else if ([symbol isEqualToString:@"\""]) {
                if (stringState == StringStateQuote) {
                    // quote found
                    if (!strArr) {
                        strArr = [@[] mutableCopy];
                    }
                    NSDictionary *str = @{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\"".length)};
                    [strArr addObject:str];
                    stringState = StringStateNone;
                }
                stringState = StringStateQuote;
                prevKey = key;
            }
        }
        NSMutableDictionary *temp = [nonCommentSegment mutableCopy];
        if (strArr) {
            temp[@"strings"] = strArr;
            nonCommentTokens[segmentKey] = temp;
        }
    }
}
@end
