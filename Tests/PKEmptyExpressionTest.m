/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKEmptyExpressionTest : NSObject <UKTest>
@end

@implementation PKEmptyExpressionTest
- (void)testSpace
{
	PKInputStream *stream  = [[PKInputStream alloc] initWithStream: @""];
	PKEmptyExpression *exp = [PKEmptyExpression new];
	id match = [exp parseInput: stream];
	UKObjectKindOf(match, PKParseMatch);
	UKTrue([match isEmpty]);

	stream = [[PKInputStream alloc] initWithStream: @"t"];
	match = [exp parseInput: stream];
	UKObjectKindOf(match, PKParseFail);
}

@end
