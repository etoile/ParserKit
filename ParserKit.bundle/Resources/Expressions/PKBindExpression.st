
PKComposeExpression subclass: PKBindExpression [
	| name |

	initWithExp: exp name: aName [
		super initWithExp: exp.
		name := aName
	]

	parseInput: list withCurrentParser: parser delegate: delegate[
		| match |
		match := exp parseInput: list withCurrentParser: parser delegate: delegate. 
		match bind: name.
		^match
	]

	description [ ^'(', exp description, '):', name ]
	
]

