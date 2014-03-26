" 
  Generates a delayed invocation with the arguments bound to the corresponding
  expressions from the current parsing environment. We might want to define a
  subclass that doesn't use invocations but instead uses the JIT to compile
  blocks that can be executed in the environment.  
"
NSObject subclass: PKParseAction [
	| selector argumentNames |
	
	initWithSelector: sel argumentNames: args [
		selector := sel.
		argumentNames := args.
	]

	invocationInEnvironment: env originalMatch: match [
		| argsBuild |
		argsBuild := NSMutableArray new.
		argumentNames do: [:each |
			| value |
			ETTranscript debug: 'Parsing with de following env.'; debug: env; debugCr.
			value := env objectForKey: each.
			value == nil ifTrue: [NSException raise: 'ParserKit' format: 'Unknown binding: ', each].
			argsBuild addObject: value.
		].
		^PKDelayInvocation invocationWithSelector: selector arguments: argsBuild originalMatch: match
	]
	
	messageString [
		| messageString |
		(selector description hasSuffix: ':') ifTrue: [
			| selectorParts |
			selectorParts := selector description componentsSeparatedByString: ':'.
			selectorParts := selectorParts zippedCollectionWithCollection: argumentNames andBlock: [ 
				:first :second |
				first, ': ', second
			].
			messageString := selectorParts componentsJoinedByString: ' '.
		] ifFalse: [
			messageString := selector description.
		].
		^(messageString hasPrefix: '#') ifTrue: [
			messageString substringWithRange: (NSValue rangeWithLocation: 1 length: (messageString length - 1))
		] ifFalse: [ messageString ].
	]

	description [ ^ '[', self messageString, ']' ]
]


