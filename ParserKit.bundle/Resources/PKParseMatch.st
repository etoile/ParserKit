
NSObject subclass: PKParseMatch [
	| input range action delegate |

	+emptyMatch: input [
        ^self new initWithInput: input length: 0; 
			yourself
	]

	initWithInput: list length: length [
		super init.
		action := nil.
		input := list.
		range := (NSValue rangeWithLocation: input position length: length).
		input pushPosition: range length + range location.
		^self
	]
	
	copyInitWith: list range: aRange [
		input := list.
		range := aRange.
		action := nil
	]

	sequenceWith: match [
		| newMatch |
		input mergePosition.
		input lastPosition = range location ifFalse: [
			"Can be remove or rephrase later."
			NSException raise: 'ParseKit' format: 'Last position is not same as the location range, something is wrong here range loc: ', range location description, ' last input: ', input lastPosition description, ' match: ', match description, ' merge with: ', self description ].
		(range location + range length) = match range location
			ifFalse: [ NSException raise: 'ParserKit' format: 'Can not add the range, it is not contiguous'].
		newMatch := self class alloc copyInitWith: input range: (NSValue rangeWithLocation: range location length: (range length + match  range length)).
		(action == nil and: match matchAction == nil) ifFalse: [
			newMatch attachAction: PKDelayActionArray new.
			" It is important to attach the verbatim matches from matches that do not require actions,
			  but only if it's no the empty match (esp. since every sequence matching starts with the
			  empty match."
			(action == nil) ifTrue: [self isEmpty ifFalse: [ newMatch sequenceAction: self matchText ]]
			               ifFalse: [newMatch sequenceAction: action].
			(match matchAction == nil) ifTrue: [newMatch isEmpty ifFalse: [newMatch sequenceAction: match matchText]]
			                          ifFalse: [newMatch sequenceAction: match matchAction].
		].
		^newMatch
	]

	bind: name [
		action == nil
            ifTrue: [input bind: name range: range]
			ifFalse: [input bind: name action: action match: self. action := nil]
	]
	
	setDelegate: anObject  [ delegate := anObject ]

	sequenceAction: anAction [ 
		action == nil 
			ifTrue:  [action := anAction]
			ifFalse: [ action := action addAction: anAction ]
	]

	attachAction: anAction [
		" There might still be an attached action if the result was not bound.
		  In this case, it is safe to assume that the result of the evaluation 
		  is irrelevant to reducing the expression at hand. 
		  FIXME: People might potentially be interested in the side-effects..."
		action := anAction.	
	]

	matchAction [^action]
	match  [ ^(input fromRange: range)]
	isEmpty [ ^range length = 0]
	isSuccess [ ^true ]
	isFailure [ ^false ]
	range [^range]
	reduce [^action == nil ifTrue: [nil] ifFalse: [action reduceOn: delegate]]
    stopPosition [^range length + range location]
	matchText [^ input fromRange: range]
	description [
		^'PKMatchSuccess  ( Recognized: ''', self matchText , ''' location: ', range description,' action: ', action description, ')\n' 
	]
]


