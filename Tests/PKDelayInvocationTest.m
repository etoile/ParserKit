/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
#import <LanguageKitRuntime/Symbol.h>
@interface PKDelayInvocationTest : NSObject <UKTest>
{
	BOOL	simpleCalled;
	BOOL	rangeCalled;
	BOOL	keywordRangeCalled;
}
@end

@implementation PKDelayInvocationTest
- (id) init
{
	simpleCalled = NO;
	rangeCalled = NO;
	keywordRangeCalled = NO;
	return self;
}

- (void)testInvocation
{
	PKInputStream *stream = [[PKInputStream alloc] initWithStream: @"test"];
	PKParseMatch *match  = [PKParseMatch emptyMatch: stream];
	PKDelayInvocation *invok = [PKDelayInvocation 
		invocationWithSelector: [Symbol SymbolForSelector: @selector(calledSelector)] 
					 arguments: [NSArray new] 
				 originalMatch: match];

	UKTrue([[invok canReduce] boolValue]);
	UKObjectsEqual([invok reduceOn: self], [NSNull null]);
	UKTrue(simpleCalled);

	invok = [PKDelayInvocation 
		invocationWithSelector: [Symbol SymbolForSelector: @selector(calledRangeSelector)]
					 arguments: [NSArray new]
				 originalMatch: match];

	UKObjectsEqual([invok reduceOn: self], [NSNull null]);
	UKTrue(rangeCalled);

	invok = [PKDelayInvocation 
		invocationWithSelector: [Symbol SymbolForSelector: @selector(keyword:)]
					 arguments: [NSArray arrayWithObject: [NSNull null]]
				 originalMatch: match];

	UKObjectsEqual([invok reduceOn: self], [NSNull null]);
	UKTrue(keywordRangeCalled);
}

- (id)calledSelector
{
	simpleCalled = YES;
	return [NSNull null];
}

- (id)calledRangeSelectorRange: (id)range
{
	UKObjectKindOf(range, NSValue);
	UKIntsEqual([range length], 0);
	rangeCalled = YES;
	return [NSNull null];
}

- (id)keyword: (id)arg1 range: (id)range
{
	UKObjectsEqual(arg1, [NSNull null]);
	keywordRangeCalled = YES;
	UKIntsEqual([range length], 0);
	return [NSNull null];
}
@end
