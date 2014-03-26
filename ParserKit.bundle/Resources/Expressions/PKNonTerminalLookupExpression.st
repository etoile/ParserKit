
PKParseExpression subclass: PKNonTerminalLookupExpression [
	| grammar name |
	initWithGrammar: aGrammar name: aName [
		grammar := aGrammar.
		name := aName
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
		"ETTranscript debug: 'Apply ', name, ' at: '; debug: list position; debugCr."
		"This allow expression to apply super rules or self rules"
		^(grammar == nil ) ifTrue: [parser matchStream: list rule: name delegate: delegate] 
						   ifFalse: [grammar matchStream: list rule: name delegate: delegate]
	]

	isMemoizable [ 
		(grammar == nil) ifTrue: [^true].
		^(grammar rules lookup: name ifFailed: [^false]) isMemoizableForNonTerminal: name inGrammar: grammar ]

	isMemoizableForNonTerminal: aName inGrammar: aGrammar [ 
		(grammar == nil) ifTrue: [^true].
		^((grammar == aGrammar) and: (name = aName)) ifTrue: [true] 
													 ifFalse: [self isMemoizable]
	]
	description [ ^name ]
]

