" 
  Restricted expressions are a quick hack to work around the fact that our 
  delegate based action syntax does not allow us to replace the parse match with
  a bound subexpression without jumping to a large number of hoops. (i.e. write
  a delegate method that does nothing
"

PKComposeExpression subclass: PKRestrictionExpression [
	| restriction |
	initWithExp: aExp restriction: aRestriction [
		super initWithExp: aExp.
		restriction := aRestriction
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		
		match := exp parseInput: list withCurrentParser: parser.
		match isSuccess  ifTrue: [
			match attachAction: (restriction restrictInEnvironment: list environment)
		].	
		^match
	]
	description [ ^exp description, ' -> ', restriction description ]
]

