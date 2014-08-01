//
//  RichTextEditorTests.m
//  RichTextEditorTests
//
//  Created by Aryan Gh on 5/4/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditorTests.h"
#import "MyRichTextEditorHelper.h"
#import "MyRichTextEditorParser.h"

@interface RichTextEditorTests()
@property (nonatomic, strong) NSString *largeSketch;
@property (nonatomic, strong) NSMutableDictionary *keywordsDic;
@property (nonatomic, strong) MyRichTextEditorHelper *helper;
@end

@implementation RichTextEditorTests

- (void)setUp
{
    [super setUp];
    
    self.helper = [[MyRichTextEditorHelper alloc] init];
    self.keywordsDic = [self.helper keywordsForPath:[[NSBundle mainBundle] pathForResource:@"keywords" ofType:@"txt"]];

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"largeTestSketch" ofType:@"ino"];
    self.largeSketch = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testFunctionRegex
{
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    NSMutableDictionary *dic = [helper occurancesOfString:@[@"\\/\\/",@"\\/\\*",@"\\*\\/",@"\n",@"(.?)\"",@"(.?)'"]  text:self.largeSketch addCaptureParen:YES];
    
    XCTAssertTrue([dic allKeys].count == 419, @"");
}

- (void)testFunctionParse
{
    MyRichTextEditorParser *parser = [[MyRichTextEditorParser alloc] init];
    NSMutableDictionary *segments = [@{} mutableCopy];
    NSMutableArray *segmentKeys = [@[] mutableCopy];
    [parser parseText:self.largeSketch segment:segments segmentKeys:segmentKeys keywords:self.keywordsDic];


}


- (void)test
{
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:@"firstsecondthird"];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0,5)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(5,6)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(11,5)];
    
    NSRange r1;
    NSDictionary *attr1 = [string attributesAtIndex:0 effectiveRange:&r1];
    
    
}

@end
