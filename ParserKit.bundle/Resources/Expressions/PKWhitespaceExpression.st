"
Interpret a whitespace expression
"
PKParseExpression subclass: PKWhitespaceExpression [

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list head isEmpty ifTrue: [
			PKParseFail alloc initWithInput: list description: 'Expected whitespace character'
		] ifFalse: [
			(list head characterAtIndex: 0) isWhitespace ifTrue: [
				PKParseMatch alloc initWithInput: list length: list head length
			] ifFalse: [
				PKParseFail alloc initWithInput: list description: 'Expected whitespace character'
			]
		]
	]

	description [ ^'[[:space:]]']
]

