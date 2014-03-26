"
  Restricted matches can be used just as delayed invocations, but they only
  contain their literal value.
"
NSObject subclass: PKRestrictedMatch [
	| restricted |
	initWithResult: result [
		super init.
		restricted := result.
		^self
	]

	reduceOn: delegate [
		^(restricted canReduce) ifTrue: [restricted reduceOn: delegate]
		                       ifFalse: [restricted].	
	]
	
	canReduce [ ^true ]

	isExplicitAction [ ^true ]

	description [ ^restricted description ]
]

