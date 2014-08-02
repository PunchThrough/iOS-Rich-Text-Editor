

//
//  ViewController.m
//  RichTextEdtor
//
//  Created by Aryan Gh on 7/21/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) UITextView *myRichTextEditor;
@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged) name:UIContentSizeCategoryDidChangeNotification object:nil];

    self.myRichTextEditor = [[UITextView alloc] init];
//    self.myRichTextEditor = [[MyRichTextEditor alloc] initWithLineNumbers:YES];
    self.myRichTextEditor.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.myRichTextEditor];
    
    NSDictionary *views = @{@"myRichTextEditor":self.myRichTextEditor};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[myRichTextEditor]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[myRichTextEditor]|" options:0 metrics:nil views:views]];
    
    [self preferredContentSizeChanged];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"examplesketch" ofType:@"ino"];
    NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
//    [self.myRichTextEditor loadWithText:myText];
    self.myRichTextEditor.text = myText;
}

- (void)preferredContentSizeChanged {
    self.myRichTextEditor.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
