//
//  MyRichTextEditorParser.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/25/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyRichTextEditorParser : NSObject
- (void)parseText:(NSString*)text segment:(NSMutableArray*)segments keywords:(NSDictionary*)keywords;
@end
