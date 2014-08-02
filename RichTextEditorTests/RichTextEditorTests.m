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
#import "NSAttributedString+MyRichTextEditor.h"

@interface RichTextEditorTests()
@property (nonatomic, strong) NSString *largeSketch;
@property (nonatomic, strong) NSString *largeSketchTestString;
@property (nonatomic, strong) NSMutableDictionary *keywordsDic;
@property (nonatomic, strong) MyRichTextEditorHelper *helper;
@property (nonatomic, strong) NSMutableDictionary *colorsDic;
@end

@implementation RichTextEditorTests

- (void)setUp
{
    [super setUp];
    
    self.helper = [[MyRichTextEditorHelper alloc] init];
    self.keywordsDic = [self.helper keywordsForPath:[[NSBundle mainBundle] pathForResource:@"keywords" ofType:@"txt"]];

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"largeTestSketch" ofType:@"ino"];
    self.largeSketch = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
    
    filePath = [[NSBundle mainBundle] pathForResource:@"textColors" ofType:@"json"];
    self.colorsDic = [self.helper colorsForPath:filePath];

    filePath = [[NSBundle mainBundle] pathForResource:@"largeTextSketchTest" ofType:@"txt"];
    self.largeSketchTestString = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testRegex
{
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    NSMutableDictionary *dic = [helper occurancesOfString:@[@"\\/\\/",@"\\/\\*",@"\\*\\/",@"\n",@"(.?)\"",@"(.?)'"]  text:self.largeSketch addCaptureParen:YES];
    
    XCTAssertTrue([dic allKeys].count == 419, @"");
}

- (void)testBuildAttrString
{
    MyRichTextEditorParser *parser = [[MyRichTextEditorParser alloc] init];
    NSMutableDictionary *segments = [@{} mutableCopy];
    NSMutableArray *segmentKeys = [@[] mutableCopy];
    [parser parseText:self.largeSketch segment:segments segmentKeys:segmentKeys keywords:self.keywordsDic];
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:self.largeSketch];
    [attr applySegments:[segments allValues] colorsDic:self.colorsDic];
    NSString *result = [attr description];
    XCTAssertEqualObjects(result, self.largeSketchTestString, @"");
}

- (void)testTextView
{
    MyRichTextEditor *editor = editor = [[MyRichTextEditor alloc] initWithLineNumbers:YES];
    [editor textView:editor shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@""];
    
}


//- (void)test
//{
//    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:@"firstsecondthird"];
//    [string addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0,5)];
//    [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(5,6)];
//    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(11,5)];
//    
//    NSRange r1;
//    NSDictionary *attr1 = [string attributesAtIndex:0 effectiveRange:&r1];
//    
//    
//}

@end
