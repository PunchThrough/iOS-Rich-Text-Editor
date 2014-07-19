//
//  MyRichTextEditorHelper.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditorHelper.h"

@interface MyRichTextEditorHelper()
@property (nonatomic, strong) NSMutableArray *brackets;
@end

@implementation MyRichTextEditorHelper 

- (id)init {
    self = [super init];
    if (self) {
        self.brackets = [@[] mutableCopy];
        self.indentation = @"    ";
    }
    return self;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        NSString *beginningText = [textView.text substringToIndex:range.location];
        NSUInteger leftBrackers = [self occurancesOfString:@"{" text:beginningText];
        NSUInteger rightBrackers = [self occurancesOfString:@"}" text:beginningText];
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

    return YES;
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

// from http://stackoverflow.com/questions/2166809/number-of-occurrences-of-a-substring-in-an-nsstring
- (NSUInteger)occurancesOfString:(NSString*)str text:(NSString*)text{
    NSUInteger count = 0, length = [text length];
    NSRange range = NSMakeRange(0, length);
    while(range.location != NSNotFound)
    {
        range = [text rangeOfString: str options:0 range:range];
        if(range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++; 
        }
    }
    return count;
}

@end
