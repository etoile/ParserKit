"
Interpret numerical value
"
PKParseExpression subclass: PKNumericExpression [

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list head isEmpty ifTrue: [PKParseFail alloc initWithInput: list description: 'Expected digit character']
			ifFalse: [
				(list head characterAtIndex: 0) isDigit
			        ifTrue: [PKParseMatch alloc initWithInput: list length: list head length]
			        ifFalse: [PKParseFail alloc initWithInput: list description: 'Expected digit character']]

	]

	description [
		^'[[:digit:]]'
	]
]

