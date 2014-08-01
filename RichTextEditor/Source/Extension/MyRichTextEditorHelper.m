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

// returns a segment that is in the location of the passed in range

- (NSDictionary*)segmentForRange:(NSRange)range fromSegments:(NSDictionary*)segments {
    NSUInteger min = NSUIntegerMax;
    NSNumber *segmentKey;
    for (NSNumber *key in segments) {
        int diff = abs((int)[key unsignedIntegerValue] - (int)range.location);
        if (([key integerValue] <= range.location) && (diff <= min)) {
            min = diff;
            segmentKey = key;
        }
    }
    // get the intersection of ranges between the range input and the range of the segment
    // we just found
    if (segmentKey) {
        NSDictionary *segment = segments[segmentKey];
        NSUInteger location = [segment[@"location"] integerValue];
        NSUInteger length = [segment[@"length"] integerValue];
        // handles case where NSIntersectionRange returns false positive
        if (range.location == 0 && range.length == 0) {
            if (location == 0) {
                return segment;
            }
        }
        else {
            NSRange intersectionRange = NSIntersectionRange(range, NSMakeRange(location, length));
            if (intersectionRange.length != 0 || intersectionRange.location != 0) {
                return segment;
            }
        }
    }
    return nil;
}

// returns the segments that are within the range

- (NSMutableArray*)segmentsForRange:(NSRange)range fromSegments:(NSDictionary*)segments segmentKeys:(NSArray*)segmentKeys {
    NSMutableArray *retArr = nil;
    for (NSNumber *key in segmentKeys) {
        NSDictionary *segment = segments[key];
        NSRange segmentRange = NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue]);
        NSRange intersectionRange = NSIntersectionRange(range, segmentRange);
        if (intersectionRange.length!= 0 || intersectionRange.location != 0) {
            if (!retArr) {
                retArr =  [@[] mutableCopy];
            }
            [retArr addObject:segment];
        }
    }
    return retArr;
}

// returns if the text is surrounded on the left and right

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

// returns a dic keyed by the location with a value of the string

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

// utility to determine if the text is a number

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

// returns a dic based on the arduino keywords file format

- (NSMutableDictionary*)keywordsForPath:(NSString*)filePath {
    NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
    NSArray *arr = [myText componentsSeparatedByString:@"\n"];
    NSMutableDictionary *keywordsDic = [@{} mutableCopy];
    for (NSString *line in arr) {
        if ([line hasPrefix:@"#"]) {
            continue;
        }
        
        // arduino file tends to have text \t text \t text but sometimes has an empty second text, so
        // in that case, we're checking the third one
        NSArray *words = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (words.count >= 2) {
            if (((NSString*)words[1]).length == 0 && words.count>=3) {
                keywordsDic[words[0]] = words[2];
            }
            else {
                keywordsDic[words[0]] = words[1];
            }
        }
    }
    return keywordsDic;
}

// returns a dic of colors mapping to a data type

- (NSMutableDictionary*)colorsForPath:(NSString*)filePath {
    NSMutableDictionary *colorsDic = [@{} mutableCopy];
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
            colorsDic[@"comment"] = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"invalid-string"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            colorsDic[@"invalid-string"] = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"string"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            colorsDic[@"string"] = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"keywords"];
        if (temp) {
            for (NSDictionary *dic in temp) {
                for (NSString *key in dic) {
                    NSArray *val = dic[key];
                    colorsDic[key] = [UIColor colorWithRed:[val[0] floatValue] green:[val[1] floatValue] blue:[val[2] floatValue] alpha:1];
                }
            }
        }
    }
    return colorsDic;
}


@end
