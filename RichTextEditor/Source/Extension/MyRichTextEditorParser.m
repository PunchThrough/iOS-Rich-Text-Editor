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
    
    NSDictionary *commentsDic = [self.helper occurancesOfString:@[@"//",@"/*",@"*/",@"\n",@"\"",@"'"] text:text];
    NSArray *commentKeys = [[commentsDic allKeys] sortedArrayUsingSelector: @selector(compare:)];
    CommentState state = CommentStateUnknown;
    NSNumber *prevKey;
    NSNumber *key;
    for (int j=0; j<commentKeys.count; j++) {
        key = commentKeys[j];
        NSString *symbol = commentsDic[key];
        if ([symbol isEqualToString:@"/*"]) {
            if (state != CommentStateSlashSlash && state != CommentStateSlashStar) {
                state = CommentStateSlashStar;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"*/"]) {
            if (state == CommentStateSlashStar) {
                // found /* */
                tokens[prevKey] = @{@"comment":@1, @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"*/".length)};
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
                tokens[prevKey] = @{@"comment":@1, @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
            }
        }
    }
    
    if (state == CommentStateSlashStar) {
        key = @(text.length);
        tokens[prevKey] = @{@"comment":@1, @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
    else if (state == CommentStateSlashSlash) {
        key = @(text.length);
        tokens[prevKey] = @{@"comment":@1, @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
    
    // calculate non comment spaces
    NSMutableDictionary *nonCommentTokens = [@{} mutableCopy];
    NSArray *sortedKeys = [[tokens allKeys] sortedArrayUsingSelector: @selector(compare:)];
    for (int i=0;i<sortedKeys.count;i++) {
        if (i == 0) {
            NSNumber *key = sortedKeys[i];
            NSDictionary *token = tokens[key];
            if ([token[@"location"] integerValue] > 0) {
                int length = [token[@"location"] intValue];
                if (length>0) {
                    nonCommentTokens[@0] = @{@"comment":@0, @"location":@(0), @"length":@(length)};
                }
                else {
                    continue;
                }
            }
        }
        else if (i == sortedKeys.count-1) {
            NSNumber *key = sortedKeys[i];
            NSDictionary *token = tokens[key];
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
                nonCommentTokens[@(location)] = @{@"comment":@0, @"location":@(location), @"length":@(length)};
            }
        }
    }
    
    [tokens addEntriesFromDictionary:nonCommentTokens];
    sortedKeys = [[[tokens allKeys] sortedArrayUsingSelector: @selector(compare:)] mutableCopy];
    [tokenKeys addObjectsFromArray:sortedKeys];
}

@end
