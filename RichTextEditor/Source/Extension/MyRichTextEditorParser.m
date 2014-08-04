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

- (void)parseText:(NSString*)text segment:(NSMutableDictionary*)segments segmentKeys:(NSMutableArray*)segmentKeys keywords:(NSDictionary*)keywords {
    [segments removeAllObjects];
    [segmentKeys removeAllObjects];
    
    [self parseStringCommentsText:text segments:segments];
    NSMutableDictionary *otherSegments = [self otherSegmentsFromText:text segments:segments];
    [self tokenizeFromText:text otherSegments:otherSegments keywords:keywords];
    
    [segments addEntriesFromDictionary:otherSegments];
    NSArray *sortedKeys = [[[segments allKeys] sortedArrayUsingSelector: @selector(compare:)] mutableCopy];
    [segmentKeys addObjectsFromArray:sortedKeys];
}

- (void)parseStringCommentsText:(NSString*)text segments:(NSMutableDictionary*)segments {
    NSMutableDictionary *symbolsDic = [self.helper occurancesOfString:@[@"\\/\\/",@"\\/\\*",@"\\*\\/",@"\n",@"(.?)\"",@"(.?)'"] text:text addCaptureParen:YES];
    
    for (NSNumber *num in [symbolsDic copy]) {
        NSString *val = symbolsDic[num];
        if (val.length==2 && ([val hasSuffix:@"\'"] || [val hasSuffix:@"\""])) {
            [symbolsDic removeObjectForKey:num];
            if ([val isEqualToString:@"\\\""]) {
                [symbolsDic removeObjectForKey:num];
            }
            else {
                symbolsDic[@([num intValue]+1)] = [val substringFromIndex:1];
            }
        }
    }
    
    NSArray *symbolKeys = [[symbolsDic allKeys] sortedArrayUsingSelector: @selector(compare:)];
    CommentState commentState = CommentStateSlashNone;
    StringState stringState = StringStateNone;
    NSNumber *prevKey;
    NSNumber *key;
    
    // comment ruleset
    for (int j=0; j<symbolKeys.count; j++) {
        key = symbolKeys[j];
        NSString *symbol = symbolsDic[key];
        if ([symbol isEqualToString:@"/*"]) {
            if (stringState == StringStateTick || stringState == StringStateQuote) {
                // do nothing
            }
            else if (commentState != CommentStateSlashSlash && commentState != CommentStateSlashStar) {
                commentState = CommentStateSlashStar;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"*/"]) {
            if (commentState == CommentStateSlashStar) {
                // found /* */
                segments[prevKey] = @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"*/".length)};
                commentState = CommentStateSlashNone;
            }
        }
        else if ([symbol isEqualToString:@"//"]) {
            if (stringState == StringStateTick || stringState == StringStateQuote) {
                // do nothing
            }
            else if (commentState != CommentStateSlashStar) {
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
            else if (commentState == CommentStateSlashSlash || commentState == CommentStateSlashStar) {
                // do nothing
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
            else if (commentState == CommentStateSlashSlash || commentState == CommentStateSlashStar) {
                // do nothing
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
            else if (stringState == StringStateQuote || stringState == StringStateTick) {
                segments[prevKey] = @{@"type":@"invalid-string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\"".length)};
                stringState = StringStateNone;
            }
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
    if (stringState == StringStateTick) {
        key = @(text.length);
        segments[prevKey] = @{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
    else if (stringState == StringStateQuote) {
        key = @(text.length);
        segments[prevKey] = @{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])};
    }
}

- (NSMutableDictionary*)otherSegmentsFromText:(NSString*)text segments:(NSMutableDictionary*)segments {
    NSMutableDictionary *otherSegments = [@{} mutableCopy];
    NSArray *sortedKeys = [[segments allKeys] sortedArrayUsingSelector: @selector(compare:)];
    for (int i=0;i<sortedKeys.count;i++) {
        // case where BOF code /* comment
        if (i == 0) {
            NSNumber *key = sortedKeys[i];
            NSDictionary *segment = segments[key];
            if ([segment[@"location"] integerValue] > 0) {
                int length = [segment[@"location"] intValue];
                if (length>0) {
                    otherSegments[@0] = @{@"type":@"code", @"location":@(0), @"length":@(length)};
                }
                else {
                    continue;
                }
            }
        }
        if (i == sortedKeys.count-1) {
            NSNumber *key = sortedKeys[i];
            NSDictionary *segment = segments[key];
            // case where /* comment segment */ otherSegment EOF
            if ([segment[@"location"] integerValue]+[segment[@"length"] integerValue] < (text.length)) {
                NSUInteger location = [segment[@"location"] integerValue] + [segment[@"length"] integerValue];
                NSUInteger length = (text.length)-location;
                if (length==0) {
                    continue;
                }
                else {
                    otherSegments[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
                }
            }
            // case where code (firstSegment) /* comment segment (secondSegment) */ EOF
            if (i>0) {
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
                    otherSegments[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
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
                otherSegments[@(location)] = @{@"type":@"code", @"location":@(location), @"length":@(length)};
            }
        }
    }
    
    if (sortedKeys.count == 0) {
        otherSegments[@(0)] = @{@"type":@"code", @"location":@(0), @"length":@(text.length)};
    }
    
    return otherSegments;
}

- (void)tokenizeFromText:(NSString*)text otherSegments:(NSMutableDictionary*)segments keywords:(NSDictionary*)keywords {
    NSArray *sortedKeys = [[segments allKeys] sortedArrayUsingSelector: @selector(compare:)];
    for (int j=0;j<sortedKeys.count;j++) {
        NSString *segmentKey = sortedKeys[j];
        NSDictionary *segment = segments[segmentKey];
        NSString *segmentText = [text substringWithRange:NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue])];
        NSMutableDictionary *dic = [self.helper occurancesOfString:@[@"\\b((\\w)*)\\b"] text:segmentText addCaptureParen:NO];
        if (dic && dic.count>0) {
            for (NSNumber *key in dic) {
                NSString *val = dic[key];
                if (val.length==0) {
                    continue;
                }
                if (keywords[val]) {
                    if (!segments[segmentKey][@"keywords"]) {
                        if (![segments[segmentKey] isKindOfClass:[NSMutableDictionary class]]) {
                            segments[segmentKey] = [segment mutableCopy];
                        }
                        segments[segmentKey][@"keywords"] = [@[] mutableCopy];
                    }
                    [segments[segmentKey][@"keywords"] addObject:@{@"type":keywords[val], @"location":key, @"length":@(val.length)}];
                }
                else if ([self.helper isNumber:val]) {
                    if (!segments[segmentKey][@"numbers"]) {
                        if (![segments[segmentKey] isKindOfClass:[NSMutableDictionary class]]) {
                            segments[segmentKey] = [segment mutableCopy];
                        }
                        segments[segmentKey][@"numbers"] = [@[] mutableCopy];
                    }
                    [segments[segmentKey][@"numbers"] addObject:@{@"type":@"number", @"location":key, @"length":@(val.length)}];
                }
            }
        }
    }
}

@end
