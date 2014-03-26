PKParseExpression subclass: PKSequenceExpression [
 	| e1 e2 |

	initWithFirst: exp1 second: exp2 [
		e1 := exp1.
		e2 := exp2.
		^self
	] 

	parseInput: list withCurrentParser: parser delegate: delegate [
		| match1 |
		match1 := e1 parseInput: list withCurrentParser: parser delegate: delegate.
		^match1 isSuccess ifTrue: [
			| match2 |
			match2 := (e2 parseInput: list withCurrentParser: parser delegate: delegate).
			match2 isSuccess 
                ifTrue: [ 
					"ETTranscript debug: 'Merge sequence: ''', match1 matchText, ''' with: ''', match2 matchText, ''''; debugCr."
					match1 sequenceWith: match2 ]
				ifFalse: [ list popPosition. match2 ]
		] ifFalse: [ match1 ]
	]

	expressions [ ^{e1. e2} ]

	seq: exp [
		| multiSeq |
		multiSeq := PKNArySequenceExpression new.
		multiSeq addExpressions: self expressions.
		^multiSeq seq: exp
	]

	description [
		^e1 description, ' ', e2 description
	]

	isMemoizable [ ^e1 isMemoizable ifTrue: [e2 isMemoizable]
			               ifFalse: [false] ]

	isMemoziableForNonTerminal: name inGrammar: grammar [ ^ (e1 isMemoizableForNonTerminal: name inGrammar: grammar) and:
		(e2 isMemoizableForNonTerminal: name inGrammar: grammar) ]
]

