

//
//  ViewController.m
//  RichTextEdtor
//
//  Created by Aryan Gh on 7/21/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) MyRichTextEditor *myRichTextEditor;
@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged) name:UIContentSizeCategoryDidChangeNotification object:nil];

    self.myRichTextEditor = [[MyRichTextEditor alloc] initWithLineNumbers:NO];
    [self.view addSubview:self.myRichTextEditor];
    self.myRichTextEditor.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = @{@"myRichTextEditor":self.myRichTextEditor};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[myRichTextEditor]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[myRichTextEditor]|" options:0 metrics:nil views:views]];
    
    [self preferredContentSizeChanged];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"examplesketch" ofType:@"ino"];
    NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
    [self.myRichTextEditor loadWithText:myText];    
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
