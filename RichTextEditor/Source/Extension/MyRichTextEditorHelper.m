//
//  MyRichTextEditorHelper.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditorHelper.h"

@interface MyRichTextEditorHelper()
@end

@implementation MyRichTextEditorHelper

- (NSDictionary*)tokenForRange:(NSRange)range fromTokens:(NSDictionary*)tokens {
    NSUInteger min = NSUIntegerMax;
    NSNumber *keyToken;
    for (NSNumber *key in tokens) {
        int diff = abs([key integerValue] - range.location);
        if (([key integerValue] <= range.location) && (diff <= min)) {
            min = diff;
            keyToken = key;
        }
    }
    if (keyToken) {
        NSDictionary *token = tokens[keyToken];
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

- (NSMutableArray*)tokensForRange:(NSRange)wholeRange fromTokens:(NSDictionary*)tokens tokenKeys:(NSArray*)tokenKeys {
    NSMutableArray *retArr = nil;
    for (NSNumber *key in tokenKeys) {
        NSDictionary *token = tokens[key];
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
// TODO : experiment with http://stackoverflow.com/questions/7489130/nsstring-find-parts-of-string-in-another-string

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
