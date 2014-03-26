"
  Parse restrictions are a reduced case of actions that can be used to replace a
  match with a bound sub-expression.
"	
NSObject subclass: PKParseRestriction [
	| binding |

	initWithBinding: name [
		super init.
		binding := name.
		^self
	]

	restrictInEnvironment: env [
		| value |
		value := env objectForKey: binding.
		value == nil ifTrue: [NSException raise: 'ParserKit' format: 'Unknown binding: ', binding].
		^PKRestrictedMatch alloc initWithResult: value
	]

	description [ ^binding ]
]

