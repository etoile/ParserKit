"
Interpret an end of input stream expression
"

PKParseExpression subclass: PKEmptyExpression [
	| +instance |

	+initialize [
        instance := self new.
	]

	+uniqueInstance [
        ^instance
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list atEnd
            ifTrue: [PKParseMatch emptyMatch: list ]
			ifFalse: [PKParseFail alloc initWithInput: list description:  'Expected an empty string'] 
	]

	description [
		^ '$'
	]
]

