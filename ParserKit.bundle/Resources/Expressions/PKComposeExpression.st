"Abstract class for composing expression"
PKParseExpression subclass: PKComposeExpression [
	| exp |

	initWithExp: expression [ 
		super init.
		exp := expression. 
		^self 
	]

	description [
		^exp description	
	]

	parseInput: list withCurrentParser: parser delegate: delegate [
	    ^exp parseInput: list  withCurrentParser: parser delegate: delegate
	]

	expression [^exp]

	" Non-Memoizability is inherited. "
	isMemoizable [ ^exp isMemoizable ]
	isMemoizableForNonTerminal: name inGrammar: grammar [ ^exp isMemoizableForNonTerminal: name inGrammar: grammar ] 

	setDelegate: aDelegate [
		super setDelegate: aDelegate.
		exp setDelegate: aDelegate.
	]
]


