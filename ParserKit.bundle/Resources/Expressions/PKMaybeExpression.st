PKComposeExpression subclass: PKMaybeExpression [
	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := exp parseInput: list withCurrentParser: parser delegate: delegate.
		^match isSuccess ifTrue: [match]
						 ifFalse: [ PKParseMatch alloc initWithInput: list length: 0 ]
	]
	
	description [^'(', exp description, ')?']
]


