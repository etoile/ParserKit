PKComposeExpression subclass: PKNonTerminalExpression [
	| name  |
	initWithName: string exp: expression [
		super init.
		exp := expression.
		name := string.
		^self
	]

	parseInput: list  withCurrentParser: parser delegate: delegate  [
		| match |
		list inEnvironmentDo: [
			exp == nil ifTrue: [NSException raise: 'ParserKit' format: 'Uncomplete grammar definition for ', name].
			ETTranscript debug: 'Trying non terminal: ', name, ' input pos: '; debug: list positionStack; debugCr.
			match := list matchRule: name.
			(match == nil) ifTrue: [
				| position |
				position := list position.

				match := exp parseInput: list  withCurrentParser: parser delegate: delegate.
				match isSuccess ifTrue: [
					" Add an implicit range notice "
					(match matchAction == nil) ifTrue: [
						match attachAction: (PKMatchRangeNotice alloc
						  initWithMatch: match
						           rule: name
						             at: match range)	
					] ifFalse: [
						" If there is already an action, we need to use that for
						  the match "
						(match matchAction isKindOfClass: PKMatchRangeNotice class) ifFalse: [
							match attachAction: (PKMatchRangeNotice alloc
							     initWithMatch: match matchAction
							              rule: name
							                at: match range)
						]
					].
				].
				" Only memoize the matches from expressions for which it is safely possible. "
				"exp isMemoizable ifTrue: [list addMatch: match at: position named: name]."
			] ifFalse: [ match isSuccess ifTrue: [
				ETTranscript debug: 'Pushing back position: '; debug: match stopPosition; debugCr.
				list pushPosition: match stopPosition.
				]
							 ifFalse: [ ETTranscript debug: 'Memo Catch failure for ', name; debugCr]
			].
			ETTranscript debug: 'End of non terminal: ', name, ' input pos: '; debug: list positionStack; debug: 'last position: '; debug: list position; debug: ', match: '; debug: match matchText; debugCr.
		].
		^match
	]

	setExpression: anExp [ exp := anExp ]
	description [^name]
]


