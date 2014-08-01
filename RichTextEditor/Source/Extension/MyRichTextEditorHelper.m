//
//  MyRichTextEditorHelper.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditorHelper.h"

@interface MyRichTextEditorHelper()
@property (nonatomic, strong) UITextView *tempTextView;
@end

@implementation MyRichTextEditorHelper

- (NSDictionary*)tokenForRange:(NSRange)range fromTokens:(NSDictionary*)tokens {
    NSUInteger min = NSUIntegerMax;
    NSNumber *keyToken;
    for (NSNumber *key in tokens) {
        int diff = abs((int)[key unsignedIntegerValue] - (int)range.location);
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


- (NSMutableDictionary*)occurancesOfString:(NSArray*)strArray text:(NSString*)text addCaptureParen:(BOOL)addParen {
    NSError *error=NULL;
    NSMutableArray *temp = [@[] mutableCopy];
    for (NSString *str in strArray) {
        [temp addObject:str];
    }

    NSString *pattern;;
    if (addParen) {
        pattern = [NSString stringWithFormat:@"(%@)", [temp componentsJoinedByString:@"|"]];
    }
    else {
        pattern = [NSString stringWithFormat:@"%@", [temp componentsJoinedByString:@"|"]];
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:nil error:&error];
    if (error) {
        NSLog(@"Couldn't create regex with given string and options %@", [error localizedDescription]);
    }
    
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    NSMutableDictionary *retDic = [@{} mutableCopy];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        retDic[@(matchRange.location)] = [text substringWithRange:matchRange];
    }
    
    return retDic;
}

- (BOOL)isNumber:(NSString*)text {
    
    if (text == nil || text.length == 0) {
        return NO;
    }
    NSError *error=NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d(x|b)?\\d*" options:nil error:&error];
    if (error) {
        NSLog(@"Couldn't create regex with given string and options %@", [error localizedDescription]);
    }
    
    NSRange textRange = NSMakeRange(0, text.length);
    NSRange matchRange = [regex rangeOfFirstMatchInString:text options:NSMatchingReportCompletion range:textRange];
    
    return (matchRange.location != NSNotFound && matchRange.length == textRange.length);
}

@end
