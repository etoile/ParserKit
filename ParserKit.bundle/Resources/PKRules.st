

"
  PKRules encapsulates the rules set up by a single grammar.
"
NSObject subclass: PKRules [
	| parent rules name |

	initWithName: string [
		super init.
		name := string.
		parent := nil.
		rules := NSMutableDictionary new.
		^self
	]

	at: rule [
		^self lookup: rule ifFailed: [
			| ruleExp |
			ruleExp := PKNonTerminalExpression alloc initWithName: rule exp: nil.
			rules setValue: ruleExp forKey: rule.
			ruleExp
		]
	]

	addRule: name expression: exp [
		| rule |
		rule := rules objectForKey: name.
		rule == nil ifTrue: [
			rule := PKNonTerminalExpression alloc initWithName: name exp: exp.
		    rules setValue: rule forKey: name
		] ifFalse: [
			rule setExpression: exp
		].
		^rule
	]

	lookup: rule ifFailed: aBlock [
		| return |
		return := rules objectForKey: rule.
		return == nil ifTrue:[
			parent == nil
                ifTrue: [ return := aBlock value ]
				ifFalse: [	
					return := parent lookup: rule ifFailed: aBlock
				]
		].
		^return	
	]
		
	initWithParent: pkRules name: string [
		self initWithName: string.
		parent := pkRules
	]

	name [ ^name ]

	description [
		| desc |
		desc := name.
		parent == nil ifFalse: [ desc := desc, ' : ', parent name ].
		desc := desc, ' {\n'.
		rules allKeys do: [:key | 
			desc := desc, key, ' <- ', (rules objectForKey: key) expression description, '\n'
		].
		^desc, '}'	
	]
		
	subgrammar: string [
		^self class alloc initWithParent: self name: string
	]
]


