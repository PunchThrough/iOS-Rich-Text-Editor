

//
//  ViewController.m
//  RichTextEdtor
//
//  Created by Aryan Gh on 7/21/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet MyRichTextEditor *myRichTextEditor;
@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged) name:UIContentSizeCategoryDidChangeNotification object:nil];

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"examplesketch" ofType:@"ino"];
    if (filePath) {
        NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
        if (myText) {
            [self.myRichTextEditor loadWithText:myText];
            [self preferredContentSizeChanged];
        }
    }
    
//    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
//    v.backgroundColor = [UIColor redColor];
//    [self.myRichTextEditor addSubview:v];
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
