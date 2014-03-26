PKComposeExpression subclass: PKLookAheadExpression [

	
	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := exp parseInput: list withCurrentParser: parser delegate: delegate.
		match isFailure ifFalse: [list popPosition].
		^match
	]
	
	description [ ^'&(', exp description, ')' ]
]


