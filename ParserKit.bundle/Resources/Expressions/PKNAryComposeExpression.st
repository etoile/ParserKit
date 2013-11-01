"Abstract compose expression with n subexpressions" 
PKParseExpression subclass: PKNAryComposeExpression [
	| expressions |

	init [
		super init.
		expressions := NSMutableArray new.
		^self
	]

	addExpression: exp
	[
		expressions addObject: exp.
	]

	addExpressions: exprs
	[
		expressions addObjectsFromArray: exprs.
	]

	expressions [ ^expressions]

	isMemoizableForNonTerminal: name inGrammar: grammar [
		| result |
		result := true.
		expressions do: [ :exp|
			result ifTrue: [
				result := exp isMemoizableForNonTerminal: name inGrammar: grammar.
			]
		].
		^result. 
	]

	isMemoizable [ ^self isMemoizableForNonTerminal: nil inGrammar: nil ]

	setDelegate: aDelegate [
		super setDelegate: aDelegate.
		expressions do: [ :each | each setDelegate: aDelegate ].
	]
]

