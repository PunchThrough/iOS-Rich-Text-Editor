//
//  MyRichTextEditorHelper.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditor.h"

@interface MyRichTextEditorHelper : NSObject 
- (NSMutableDictionary*)occurancesOfString:(NSArray*)strArray text:(NSString*)text addCaptureParen:(BOOL)addParen;
- (BOOL)text:(NSString*)text range:(NSRange)range leftNeighbor:(NSString*)left rightNeighbor:(NSString*)right;
- (NSDictionary*)tokenForRange:(NSRange)range fromTokens:(NSDictionary*)tokens;
- (NSMutableArray*)tokensForRange:(NSRange)wholeRange fromTokens:(NSDictionary*)tokens tokenKeys:(NSArray*)tokenKeys;
- (BOOL)isNumber:(NSString*)text;
- (NSUInteger)viewHeightForText:(NSString*)text textView:(UITextView*)textView;
@end
