//
//  MyRichTextEditorParser.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/25/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyRichTextEditorParser : NSObject
- (void)parseText:(NSString*)text segment:(NSMutableDictionary*)segments segmentKeys:(NSMutableArray*)segmentKeys keywords:(NSDictionary*)keywords;
@end
