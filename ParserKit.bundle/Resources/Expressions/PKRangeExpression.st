"
Interpret an set of character sort by it encoding value.
"
PKParseExpression subclass: PKRangeExpression [
	| from to |

	initFrom: fromChar to: toChar [
		super init.
		from := fromChar.
		to := toChar.
		^self
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		^list head isEmpty 
            ifTrue: [PKParseFail alloc initWithInput: list description: 'Expected character [', from, '-', to, ']']
			ifFalse: [
		         (((list head characterAtIndex: 0) >= ( from  characterAtIndex: 0)) and: ((list head characterAtIndex: 0) <= (to characterAtIndex: 0)))
	                   ifTrue: [PKParseMatch alloc initWithInput: list length: list head length]
		               ifFalse: [PKParseFail alloc initWithInput: list description: 'Expected character [', from, '-', to, ']']]
		
	]

	description [
		^'[', from, '-', to, ']'
	]
	
	
]

