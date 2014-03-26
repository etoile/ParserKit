
PKComposeExpression subclass: PKParameterizedExpression [
	| predicate |
	initWithExp: aExp predicate: pred [
		super initWithExp: aExp.
		predicate := pred.
	]
	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := exp parseInput: list  withCurrentParser: parser delegate: delegate.
		^match isSuccess ifTrue: [
			(predicate succeedsInEnvironment: (list environment) withDelegate: delegate) ifTrue: [ match ]
			ifFalse: [
				list popPosition.
				PKParseFail alloc initWithInput: list
				                    description: ('Expected ', exp description, ' to satisfy parameter ', predicate description)].
		] ifFalse: [ match ].
	]
	
	description [
		^exp description, ' ', predicate description
	]
	
	isMemoizable [ ^false ]
	isMemoizableForNonTerminal: name inGrammar: grammar [ ^false ] 
]

