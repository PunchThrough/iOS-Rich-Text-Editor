//
//  RichTextEditorTests.m
//  RichTextEditorTests
//
//  Created by Aryan Gh on 5/4/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditorTests.h"
#import "MyRichTextEditorHelper.h"

@interface RichTextEditorTests()
@property (nonatomic, strong) NSString *myText;
@end

@implementation RichTextEditorTests

- (void)setUp
{
    [super setUp];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"examplesketch" ofType:@"ino"];
    self.myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

#define CURRENT_IMPL_FIRST 1

#if CURRENT_IMPL_FIRST == 1
- (void)testFunctionCurrentImpl1
{
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    NSMutableDictionary *dic = [helper occurancesOfString:@[@"//",@"/*",@"*/",@"\n"] text:self.myText];
    
    XCTAssertTrue([dic allKeys].count == 359, @"");
}

- (void)testFunctionCurrentImpl2
{
    self.myText = [NSString stringWithFormat:@"%@\n\n/* added comment */", self.myText];

    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    NSMutableDictionary *dic = [helper occurancesOfString:@[@"//",@"/*",@"*/",@"\n"] text:self.myText];
    
    XCTAssertTrue([dic allKeys].count == 359+4, @"");
}

#else

- (void)testFunctionRegexImpl1
{
    NSMutableArray *arr = [@[] mutableCopy];
    NSError *error = NULL;
    // regex for // /* */ \n
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\/\\/|\\/\\*|\\*\\/|\\\n)" options:nil error:&error];
    if (error) {
        NSLog(@"Couldn't create regex with given string and options");
    }
    
    NSArray *matches = [regex matchesInString:self.myText options:0 range:NSMakeRange(0, self.myText.length)];
    
    // 6: Iterate through the matches and highlight them
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        [arr addObject:[NSValue valueWithRange:matchRange]];
    }
    
    XCTAssertTrue(arr.count == 359, @"");
}

- (void)testFunctionRegexImpl2
{
    self.myText = [NSString stringWithFormat:@"%@\n\n/* added comment */", self.myText];
    
    // experimental impl
    NSMutableArray *arr = [@[] mutableCopy];
    NSError *error = NULL;
    // regex for // /* */ \n
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\/\\/|\\/\\*|\\*\\/|\\\n)" options:nil error:&error];
    if (error) {
        NSLog(@"Couldn't create regex with given string and options");
    }
    
    NSArray *matches = [regex matchesInString:self.myText options:0 range:NSMakeRange(0, self.myText.length)];
    
    // 6: Iterate through the matches and highlight them
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        [arr addObject:[NSValue valueWithRange:matchRange]];
    }
    
    XCTAssertTrue(arr.count == 359+4, @"");
}

#endif

@end
