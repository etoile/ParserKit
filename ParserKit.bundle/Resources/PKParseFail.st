
NSObject subclass: PKParseFail [
	| input failedPosition describ delegate cause |

	initWithInput: list description: string cause: theCause [
		super init.
		describ := string.
		input := list.
		cause := theCause.
		failedPosition := input position.
		^self
	]
	initWithInput: list description: string [
		^self initWithInput: list description: string cause: nil
	]

	cause [
		^(cause == nil) ifTrue: [ self ]
		                ifFalse: [ cause cause ]
	]  

	setDelegate: anObject  [ delegate := anObject]
	stopPosition [^failedPosition]
	isFailure [ ^true ]
	isSuccess [ ^false ]
	matchAction [^nil]
	matchText [^'PKParseFail']
	bind: name ["No sensible thing can be done here"]
	description [
		| desc |
		 desc := 'PKMatchFailure  ( At: ''',   failedPosition description, ''', ', input stream, ') ', describ, '\n'.
		(nil == cause) ifFalse: [desc := desc, 'Cause: ', self cause description, '\n'].
		^desc. 
	]
]

