/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKNumericExpressionTest : NSObject <UKTest>
@end

@implementation PKNumericExpressionTest
- (void)testSpace
{
	PKInputStream *stream  = [[PKInputStream alloc] initWithStream: @"1s"];
	PKNumericExpression *exp = [PKNumericExpression new];
	id result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @"1");

	result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseFail);
	UKFalse([[result isSuccess] boolValue]);


}
@end
