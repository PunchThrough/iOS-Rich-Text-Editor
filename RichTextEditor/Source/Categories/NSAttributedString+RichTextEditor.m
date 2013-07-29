//
//  NSAttributedString+RichTextEditor.m
//  RichTextEdtor
//
//  Created by Aryan Gh on 7/21/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//
// https://github.com/aryaxt/iOS-Rich-Text-Editor
//
// Permission to use, copy, modify and distribute this software and its documentation
// is hereby granted, provided that both the copyright notice and this permission
// notice appear in all copies of the software, derivative works or modified versions,
// and any portions thereof, and that both notices appear in supporting documentation,
// and that credit is given to Aryan Ghassemi in all documents and publicity
// pertaining to direct or indirect use of this code or its derivatives.
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSAttributedString+RichTextEditor.h"

@implementation NSAttributedString (RichTextEditor)

- (NSRange)paragraphRangeFromTextRange:(NSRange)range
{
	NSInteger start = -1;
	NSInteger end = -1;
	NSInteger length = 0;
	
	NSInteger startingRange = (range.location == self.string.length || [self.string characterAtIndex:range.location] == '\n') ?
		range.location-1 :
		range.location;
	
	for (int i=startingRange ; i>=0 ; i--)
	{
		char c = [self.string characterAtIndex:i];
		if (c == '\n')
		{
			start = i+1;
			break;
		}
	}
	
	start = (start == -1) ? 0 : start;
	
	NSInteger moveForwardIndex = (range.location > start) ? range.location : start;
	
	for (int i=moveForwardIndex; i<= self.string.length-1 ; i++)
	{
		char c = [self.string characterAtIndex:i];
		if (c == '\n')
		{
			end = i;
			break;
		}
	}
	
	end = (end == -1) ? self.string.length-1 : end;
	length = end - start;
	
	return NSMakeRange(start, length);
}

@end