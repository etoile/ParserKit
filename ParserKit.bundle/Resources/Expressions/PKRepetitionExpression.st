
PKComposeExpression subclass: PKRepetitionExpression [
	| canBeEmpty |

	initWithExpression: anExp canBeEmpty: aBool [
		super init.
		exp := anExp.
		canBeEmpty := aBool.
		^self
	]
	
	parseInput: list withCurrentParser: parser delegate: delegate[
		| match currentMatch |
		match := PKParseMatch emptyMatch: list.
		[
			currentMatch := exp parseInput: list withCurrentParser: parser delegate: delegate.
			currentMatch isSuccess
		] whileTrue: [ 
			"ETTranscript debug: 'Merge repetition ', match matchText, ' with: ', currentMatch matchText; debugCr."
			match := match sequenceWith: currentMatch.
		].
		^(match isEmpty and: canBeEmpty not) 
            ifTrue: [list popPosition. PKParseFail new initWithInput: list description: 'Unexpected token, expected: ', exp description
	                                                           cause: currentMatch ]
			ifFalse: [match]
	]

	description [
		^exp description , (canBeEmpty ifTrue: ['*'] ifFalse: ['+'])
	]
]

