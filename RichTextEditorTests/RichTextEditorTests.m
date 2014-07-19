//
//  RichTextEditorTests.m
//  RichTextEditorTests
//
//  Created by Aryan Gh on 5/4/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditorTests.h"
#import "MyRichTextEditorHelper.h"

@implementation RichTextEditorTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testFunction1
{
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    UITextView *textView = [[UITextView alloc] init];
    textView.text = @"void myFunction() {}";
    NSRange range = NSMakeRange(textView.text.length-1, 0);
    [helper textView:textView shouldChangeTextInRange:range replacementText:@"\n"];
    NSString *result = @"void myFunction() {\n    \n}";
    XCTAssertTrue([textView.text isEqualToString:result], @"");
    XCTAssertEqual(textView.selectedRange.location, result.length-2, @"");
}

- (void)testFunction2
{
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    UITextView *textView = [[UITextView alloc] init];
    textView.text = @"void myFunction()\n{}";
    NSRange range = NSMakeRange(textView.text.length-1, 0);
    [helper textView:textView shouldChangeTextInRange:range replacementText:@"\n"];
    NSString *result = @"void myFunction()\n{\n    \n}";
    XCTAssertTrue([textView.text isEqualToString:result], @"");
    XCTAssertEqual(textView.selectedRange.location, result.length-2, @"");
}


@end
