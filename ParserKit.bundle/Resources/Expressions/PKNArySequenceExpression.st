
PKNAryComposeExpression subclass: PKNArySequenceExpression [

	parseInput: list withCurrentParser: parser delegate: delegate[
		| match |
		match := PKParseMatch emptyMatch: list.
		expressions do: [ :exp|
			match isSuccess ifTrue: [
				| currentMatch |
				currentMatch := exp parseInput: list withCurrentParser: parser delegate: delegate.
				currentMatch isSuccess ifTrue: [ 
					"ETTranscript debug: 'Merge sequence ''', match matchText, ''' with: ''', currentMatch matchText, ''''; debugCr."
					match := match sequenceWith: currentMatch.
				] ifFalse: [
					list popPosition.
					match := PKParseFail new initWithInput: list description: 'Unexpected token, expected: ', exp description
					                                 cause: currentMatch.
				].
			]
		].
		^ match
	]
	
	seq: exp
	[
		((exp isKindOfClass: PKNArySequenceExpression class) or: (exp isKindOfClass: PKSequenceExpression class)) ifTrue: [
			self addExpressions: exp expressions.
		] ifFalse: [ self addExpression: exp ].
		^self
	]

	description [
		^expressions leftFoldWithInitialValue: ''
		                            intoBlock: [ :acc :exp|
			('' = acc) ifTrue: [exp description]
			          ifFalse: [acc, ' ', exp description]
		]
	]
]

