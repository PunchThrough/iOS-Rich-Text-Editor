//
//  RichTextEditorTests.m
//  RichTextEditorTests
//
//  Created by Aryan Gh on 5/4/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditorTests.h"
#import "MyRichTextEditorHelper.h"
#import "MyRichTextEditor.h"

@implementation RichTextEditorTests

// where | is the cursor

//  void myFunction() {|}

- (void)testFunction1 {
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    helper.indentation = @"    ";
    MyRichTextEditor *textView = [[MyRichTextEditor alloc] init];
    textView.text = @"void myFunction() {}";
    NSRange range = NSMakeRange(textView.text.length-1, 0);
    [helper textView:textView shouldChangeTextInRange:range replacementText:@"\n"];
    NSString *result = @"void myFunction() {\n    \n}";
    XCTAssertTrue([textView.text isEqualToString:result], @"");
    XCTAssertEqual(textView.selectedRange.location, result.length-2, @"");
}

// void myFunction()\n{|}

- (void)testFunction2 {
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    helper.indentation = @"    ";
    MyRichTextEditor *textView = [[MyRichTextEditor alloc] init];
    textView.text = @"void myFunction()\n{}";
    NSRange range = NSMakeRange(textView.text.length-1, 0);
    [helper textView:textView shouldChangeTextInRange:range replacementText:@"\n"];
    NSString *result = @"void myFunction()\n{\n    \n}";
    XCTAssertTrue([textView.text isEqualToString:result], @"");
    XCTAssertEqual(textView.selectedRange.location, result.length-2, @"");
}

// testing indendation of 1 {}{}{{{{}}}|

- (void)testIndentation1 {
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    helper.indentation = @"    ";
    MyRichTextEditor *textView = [[MyRichTextEditor alloc] init];
    textView.text = @"{}{}{{{{}}}";
    NSRange range = NSMakeRange(textView.text.length, 0);
    [helper textView:textView shouldChangeTextInRange:range replacementText:@"\n"];
    NSString *result =  @"{}{}{{{{}}}\n    ";
    XCTAssertTrue([textView.text isEqualToString:result], @"");
    XCTAssertEqual(textView.selectedRange.location, result.length, @"");
}

// testing indendation of 1 {}{}{{{{}}|}

- (void)testIndentation2 {
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    helper.indentation = @"    ";
    MyRichTextEditor *textView = [[MyRichTextEditor alloc] init];
    textView.text = @"{}{}{{{{}}}";
    NSRange range = NSMakeRange(textView.text.length-1, 0);
    [helper textView:textView shouldChangeTextInRange:range replacementText:@"\n"];
    NSString *result =  @"{}{}{{{{}}\n        }";
    XCTAssertTrue([textView.text isEqualToString:result], @"");
    XCTAssertEqual(textView.selectedRange.location, result.length-1, @"");
}

// testing // abc \n def then // abc \n de//f

- (void)testAddComments1 {
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    MyRichTextEditor *textView = [[MyRichTextEditor alloc] init];
    textView.text = @"";
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(0, 1) replacementText:@"/"];
    NSAttributedString *attributedString1 = textView.attributedText;
    NSDictionary* myAttributes1 =[attributedString1 attributesAtIndex:0 effectiveRange:nil];
    XCTAssertTrue([myAttributes1 objectForKey:@"NSColor"]==nil, @"");
    
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(1, 1) replacementText:@"/"];
    NSAttributedString *attributedString2 = textView.attributedText;
    NSDictionary* myAttributes2 =[attributedString2 attributesAtIndex:1 effectiveRange:nil];
    XCTAssertTrue([myAttributes2[@"NSColor"] isEqual:[UIColor redColor]], @"");

    [helper textView:textView shouldChangeTextInRange:NSMakeRange(2, 1) replacementText:@" "];
    NSAttributedString *attributedString3 = textView.attributedText;
    NSDictionary* myAttributes3 =[attributedString3 attributesAtIndex:2 effectiveRange:nil];
    XCTAssertTrue([myAttributes3[@"NSColor"] isEqual:[UIColor redColor]], @"");

    [helper textView:textView shouldChangeTextInRange:NSMakeRange(3, 1) replacementText:@"a"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(4, 1) replacementText:@"b"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(5, 1) replacementText:@"c"];

    NSAttributedString *attributedString4 = textView.attributedText;
    NSDictionary* myAttributes4 =[attributedString4 attributesAtIndex:5 effectiveRange:nil];
    XCTAssertTrue([myAttributes4[@"NSColor"] isEqual:[UIColor redColor]], @"");

    [helper textView:textView shouldChangeTextInRange:NSMakeRange(6, 1) replacementText:@"\n"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(7, 1) replacementText:@" "];
    NSAttributedString *attributedString5 = textView.attributedText;
    NSDictionary* myAttributes5 =[attributedString5 attributesAtIndex:7 effectiveRange:nil];
    XCTAssertTrue([myAttributes5 objectForKey:@"NSColor"]==nil, @"");

    [helper textView:textView shouldChangeTextInRange:NSMakeRange(8, 1) replacementText:@"d"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(9, 1) replacementText:@"e"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(10, 1) replacementText:@"f"];
    NSAttributedString *attributedString6 = textView.attributedText;
    NSDictionary* myAttributes6 =[attributedString6 attributesAtIndex:10 effectiveRange:nil];
    XCTAssertTrue([myAttributes6 objectForKey:@"NSColor"]==nil, @"");

    textView.selectedRange = NSMakeRange(10, 0);
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(10, 1) replacementText:@"/"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(11, 1) replacementText:@"/"];

    NSAttributedString *attributedString7 = textView.attributedText;
    NSDictionary* myAttributes7 =[attributedString7 attributesAtIndex:10 effectiveRange:nil];
    XCTAssertTrue([myAttributes7[@"NSColor"] isEqual:[UIColor redColor]], @"");

    NSAttributedString *attributedString8 = textView.attributedText;
    NSDictionary* myAttributes8 =[attributedString8 attributesAtIndex:12 effectiveRange:nil];
    XCTAssertTrue([myAttributes8[@"NSColor"] isEqual:[UIColor redColor]], @"");
}

