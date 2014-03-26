
PKComposeExpression subclass: PKNegateExpression [

	initWithExp: expression [
		super initWithExp: (PKLookAheadExpression alloc initWithExp: expression).
		^self
	]

	description [
		^'!(',exp expression description,')'
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := exp parseInput: list withCurrentParser: parser delegate: delegate.
		^match isSuccess ifTrue: [PKParseFail alloc initWithInput: list description: 'Should not match ', exp expression description] 
						 ifFalse: [PKParseMatch alloc initWithInput: list length: 0]
	]
]

