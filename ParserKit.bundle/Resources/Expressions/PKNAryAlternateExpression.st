
PKNAryComposeExpression subclass: PKNAryAlternateExpression [
	parseInput: list withCurrentParser: parser delegate: delegate [
		| match |
		match := PKParseFail alloc initWithInput: list description: 'Expected ', self description.
		expressions do: [ :exp |
			match isSuccess ifFalse: [
				| currentMatch |
				currentMatch := exp parseInput: list withCurrentParser: parser delegate: delegate.
				currentMatch isSuccess ifTrue: [ match := currentMatch ]
			]
		].
		^match
	]
	
	description [
		^expressions leftFoldWithInitialValue: ''
		                            intoBlock: [ :acc :exp|
			('' = acc) ifTrue: [exp description]
			          ifFalse: [acc, ' / ', exp description]
		]
	]

	or: exp [
		((exp isKindOfClass: PKNAryAlternateExpression class) or: (exp isKindOfClass: PKAlternateExpression class)) ifTrue: [
			self addExpressions: exp expressions.
		] ifFalse: [ self addExpression: exp ]
	]
]



