"
  Delayed invocations are used to record the semantic actions defined by parse
  expressions and to execute them after the parse tree has successfully
  constructed.
"
NSObject subclass: PKDelayInvocation [
	| selector args original |
	
	+invocationWithSelector: aSelector arguments: someArgs originalMatch: match [
		^self alloc initWithSelector: aSelector arguments: someArgs originalMatch: match
	]

	initWithSelector: aSelector arguments: someArgs originalMatch: match [
		super init.
		selector := aSelector.
		args := someArgs.
		original := match.
		^self
	]

	isExplicitAction [^true]
	canReduce [^true]
	reduceOn: target [
		| oldSelString rangedSelector reduceArgs anInvoc |
		oldSelString := selector description.
		(oldSelString hasPrefix: '#') ifTrue: [ oldSelString := oldSelString substringFromIndex: 1 ].
		rangedSelector := (oldSelString hasSuffix: ':') ifTrue: [ (oldSelString stringByAppendingString: 'range:') selValue ]
		                                               ifFalse: [ (oldSelString stringByAppendingString: 'Range:') selValue ].
		" If the delegate is also interested in the range, invoke that method (and add the
		  implicitly bound range argument, of course)"
		(target respondsToSelector: rangedSelector) ifTrue: [
			selector := rangedSelector.
			args := args arrayByAddingObject: original range.
		].

		^(target respondsToSelector: selector) ifTrue: [
			reduceArgs := args map: [:each | each canReduce ifTrue: [
				| res | res := each reduceOn: target.
				(res == nil) ifTrue: [
					NSNull new
				] ifFalse: [
					res].
			] ifFalse: [each]].
			anInvoc := NSInvocation invocationWithTarget: target selector: selector arguments: reduceArgs.
			anInvoc invoke.
			anInvoc returnValueAsObject
		] ifFalse: [
			" if the selector cannot be invoked, we just return the original match. "
			ETTranscript show: 'Missing selector '; show: selector; cr.
			original matchText
		]
	]

	description [
		| argList |
		argList := args leftFoldWithInitialValue: ''
		intoBlock: [ :acc :arg |
			'' = acc ifTrue: [arg description]
			        ifFalse: [ acc, ', ', arg description]
		].
		^ selector description, ' with args: (', argList, ')'
	]
]
