NSObject subclass: PKMatchRangeNotice [
	| match rule range |

	initWithMatch: aMatch rule: aRule at: aRange [
		super init.
		match := aMatch.
		rule := aRule.
		range := aRange.
	]

	canReduce [ ^true ]

	isExplicitAction [
		^(match respondsToSelector: #isExplicitAction ) ifTrue: [
			(self == match) ifTrue: [ false ]
			               ifFalse: [ match isExplicitAction ].
		] ifFalse: [
			| action |
			action := match matchAction.
			(nil == action) ifTrue: [ false ]
			ifFalse: [
				(action isKindOfClass: PKMatchRangeNotice class) ifTrue: [ false ]
				ifFalse: [ action isExplicitAction ]
			]
		]
	]

	originalMatch [ ^match ]

	range [ ^range ]

	setOriginalMatch: aMatch [
		match := aMatch
	]

	reduceOn: target [
		| selector |
		selector := ('matched', rule, 'At:') selValue.
		ETTranscript debug: 'Reduce called: '; debug: selector; debugCr.
		(target respondsToSelector: selector) ifTrue: [
			target performSelector: selector withObject: range.
		] ifFalse: [
			target ifResponds matched: rule at: range.
		].
		^match canReduce ifTrue: [ 
			match reduceOn: target
		] ifFalse: [
			match match
		]
	]

	description [ ^'Notice about match for ''', rule, ''' at ', range description ] 
]


