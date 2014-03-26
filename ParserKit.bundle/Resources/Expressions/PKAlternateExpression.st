
PKParseExpression subclass: PKAlternateExpression [
     | first second |

	initWithExp: exp1 or: exp2 [
		first := exp1.
		second := exp2
	]

	parseInput: list withCurrentParser: parser delegate: delegate[
		 ^first parseInput: list  withCurrentParser: parser delegate: delegate ifFailed: [
			 | match |
			 match := second parseInput: list withCurrentParser: parser delegate: delegate.
			 match isFailure 
                 ifTrue:[ PKParseFail alloc initWithInput: list description: 'Expected ', self description]
				 ifFalse: [match]
		 ]		
	 ]

	expressions [ ^{first. second} ]

	or: exp [
		| multiOr |
		multiOr := PKNAryAlternateExpression new.
		multiOr addExpression: first; addExpression: second.
		
		^multiOr or: exp.
	]

	description [
		^first description, ' / ', second description
	]
	
	isMemoizable [ ^first isMemoizable ifTrue: [second isMemoizable]
			                  ifFalse: [false] ]

	isMemoziableForNonTerminal: name inGrammar: grammar [ ^ (first isMemoizableForNonTerminal: name inGrammar: grammar) and:
		(second isMemoizableForNonTerminal: name inGrammar: grammar) ]

]

