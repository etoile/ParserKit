/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKAnythingExpressionTest : NSObject <UKTest>
@end

@implementation PKAnythingExpressionTest
- (void)testSpace
{
	PKInputStream *stream  = [[PKInputStream alloc] initWithStream: @""];
	PKAnythingExpression *exp = [PKAnythingExpression new];
	id match = [exp parseInput: stream];
	UKObjectKindOf(match, PKParseMatch);
	UKTrue([match isEmpty]);

	stream = [[PKInputStream alloc] initWithStream: @"t"];
	match = [exp parseInput: stream];
	UKObjectKindOf(match, PKParseMatch);
	UKTrue([match isEmpty]);
	UKIntsEqual([[stream position] intValue], 0);
}

@end
