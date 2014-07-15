//
//  MyRichTextEditorToolbar.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditorToolbar.h"
#import "RichTextEditorToggleButton.h"

@interface MyRichTextEditorToolbar()
@property (nonatomic, strong) RichTextEditorToggleButton *btnLeftBracket;
@property (nonatomic, strong) RichTextEditorToggleButton *btnRightBracket;
@property (nonatomic, strong) RichTextEditorToggleButton *btnLeftParen;
@property (nonatomic, strong) RichTextEditorToggleButton *btnRightParen;
@property (nonatomic, strong) RichTextEditorToggleButton *btnLeftBrace;
@property (nonatomic, strong) RichTextEditorToggleButton *btnRightBrace;
@end

@implementation MyRichTextEditorToolbar

- (void)initializeButtons
{
	self.btnLeftBracket = [self buttonWithText:@"[" width:36 andSelector:@selector(leftBracketSelected)];
	self.btnRightBracket = [self buttonWithText:@"]" width:36 andSelector:@selector(rightBracketSelected)];
	self.btnLeftParen = [self buttonWithText:@"(" width:36 andSelector:@selector(leftParenSelected)];
	self.btnRightParen = [self buttonWithText:@")" width:36 andSelector:@selector(rightParenSelected)];
	self.btnLeftBrace = [self buttonWithText:@"{" width:36 andSelector:@selector(leftBraceSelected)];
	self.btnRightBrace = [self buttonWithText:@"}" width:36 andSelector:@selector(rightBraceSelected)];
}

- (RichTextEditorToggleButton *)buttonWithText:(NSString *)text width:(NSInteger)width andSelector:(SEL)selector
{
	RichTextEditorToggleButton *button = [[RichTextEditorToggleButton alloc] init];
	[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
	[button setFrame:CGRectMake(0, 0, width, 0)];
	[button.titleLabel setFont:[UIFont boldSystemFontOfSize:10]];
	[button.titleLabel setTextColor:[UIColor blackColor]];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitle:text forState:UIControlStateNormal];
	
	return button;
}

- (void)populateToolbar
{
    [super populateToolbar];
    
	CGRect visibleRect;
	visibleRect.origin = self.contentOffset;
	visibleRect.size = self.bounds.size;
	
    RichTextEditorFeature features = [self.dataSource featuresEnabledForRichTextEditorToolbar];
    UIView *lastAddedView = self.subviews.lastObject;

    self.hidden = (features == RichTextEditorFeatureNone);

	if (self.hidden)
		return;

	if (features & MyRichTextEditorLeftBracket || features & MyRichTextEditorAll)
	{
		UIView *separatorView = [self separatorView];
		[self addView:self.btnLeftBracket afterView:lastAddedView withSpacing:YES];
		[self addView:separatorView afterView:self.btnLeftBracket withSpacing:YES];
		lastAddedView = self.btnLeftBracket;
	}

    if (features & MyRichTextEditorRightBracket || features & MyRichTextEditorAll)
	{
		UIView *separatorView = [self separatorView];
		[self addView:self.btnRightBracket afterView:lastAddedView withSpacing:YES];
		[self addView:separatorView afterView:self.btnRightBracket withSpacing:YES];
		lastAddedView = self.btnRightBracket;
	}

    if (features & MyRichTextEditorLeftBrace || features & MyRichTextEditorAll)
	{
		UIView *separatorView = [self separatorView];
		[self addView:self.btnLeftBrace afterView:lastAddedView withSpacing:YES];
		[self addView:separatorView afterView:self.btnLeftBrace withSpacing:YES];
		lastAddedView = self.btnLeftBrace;
	}
    
    if (features & MyRichTextEditorRightBrace || features & MyRichTextEditorAll)
	{
		UIView *separatorView = [self separatorView];
		[self addView:self.btnRightBrace afterView:lastAddedView withSpacing:YES];
		[self addView:separatorView afterView:self.btnRightBrace withSpacing:YES];
		lastAddedView = self.btnRightBrace;
	}

    if (features & MyRichTextEditorLeftParen || features & MyRichTextEditorAll)
	{
		UIView *separatorView = [self separatorView];
		[self addView:self.btnLeftParen afterView:lastAddedView withSpacing:YES];
		[self addView:separatorView afterView:self.btnLeftParen withSpacing:YES];
		lastAddedView = self.btnLeftParen;
	}
    
    if (features & MyRichTextEditorRightParen || features & MyRichTextEditorAll)
	{
		UIView *separatorView = [self separatorView];
		[self addView:self.btnRightParen afterView:lastAddedView withSpacing:YES];
		[self addView:separatorView afterView:self.btnRightParen withSpacing:YES];
		lastAddedView = self.btnRightParen;
	}
    
	[self scrollRectToVisible:visibleRect animated:NO];
}

- (void)leftBracketSelected {
    [self.dataSource insertText:@"["];
}

- (void)rightBracketSelected {
    [self.dataSource insertText:@"]"];
}

- (void)leftBraceSelected {
    [self.dataSource insertText:@"{"];
}

- (void)rightBraceSelected {
    [self.dataSource insertText:@"}"];
}

- (void)leftParenSelected {
    [self.dataSource insertText:@"("];
}

- (void)rightParenSelected {
    [self.dataSource insertText:@")"];
}


@end
