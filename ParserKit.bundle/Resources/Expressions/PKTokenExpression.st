PKParseExpression subclass: PKTokenExpression [
	| match |

	initWithPattern: matchPattern [
		super init.
		match := matchPattern.
		^self
	]
	
	parseInput: list withCurrentParser: parser delegate: delegate [
		| return |
		((list head: match matchSize) isEqual: match) ifTrue: [ 
			return := PKParseMatch alloc initWithInput: list
								length: match matchSize.
		] ifFalse: [
			return := PKParseFail alloc initWithInput: list description: 'Unexpected token, expected: ', match
		].
		^return
	]

	description [
		^'''', match description, ''''
	]
]


