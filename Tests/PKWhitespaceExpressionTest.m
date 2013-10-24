/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKWhitespaceExpressionTest : NSObject <UKTest>
@end

@implementation PKWhitespaceExpressionTest
- (void)testSpace
{
	PKInputStream *stream  = [[PKInputStream alloc] initWithStream: @" \n\t\r"];
	PKWhitespaceExpression *exp = [PKWhitespaceExpression new];
	id result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @" ");

	result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @"\n");

	result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @"\t");

	result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @"\r");

}

- (void)testParseFail
{
	PKInputStream *stream = [[PKInputStream alloc] initWithStream: @"test"];
	PKWhitespaceExpression *exp = [PKWhitespaceExpression new];
	id result = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseFail);
	UKFalse([[result isSuccess] boolValue]);
}
@end