// testing /* abc */

- (void)testAddComments2 {
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    MyRichTextEditor *textView = [[MyRichTextEditor alloc] init];
    textView.text = @"";
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(0, 1) replacementText:@"/"];
    NSAttributedString *attributedString1 = textView.attributedText;
    NSDictionary* myAttributes1 =[attributedString1 attributesAtIndex:0 effectiveRange:nil];
    XCTAssertTrue([myAttributes1 objectForKey:@"NSColor"]==nil, @"");
    
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(1, 1) replacementText:@"*"];
    NSAttributedString *attributedString2 = textView.attributedText;
    NSDictionary* myAttributes2 =[attributedString2 attributesAtIndex:1 effectiveRange:nil];
    XCTAssertTrue([myAttributes2[@"NSColor"] isEqual:[UIColor redColor]], @"");

    [helper textView:textView shouldChangeTextInRange:NSMakeRange(2, 1) replacementText:@" "];
    
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(3, 1) replacementText:@"a"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(4, 1) replacementText:@"b"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(5, 1) replacementText:@"c"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(6, 1) replacementText:@" "];

    NSAttributedString *attributedString3 = textView.attributedText;
    NSDictionary* myAttributes3 =[attributedString3 attributesAtIndex:6 effectiveRange:nil];
    XCTAssertTrue([myAttributes3[@"NSColor"] isEqual:[UIColor redColor]], @"");

    [helper textView:textView shouldChangeTextInRange:NSMakeRange(7, 1) replacementText:@"*"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(8, 1) replacementText:@"/"];
    NSAttributedString *attributedString4 = textView.attributedText;
    NSDictionary* myAttributes4 =[attributedString4 attributesAtIndex:8 effectiveRange:nil];
    XCTAssertTrue([myAttributes4[@"NSColor"] isEqual:[UIColor redColor]], @"");
}

// testing / abc */ d then add /* abc */ d

- (void)testAddComments3 {
    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
    MyRichTextEditor *textView = [[MyRichTextEditor alloc] init];
    textView.text = @"";
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(0, 1) replacementText:@"/"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(1, 1) replacementText:@" "];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(2, 1) replacementText:@"a"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(3, 1) replacementText:@"b"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(4, 1) replacementText:@"c"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(5, 1) replacementText:@" "];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(6, 1) replacementText:@"*"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(7, 1) replacementText:@"/"];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(8, 1) replacementText:@" "];
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(9, 1) replacementText:@"d"];
    NSAttributedString *attributedString1 = textView.attributedText;
    NSDictionary* myAttributes1 =[attributedString1 attributesAtIndex:0 effectiveRange:nil];
    XCTAssertTrue([myAttributes1 objectForKey:@"NSColor"]==nil, @"");

    NSAttributedString *attributedString2 = textView.attributedText;
    NSDictionary* myAttributes2 =[attributedString2 attributesAtIndex:9 effectiveRange:nil];
    XCTAssertTrue([myAttributes2 objectForKey:@"NSColor"]==nil, @"");

    textView.selectedRange = NSMakeRange(1, 0);
    [helper textView:textView shouldChangeTextInRange:NSMakeRange(1, 1) replacementText:@"*"];
    NSAttributedString *attributedString3 = textView.attributedText;
    NSDictionary* myAttributes3 =[attributedString3 attributesAtIndex:0 effectiveRange:nil];
    XCTAssertTrue([myAttributes3[@"NSColor"] isEqual:[UIColor redColor]], @"");

    NSAttributedString *attributedString4 = textView.attributedText;
    NSDictionary* myAttributes4 =[attributedString4 attributesAtIndex:10 effectiveRange:nil];
    XCTAssertTrue([myAttributes4 objectForKey:@"NSColor"]==nil, @"");
}

// testing / abc

//- (void)testDelComments1 {
//    MyRichTextEditorHelper *helper = [[MyRichTextEditorHelper alloc] init];
//    MyRichTextEditor *textView = [[MyRichTextEditor alloc] init];
//    textView.text = @"";
//    
//    [helper textView:textView shouldChangeTextInRange:NSMakeRange(0, 1) replacementText:@"/"];
//    [helper textView:textView shouldChangeTextInRange:NSMakeRange(1, 1) replacementText:@"/"];
//    [helper textView:textView shouldChangeTextInRange:NSMakeRange(2, 1) replacementText:@" "];
//    [helper textView:textView shouldChangeTextInRange:NSMakeRange(3, 1) replacementText:@"a"];
//    [helper textView:textView shouldChangeTextInRange:NSMakeRange(4, 1) replacementText:@"b"];
//    [helper textView:textView shouldChangeTextInRange:NSMakeRange(5, 1) replacementText:@"c"];
//    
//    NSRange range = NSMakeRange(1, 1);
//    textView.selectedRange = range;
//    [helper textView:textView shouldChangeTextInRange:range replacementText:@""];
//    
//    NSAttributedString *attributedString1 = textView.attributedText;
//    NSDictionary* myAttributes1 =[attributedString1 attributesAtIndex:0 effectiveRange:nil];
//    XCTAssertTrue([myAttributes1 objectForKey:@"NSColor"]==nil, @"");
//}



@end
