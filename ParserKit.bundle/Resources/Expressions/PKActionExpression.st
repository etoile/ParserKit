"
Action expression attache a hook to the matching expression.
"
PKComposeExpression subclass: PKActionExpression [
	| action |
	
	initWithExp: aExp action: anAction [
		super initWithExp: aExp.
		action := anAction
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		
		match := exp parseInput: list withCurrentParser: parser delegate: delegate.
		match isSuccess  ifTrue: [
			match attachAction: (action invocationInEnvironment: list environment originalMatch: match)
		].
		
		^match
	]
	description [ ^exp description, ' -> ', action description ]
]

