"
  Parse predicates can be evaluated right away to decide whether a given
  expression should match.
"
PKParseAction subclass: PKParsePredicate [
	| targetName |
	initWithTargetName: trgt selector: sel argumentNames: args [
		super initWithSelector: sel argumentNames: args.
		targetName := trgt.
		^self
	]

	succeedsInEnvironment: env withDelegate: delegate [
		| target arguments invocation |
		arguments := argumentNames mappedCollectionWithBlock: [ :argName |
			|value |
			value := env objectForKey: argName.
			"FIXME: This is a quick hack. If the value cannot be bound, we assume
			 that it should be interpreted as a literal value."
			value == nil ifTrue: [value := argName].

			" We might need to reduce the value first, which might trigger
			  unwanted side-effects if we need to backtrack latter.
			  TODO: In the ParserKit manual, clearly inform the user about
			  the fact that it is unsafe use bound matches with side-effecting
			  actions in predicates. The only thing we can avoid is triggering
			  match range notices to the delegate."
			value canReduce ifTrue: [
				(value isKindOfClass: PKMatchRangeNotice class) ifTrue: [
					| innerValue |
					innerValue := value originalMatch.
					innerValue canReduce ifTrue: [
						innerValue := innerValue reduceOn: delegate.
					] ifFalse: [
						innerValue := innerValue match.
					].
					value setOriginalMatch: innerValue.
					value := innerValue.
				] ifFalse: [
				  value := value reduceOn: delegate.
				  " We also need to update the environment with the reduced value. "
				  env replaceObject: value forKey: argName.
				].
			].	
			value.
		].
		target := env objectForKey: targetName.
		target == nil ifTrue: [target := targetName].
		invocation := NSInvocation invocationWithTarget: target selector: selector arguments: arguments.
		ETTranscript show: 'Invoking selector: '; show: selector;cr.
		invocation invoke.
		^invocation returnValueAsBool
	]
	
	description [
		^'?(', targetName, ' ', self messageString, ')'.
	]
]


