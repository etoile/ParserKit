"
============================================================================
  ParserKit.st -- OMeta like parser implementation

  Copyright (C) 2011,2012 Mathieu Suen <mathieu@nebu.li>
  Copyright (C) 2012 Niels Grewe <niels.grewe@halbordnung.de>

  The parser has a slightly different syntax than the OMeta one. Semantics
  could also differ. For the time being to write expression use the 
  PKParseExpression class. See example at the bottom of the file.

    2012/03/08 Rule lookup can be optimize at runtime

    2012/03/05 Fix way input consuming. 

    2012/02/22 Many bug fix and start to implement a OMeta parser. 
      - Todo fix the way we walk throw the input. When to consume or not
    the input etc.
      - Some PK*Expression should be singleton

    2011/09/21 Beginning of the expression tree
      - Get the expression tree implementation inspire from OMGrammar
 
    2011/10/20 Beginning of the OMeta implementation
      - Adding the PKParserBase PKRules class

    2011/11/09 Todo merge PKRules with PKParserBase

============================================================================
"
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

"
============================================================================
  
  Main parser class and builtin declarations of the Étoilé oMeta dialect.
  
============================================================================
"


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


NSObject subclass: PKParser [
	| +rulesRepo input rules delegate |

	+initialize [
		rulesRepo := NSMutableDictionary new.
		self actionizedParserGrammar.
		self loadGrammarsFromBundle: NSBundle mainBundle.
 	]

	+actionizedParserGrammar [
		| ocParser |
		ocParser := (self parserGrammar) subgrammar: '_ActionizedEtoileOMeta'.
		ocParser addRule: 'Nullary' expression: (((ocParser at: 'Identifier') bind: 'nullary')
			actionSelector: #makeNullarySelector: arguments: {'nullary'}).
		ocParser addRule: 'Keyword' expression: ((ocParser at: 'IdentStart') seq: (ocParser at: 'IdentCont') repeat seq: (ocParser at: 'COLON')).
		ocParser addRule: 'KeywordMessagePart' expression: ((((ocParser at: 'Keyword') bind: 'selectorPart')
			seq: ((ocParser at: 'Identifier') bind: 'argument'))
				actionSelector: #makeKeywordMessagePart:argument: arguments: {'selectorPart'. 'argument'}).
		ocParser addRule: 'KeywordMessage' expression: (((ocParser at: 'KeywordMessagePart') repeatOneLeast bind: 'selectorArgumentPairs')
			actionSelector: #makeSelectorAndArguments: arguments: {'selectorArgumentPairs'}).
		ocParser addRule: 'Statements' expression: ((ocParser at: 'KeywordMessage') or: (ocParser at: 'Nullary')).
		^ocParser
	]

	+parserGrammar [
		| oMeta  |
		oMeta := PKParser alloc initWithNewGrammar: '_EtoileOMeta'.
		oMeta addRule: 'EndOfLine' expression: ('\r\n' asExp or: '\n' asExp).
		oMeta addRule: 'Space' expression: (PKWhitespaceExpression new or: (oMeta at: 'EndOfLine')).
		oMeta addRule: 'Comment' expression: ('#' asExp seq: ((oMeta at: 'EndOfLine') not 
            seq: (PKDotExpression new) ) repeat seq: (oMeta at: 'EndOfLine')).
		oMeta addRule: 'Spacing' expression: ((((oMeta at: 'Space') or: (oMeta at: 'Comment')) repeat) actionSelector: #makeEmpty arguments: {}).
		oMeta addRule: 'HexDigit' expression: ((PKRangeExpression alloc initFrom: '0' to: '9') or: (PKRangeExpression alloc initFrom: 'A' to: 'F')).
		oMeta addRule: 'DOT' expression: ((('.' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'DOLLAR' expression: ((('$' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'COLON' expression: (((':' asExp bind: 'expr') seq: (oMeta at: 'Spacing'))restrict:  'expr'  ).
		oMeta addRule: 'CLOSE' expression: ((( ')' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ). 
		oMeta addRule: 'OPEN' expression: ((( '(' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'CCLOSE' expression: ((( '}' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ). 
		oMeta addRule: 'COPEN' expression: ((( '{' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'ACLOSE' expression: ((( ']' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ). 
		oMeta addRule: 'AOPEN' expression: ((( '[' asExp  bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'PLUS' expression: ((('+' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'STAR' expression: ((('*' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'QUESTION' expression: ((('?' asExp bind: 'expr')  seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'NOT' expression: ((('!' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'SLASH' expression: (( '/' asExp seq: (oMeta at: 'Spacing')) actionSelector: #orJunction arguments: {}).
		oMeta addRule: 'AND' expression: ((('&' asExp bind: 'expr') seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'LEFTARROW' expression: ((( '<-' asExp   bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'RIGHTARROW' expression: ((( '->' asExp   bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'CARET' expression: ((('^' asExp   bind: 'expr')seq: (oMeta at: 'Spacing')) restrict:  'expr' ).
		oMeta addRule: 'Char' expression: 
			((('\' asExp seq: ({'n' . 'r' . 't' . ''''. '"' . '[' . ']'. '\'} joinAll bind: 'specialChar'))  
                          actionSelector: #parseSpecialChar: arguments: {'specialChar'})
				or: (('\' asExp seq: (((oMeta at: 'HexDigit') 
							    seq: (oMeta at: 'HexDigit')) bind: 'hexChar'))
				  actionSelector: #parseHexChar: arguments: {'hexChar'})
			    or: ('\' asExp not seq: (PKDotExpression new)  )).
		oMeta addRule: 'BuiltinRange' expression: ((('[:' asExp) seq: 
			(((('alpha' asExp) or: ('alnum' asExp) or: ('digit' asExp))
				or: ('lower' asExp) or: ('upper' asExp) or: ('space' asExp))
			 bind: 'builtinRange')
			seq: (':]' asExp)) actionSelector: #makeBuiltinRange: arguments: {'builtinRange'}).
		oMeta addRule: 'Range' expression: (((((oMeta at: 'Char') bind: 'first') 
        	seq: '-' asExp seq: ((oMeta at: 'Char') bind: 'second')) 
				 actionSelector: #makeRangeFrom:to: arguments: {'first'. 'second'})
		or: (oMeta at: 'BuiltinRange')
        	or: (((oMeta at: 'Char') bind: 'tok') actionSelector: #makeToken: arguments: {'tok'})).
		oMeta addRule: 'Class' expression: (('[' asExp 
			seq: ((']' asExp not seq: (oMeta at: 'Range')) repeat bind: 'rangeList')
                	seq: ']' asExp 
                	seq: (oMeta at: 'Spacing')) actionSelector: #join: arguments: {'rangeList'}).
		oMeta addRule: 'Literal' expression: ((('''' asExp 
                seq: (('''' asExp not seq: (oMeta at: 'Char')) repeat bind: 'literal') 
				seq: '''' asExp seq: (oMeta at: 'Spacing') ) 
			or: ('"' asExp 
                seq: (('"' asExp not seq: (oMeta at: 'Char')) repeat bind: 'literal') 
				seq: '"' asExp seq: (oMeta at: 'Spacing') ))
		  actionSelector: #makeLiteral: arguments: {'literal'}).
		oMeta addRule: 'IdentStart'  expression: ((PKRangeExpression alloc initFrom: 'a' to: 'z') 
			or: (PKRangeExpression alloc initFrom: 'A' to: 'Z')
			or: '_' asExp).
		oMeta addRule: 'IdentCont' expression: ((oMeta at: 'IdentStart') or: (PKRangeExpression alloc initFrom: '0' to: '9')).
		oMeta addRule: 'Identifier' expression: (((((oMeta at: 'IdentStart') seq: ((oMeta at: 'IdentCont') repeat)) bind: 'ident') seq: (oMeta at: 'Spacing'))
			restrict: 'ident').
		oMeta addRule: 'SuperRuleApplication' expression: (((oMeta at: 'CARET') seq: ((oMeta at: 'Identifier') bind: 'rule'))
			actionSelector: #makeRuleLookup:fromSuperGrammar: arguments: {'rule'. 'superGrammar'}).
		oMeta addRule: 'ForeignRuleApplication' expression: ((((oMeta at: 'Identifier') bind: 'grammar')
			seq: ('::' asExp)
			seq: ((oMeta at: 'Identifier') bind: 'rule'))
				actionSelector: #makeRuleLookup:fromGrammar: arguments: {'rule'. 'grammar'}).
		oMeta addRule: 'RuleApplication' expression: ((oMeta at: 'SuperRuleApplication')
			or: (oMeta at: 'ForeignRuleApplication')
			or: ((((oMeta at: 'Identifier') bind: 'rule') seq: ((oMeta at: 'LEFTARROW') not))
				actionSelector: #makeRuleLookup: arguments: {'rule'})).
		oMeta addRule: 'ParenthesizedExpression' expression: (((oMeta at: 'OPEN')
			seq: ((oMeta at: 'Expression') bind: 'expr')
			seq: (oMeta at: 'CLOSE'))
				restrict: 'expr').
		oMeta addRule: 'Primary' expression: (((((oMeta at: 'RuleApplication') bind: 'expr') seq: (oMeta at: 'LEFTARROW') not)
				restrict: 'expr')
			or: (oMeta at: 'ParenthesizedExpression')
			or: (oMeta at: 'Literal')
			or: (oMeta at: 'Class')
			or: (((oMeta at: 'DOT') actionSelector: #makeWildcard arguments: {})
				or: ((oMeta at: 'DOLLAR') actionSelector: #makeEOF arguments: {}))).
		oMeta addRule: 'Suffix' expression: ((((oMeta at: 'Primary') bind: 'expression')
            seq: (((oMeta at: 'QUESTION') or: (oMeta at: 'STAR') or: (oMeta at: 'PLUS')) maybe bind: 'modifier')
			seq: ((oMeta at: 'Binding') maybe bind: 'bindingName')
			seq: ((oMeta at: 'Predicate') maybe bind: 'predicate'))
			   actionSelector: #makeExpression:modifier:bind:predicate: arguments: {'expression'. 'modifier'. 'bindingName'. 'predicate'}).
		oMeta addRule: 'Prefix' expression: ((((((oMeta at: 'AND') or: (oMeta at: 'NOT')) maybe bind: 'junction') 
            seq: ((oMeta at: 'Suffix') bind: 'expression'))
			   actionSelector: #makePrefix:exp: arguments: {'junction'. 'expression'})
			or: (((oMeta at: 'Binding') bind: 'bindingName')
				actionSelector: #makeAnythingBind: arguments: {'bindingName'})).
		oMeta addRule: 'Action' expression: (((oMeta at: 'RIGHTARROW')
			seq: (oMeta at: 'AOPEN')
			seq: ((oMeta at: 'Statements') bind: 'actionStatements')
			seq: (oMeta at: 'ACLOSE'))
				actionSelector: #makeAction: arguments: {'actionStatements'}).
		oMeta addRule: 'Restriction' expression: (((oMeta at: 'RIGHTARROW')
			seq: ((oMeta at: 'Identifier') bind: 'bindingName'))
				actionSelector: #makeRestriction: arguments: { 'bindingName' }).
		oMeta addRule: 'Binding' expression: ((':' asExp seq: ((oMeta at: 'Identifier') bind: 'bindingName')) restrict: 'bindingName').
		oMeta addRule: 'Predicate' expression: (((oMeta at: 'QUESTION') seq: (oMeta at: 'OPEN') seq: ((oMeta at: 'Identifier') bind: 'target')
		    seq: ((oMeta at: 'Statements') bind: 'predicateMessage') seq: (oMeta at: 'CLOSE'))
		       actionSelector: #makePredicate:target: arguments: {'predicateMessage'. 'target'}). 
		oMeta addRule: 'Sequence' expression: ((((oMeta at: 'Prefix')  repeat bind: 'expressions')
        	seq: (((oMeta at: 'Action') or: (oMeta at: 'Restriction')) maybe bind: 'action'))
				actionSelector: #makeSequenceExpression:actionOrRestriction: arguments: {'expressions'. 'action'}).
		oMeta addRule: 'Expression' expression: ((((oMeta at: 'Sequence') bind: 'expression1')
			seq: ((((oMeta at: 'SLASH')
			seq: (oMeta at: 'Sequence')) repeat) bind: 'alternative'))
				actionSelector: #makeAlternativeExpression:alternative: arguments: { 'expression1'. 'alternative' }).
		oMeta addRule: 'Definition' expression: ((((oMeta at: 'Identifier') bind: 'ruleName')
			seq: (oMeta at: 'LEFTARROW')
			seq: ((oMeta at: 'Expression') bind: 'ruleExpression'))
				actionSelector: #makeRule:expression: arguments: {'ruleName'. 'ruleExpression'}).
		oMeta addRule: 'Grammar' expression: (((oMeta at: 'Spacing') seq: (((oMeta at: 'Definition') repeatOneLeast) bind: 'expr'))
			restrict:  'expr').
		oMeta addRule: 'SuperGrammarIdentifier' expression: (((oMeta at: 'COLON') seq: ((oMeta at: 'Identifier') bind: 'super'))
			actionSelector: #makeSuperGrammar: arguments: {'super'}).
		oMeta addRule: 'Ometa' expression: ((((oMeta at: 'Identifier') bind: 'grammar')
			seq: (((oMeta at: 'SuperGrammarIdentifier') maybe bind: 'superGrammar'))
            seq: (oMeta at: 'COPEN')
			seq: ((oMeta at: 'Grammar') bind: 'grammarList')
			seq: (oMeta at: 'CCLOSE'))
				actionSelector: #makeGrammar:parent:rules: arguments: {'grammar'. 'superGrammar'. 'grammarList'}).
		oMeta addRule: 'OmetaList' expression: (((oMeta at: 'Spacing') 
            seq: (((oMeta at: 'Ometa') repeatOneLeast) bind: 'grammars')
			seq: PKEmptyExpression uniqueInstance)
				restrict: 'grammars').
		^oMeta
	]

	+derivate: parent subgrammar: name [
		| rule newRule |
		newRule := parent subgrammar: name.
		rulesRepo setValue: newRule forKey: name.
		^newRule
	]

	+getGrammar: name [
		| rule |
		rule := rulesRepo objectForKey: name.
		rule == nil ifTrue: [
			^NSException raise: 'ParserKit' format: 'Cannot load grammar ''', name, ''''
		].
		^rule	
	]

	+getNewGrammar: name [
		| rule |
		rule := PKRules alloc initWithName: name.
		rulesRepo setValue: rule forKey: name.
		^rule	
	]

	setDelegate: anObject [
		delegate := anObject
	]

	+supportsGrammar: name [
		^((rulesRepo objectForKey: name) == nil) not.
	]

	+loadGrammarsFromBundle: bundle [
		|files|
		files := bundle pathsForResourcesOfType: 'pk'
		                            inDirectory: nil.
		files leftFoldWithInitialValue: {}
		                     intoBlock: [ :acc :each|
			acc arrayByAddingObjectsFromArray:
			  (self loadGrammarsFromString: (NSString stringWithContentsOfFile: each)).
		] 
	]
	
	+loadGrammarsFromString: string [
		| parserParser internalDelegate match grammars notificationCenter |
		internalDelegate := PKParserRuleGenerator new.
		parserParser := PKParser alloc initWithGrammar: '_ActionizedEtoileOMeta'.
		parserParser setDelegate: internalDelegate.
		match := parserParser match: string rule: 'OmetaList'.
		"TODO: Smarter error reporting."
		match isSuccess ifFalse: [NSException raise: 'PKParserException' format: 'Could not load grammar.'].
		notificationCenter := NSNotificationCenter defaultCenter.
		grammars := match reduce asArray.
		grammars do: [ :each |
			notificationCenter postNotificationName: 'PKParserGrammarBecameAvailable'
			                                 object: self
                                           userInfo: (NSDictionary dictionaryWithObject: (each name)
			                                 forKey: 'name').
		].
		^grammars map: [ :each | each name ].
	]
    

	initWithGrammar: grammarName [
		super init.
		rules := self class getGrammar: grammarName.
		^self
	]

	initWithNewGrammar: grammarName [
		super init.
		rules := self class getNewGrammar: grammarName.
		^self
	]

	subgrammar: name [
		rules := self class derivate: rules subgrammar: name.
	]

	at: rule [
		^PKNonTerminalLookupExpression alloc initWithGrammar: self name: rule
	]

	addRule: name expression: exp  [
		rules addRule: name expression: exp
	]

	description [
		^rules description
	]
	

	apply: rule [
		^self apply: rule withInit: nil delegate: delegate 
	]

	apply: rule withInit: init delegate: aDelegate[
		| exp |
		exp := rules lookup: rule ifFailed: [
			NSException raise: 'ParserKit' format: ('Invalid rule ', rule)
		].
		(init == nil) ifFalse: [ exp := init seq: exp ].
		^exp parseInput: input withCurrentParser: self delegate: aDelegate.
	]
	
	match: inputStream rule: rule [
		^self matchStream: (PKInputStream alloc initWithStream: inputStream)
		             rule: rule
		         withInit: (rules lookup: '__init__' ifFailed: [nil])
			 delegate: delegate.
	]

	matchStream: stream rule: rule delegate: aDelegate [
		^self matchStream: stream rule: rule withInit: nil delegate: aDelegate.
	]
	
	matchStream: stream rule: rule withInit: init delegate: aDelegate [
		|match|
		(aDelegate == nil) ifTrue: [aDelegate := delegate].
		input := stream.	
		match := self apply: rule withInit: init delegate: aDelegate.
		match setDelegate: aDelegate.
		^match
	]

	rules  [ ^rules ]
	setRules: someRules [rules := someRules]
   

	getMatchWithInput: list length: len  [
		^PKParseMatch alloc initWithInput: list length: len.
	]

	getMatchCopyWithInput: list range: range  [
		^PKParseMatch alloc copyInitWith: list range: range.
	]

	getEmptyMatch: list [
		^PKParseMatch emptyMatch: list
	]


	getFailureWithInput: list description: desc cause: cause [
		^PKParseFail alloc initWithInput: list description: desc cause: cause.
	]
]


"
============================================================================
Delegate and utilities to parse oMeta grammars
============================================================================
"

"
  Expression generator, presently only used for alternative expressions.
"
NSObject subclass: PKAstExpressionGen [
	| expression operation |

	initWithExp: exp operation: op [
		expression := exp.
		operation := op
	]

	reduce: exp [
		exp == nil 
            ifFalse: [ expression ]
			ifTrue: [ operation value: exp value: expression ]
	]
]


"
  The purpose of the delayed expression builder is to defer generating
  expressions that depend on global state until after the entire grammar
  has been parsed.
"
NSObject subclass: PKDelayedExpressionBuilder [
	| block exp |

	initWithBlock: aBlock [
		block := aBlock.
		exp := nil.
		^self.
	]

	initWithExp: anExp [
		exp := anExp.
		block := nil.
		^self
	]

	asExp [ ^self ]
	
	bind: name [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value bind: name ].
		
	]

	repeat [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value repeat ].
	]
	
	repeatOneLeast [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value repeatOneLeast ].
	]

	maybe [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value maybe ].
	]

	parameter: predicate [
		^PKDelayedExpressionBuilder alloc initWithBlock: [ self value parameter: predicate ].
	]

	semanticAction: action [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value semanticAction: action ].
	]

	restrict: binding [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value restrict: binding ].
	]

	not [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value not ].
	]

	lookahead [
		^PKDelayedExpressionBuilder alloc initWithBlock: [self value lookahead ].
	]

	seq: exp [
		^(exp isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
			PKDelayedExpressionBuilder alloc initWithBlock: [self value seq: exp value ]
		] ifFalse: [
			PKDelayedExpressionBuilder alloc initWithBlock: [self value seq: exp ]
		]
	]

	or: exp [
		^(exp isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
			PKDelayedExpressionBuilder alloc initWithBlock: [self value or: exp value ]
		] ifFalse: [
			PKDelayedExpressionBuilder alloc initWithBlock: [self value or: exp ]
		]
	]
	
	value [ ^(nil == exp) ifTrue: [ block value ]
		                 ifFalse: [ exp ]	
	]
]

"
  Delegate class that generates a grammar. The main entry point is
  #makeGrammar:parent:rules. That method also installs the parsed grammars into
  the rule repository.

  Dependencies on foreign grammars are not yet automatically resolved. You need
  to make sure that all referenced grammars have already been registered.
"
PKParserAbstractGenerator subclass: PKParserRuleGenerator [

	makeLiteral: literal [
		| result |
		(literal isKindOfClass: NSArray class) ifTrue: [
			result := literal componentsJoinedByString: ''.
		] ifFalse: [ result := literal ].
		^result asExp
	]
	makeRangeFrom: first to: second [
		^PKRangeExpression alloc initFrom: first to: second.
	]

	makeBuiltinRange: builtin [
		| exp |
		'alpha' = builtin ifTrue: [exp := PKAlphabeticExpression new].	
		'alnum' = builtin ifTrue: [exp := PKAlphanumericExpression new].	
		'digit' = builtin ifTrue: [exp := PKNumericExpression new].	
		'lower' = builtin ifTrue: [exp := PKLowercaseExpression new].	
		'upper' = builtin ifTrue: [exp := PKUppercaseExpression new].	
		'space' = builtin ifTrue: [exp := PKWhitespaceExpression new].	

		^exp
	]

	makeToken: tok [
		^PKTokenExpression alloc initWithPattern: tok

	]

	makeSuperGrammar: sup [
		^PKParser getGrammar: sup.
	]

	makeGrammar: grammarName parent: superGrammar rules: rules [
		| grammar |
		"Note: The grammars returned by PKParser are actually PKRules instances."
		'' = superGrammar ifTrue: [
			grammar := PKParser getNewGrammar: grammarName
		] ifFalse: [
			grammar := PKParser derivate: superGrammar subgrammar: grammarName.
		].
		ETTranscript debug: 'Building grammar ''', grammarName, ''''; debugCr.
		
		rules do: [ :each |
			| name expression |
			name := each objectForKey: 'rule'.
			expression := each objectForKey: 'expression'.
			" We need to materialize expressions whose building has been delayed
			  because the need to know about the grammars. "
			(expression isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
				expression := expression value.
			].
			ETTranscript debug: 'Adding rule ''', name, ''' expression: ', (expression description); debugCr.
			grammar addRule: name expression: expression.
		].
		delegate ifResponds loadedGrammar: grammarName.
		^grammar 
	]

	makeNullarySelector: sel [
		^sel selValue
	]



	makeEOF [^PKEmptyExpression uniqueInstance]

	makeKeywordMessagePart: keyword argument: arg [
		^NSDictionary dictionaryWithObjects: { keyword componentsJoinedByString: ''. arg }
		                            forKeys: { 'selectorPart'. 'argumentName' }
	]

	makeSelectorAndArguments: components [
		| selector args |
		selector := ''.
		args := NSMutableArray new.
		(components isKindOfClass: NSArray class) ifFalse: [ components := { components } ].
		components do: [ :each |
			selector := selector, (each objectForKey: 'selectorPart').
			args addObject: (each objectForKey: 'argumentName').
		].
		^ NSDictionary dictionaryWithObjects: { selector. args }
		                             forKeys: { 'selector'. 'arguments' }
	]

	makeAction: actionInfo [
		^(actionInfo isKindOfClass: NSDictionary class) ifTrue: [
			PKParseAction alloc initWithSelector: (actionInfo objectForKey: 'selector')
		     	                   argumentNames: (actionInfo objectForKey: 'arguments') 	
		] ifFalse: [
			PKParseAction alloc initWithSelector: actionInfo argumentNames: nil
		]
	]

	makeRestriction: binding [
		^PKParseRestriction alloc initWithBinding: binding
	]

	makePredicate: predicateInfo target: target [
		^(predicateInfo isKindOfClass: NSDictionary class) ifTrue: [
			PKParsePredicate alloc initWithTargetName: target
			                                 selector: (predicateInfo objectForKey: 'selector')
			                            argumentNames: (predicateInfo objectForKey: 'arguments')
		] ifFalse: [
			PKParsePredicate alloc initWithTargetName: target
			                                 selector: predicateInfo
			                            argumentNames: nil
		]
	]

	makeRule: ruleName expression: expression [
		^NSDictionary dictionaryWithObjects: { ruleName. expression }
                                    forKeys: { 'rule'. 'expression' }	
	] 

	makeExpression: expression modifier: mode bind: name predicate: predicate [
		mode = '+' ifTrue: [ expression := expression repeatOneLeast ].
		mode = '*' ifTrue: [ expression := expression repeat ].
		mode = '?' ifTrue: [ expression := expression maybe ].
		name = '' ifFalse: [ expression := expression bind: name ].
		predicate = '' ifFalse: [ expression parameter: predicate ].
		^expression
	]

	makePrefix: junction exp: expression [
		junction = '!' ifTrue: [ expression := expression not ].
		junction = '&' ifTrue: [ expression := expression lookahead ].	
		^expression
	]

	makeSequenceExpression: expressions actionOrRestriction: action [
		| expression |
		(expressions isKindOfClass: NSArray class) ifTrue: [
			expression := expressions leftFoldWithInitialValue: nil
			                                         intoBlock: [ :acc :exp|
				(nil == acc) ifTrue: [ exp ]
				            ifFalse: [ 
					"If the argument and not the receiver is a delayed builder, we need to wrap
					 the receiver in one."
					(acc isKindOfClass: PKDelayedExpressionBuilder class) ifFalse: [
						(exp isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
							acc := PKDelayedExpressionBuilder alloc initWithExp: acc
						]
					].
					acc seq: exp ]
			].
		] ifFalse: [
			expression := expressions.
		].
		action = '' ifFalse: [
			(action isKindOfClass: (PKParseAction class)) ifTrue: [
				expression := expression semanticAction: action
			] ifFalse: [
				"It's a restriction statement, but we need to unpack the binding again"
				expression := expression restrict: action description.
			].
		].
		^expression.
	]
	
	makeAlternativeExpression: exp1 alternative: alts [
		| expression |
		'' = alts ifTrue: [ expression := exp1 ]
		       ifFalse: [
			| op expectObj |
			expectObj := false.
			op := nil.
			expression := alts leftFoldWithInitialValue: exp1
			                                  intoBlock: [ :acc :expOrBlock|
				expectObj ifTrue: [
					" The current value is an object, we make sure that the next is being
					  interpreted as a block and update the accumulator by executing the block. "
					expectObj := false.
					"If the argument and not the receiver is a delayed builder, we need to wrap
					 the receiver in one."
					(acc isKindOfClass: PKDelayedExpressionBuilder class) ifFalse: [
						(expOrBlock isKindOfClass: PKDelayedExpressionBuilder class) ifTrue: [
							acc := PKDelayedExpressionBuilder alloc initWithExp: acc
						]
					].
					op value: acc value: expOrBlock
				] ifFalse: [
					" The next element will be an object, we store the operation and return the
					  present state of the accumulator. " 
					op := expOrBlock.
					expectObj := true.
					acc
				]
			].
		].
		^expression
	]
	
	" Returns a closure that is wrapped in an expressionBuilder which can be
	  evaluated by the action creating the grammar in order to install the rule
	  lookup. "
	makeRuleLookup: ruleName fromGrammar: grammarName [
		^PKDelayedExpressionBuilder alloc initWithBlock: [
			PKNonTerminalLookupExpression alloc initWithGrammar: (PKParser alloc initWithGrammar: grammarName)
			                                    name: ruleName
		]
	]

	makeRuleLookup: ruleName [
		^PKDelayedExpressionBuilder alloc initWithBlock: [
			PKNonTerminalLookupExpression alloc initWithGrammar: nil
			                                    name: ruleName
		]
	]

	" Super lookups are less problematic because the super grammar is
	  required to be resolved prior to the grammar we are parsing right
	  now. "
	makeRuleLookup: ruleName fromSuperGrammar: superGrammar [
		^PKNonTerminalLookupExpression alloc initWithGrammar: superGrammar
			                                 name: ruleName
	]


	orJunction [^[:exp1 :exp2 | exp1 or: exp2 ]]
	seqJunction [^[:exp1 :exp2 | exp1 seq: exp2 ]]

	makeWildcard [^PKDotExpression new]

	makeAnythingBind: name [ ^(PKAnythingExpression uniqueInstance) bind: name ]

	join: list [
		^list joinAll
	]

	sequence: list [
		^list sequenceAll
	]
]


PKParserAbstractGenerator subclass: PKParserASTGenerator [
	| +rangeBuiltinSelectors externalParsers inputStreamDeclaration tempDecl methodStatements currentTempsCount |

	+initialize [
		rangeBuiltinSelectors := NSDictionary alloc initWithObjects:
		  { 'isAlphabetic' . 'isUppercase' . 'isLowercase' . 'isDigit' . 'isAlphanumeric' . 'isWhitespace' }
		                                                    forKeys:
		  { 'alpha' . 'upper' . 'lower' . 'digit' . 'alnum' . 'space' }
	]

	+selectorForBuiltinRange: name [ ^rangeBuiltinSelectors objectForKey: name ]

	genTemp [
		| tempName |
		tempName := 'temp', currentTempsCount description.
		currentTempsCount := currentTempsCount + 1.
		tempDecl setValue: (LKDeclRef referenceWithSymbol: tempName) forKey: tempName.
		^tempDecl objectForKey: tempName
	]

	genOr: first alternate: second [
		| ifTest match assign test |
		
		match := self genTemp.
		ETTranscript show: 'genOr:alternate: First exp: '; show: first; cr.
		methodStatements addObject: ( LKAssignExpr assignWithTarget: match expr: first).
		ifTest := LKMessageSend messageWithSelectorName: 'isFailure'.
		ifTest setTarget: match.
		test := LKIfStatement ifStatementWithCondition: ifTest then: { second } else: { match }.
		^test
	]

	genSeq: first alternate: second [
		| match1 match2 firstAssign secondAssign ifTest ifTestLeft ifTestRight test successStatement |
		match1 := self genTemp.
		match2 := self genTemp.
		firstAssign := LKAssignExpr assignWithTarget: match1 expr: first.
		secondAssign := LKAssignExpr assignWithTarget: match2 expr: second.
		
		ifTestLeft := LKMessageSend messageWithSelectorName: 'isSuccess'.
		ifTestLeft setTarget: match1.
		ifTestRight := LKMessageSend messageWithSelectorName: 'isSuccess'.
		ifTestRight setTarget: match2.
		
		ifTest := LKMessageSend messageWithSelectorName: 'and:' arguments: { ifTestRight }.
		ifTest setTarget: ifTestLeft.
		successStatement := LKMessageSend  messageWithSelectorName: 'sequenceWith:'
			arguments: {match2}.
		successStatement setTarget: match1.
		"Error can be better report with more information but for the time being is good enough"
		test := LKIfStatement ifStatementWithCondition: ifTest then: {
			successStatement
		} else: { 	 
			self genFailDescription: (LKLiteral literalFromString: 'Both expression failed') 
		}.
		methodStatements addObject: secondAssign.
		methodStatements addObject: firstAssign.
		^test
	]

	init [
		super init.
		externalParsers := NSMutableDictionary new.
		tempDecl := NSMutableDictionary new.
		inputStreamDeclaration := LKDeclRef referenceWithSymbol: 'inputStream'.
		methodStatements := NSMutableArray new.
		currentTempsCount := 0.
		^self
	]

	maybeBlock [
		^[:expr |
			|  ifTest tempExp pkMatch emptySuccess |
			tempExp := self genTemp.
			methodStatements addObject: (LKAssignExpr assignWithTarget: tempExp expr: expr).
			ifTest := LKMessageSend messageWithSelectorName: 'isFailure'.
			ifTest setTarget: tempExp.
			pkMatch := LKMessageSend messageWithSelectorName: 'alloc'.
			pkMatch setTarget: (LKSymbolRef referenceWithSymbol: 'PKParseMatch').
			emptySuccess := LKMessageSend messageWithSelectorName:  'initWithInput:length:'
				arguments: { inputStreamDeclaration. 0 }.
			emptySuccess setTarget: pkMatch.
			LKIfStatement ifStatementWithCondition: ifTest
		                                   then: { emptySuccess }
		                                   else: { tempExp }
		]
	]

	genRepeatLoop: expr [
		
		| emptyMatch returnMatch loopTest loop currentMatch currentMatchDecl test newMatch |
		returnMatch := self genTemp.
		emptyMatch := LKMessageSend messageWithSelectorName: 'emptyMatch:' arguments: {inputStreamDeclaration}.
		emptyMatch setTarget: (LKSymbolRef referenceWithSymbol: 'PKParseMatch').
		methodStatements addObject: (LKAssignExpr assignWithTarget: returnMatch expr: emptyMatch).
		currentMatchDecl := self genTemp.
		currentMatch := LKAssignExpr assignWithTarget: currentMatchDecl expr: expr.
		test := LKMessageSend messageWithSelectorName: 'isSuccess'.
		test setTarget: currentMatchDecl.
		loopTest := LKBlockExpr  blockWithArguments: {} locals: {  } statements: {currentMatch. test }.
		newMatch := LKMessageSend messageWithSelectorName: 'sequenceWith:' arguments: {currentMatchDecl}.
		newMatch setTarget: returnMatch.
		newMatch := LKAssignExpr assignWithTarget: returnMatch expr: newMatch.
		loop := LKBlockExpr blockWithArguments: {} locals: {}  statements:  { newMatch }.
		loop := LKMessageSend messageWithSelectorName: 'whileTrue:' arguments: {loop}.
		loop setTarget: loopTest.
		methodStatements addObject: loop.
		^returnMatch.
	]

	manyBlock [
		^[:expr |
			self genRepeatLoop: expr.
		]
	]

	manyOnceBlock [
		^[:expr | 
			| test  return pop failure initFailure |
			return := self genRepeatLoop: expr.
			test := LKMessageSend messageWithSelectorName: 'isEmpty'.
			test setTarget: return.
			pop := LKMessageSend messageWithSelectorName: 'popPosition'.
			pop setTarget: inputStreamDeclaration.
			failure := LKMessageSend messageWithSelectorName: 'new'.
			failure setTarget:  (LKSymbolRef referenceWithSymbol: 'PKParseFail').

			"Argument are temporary wrong instead of the 'return' we
			should show the 'currentMatch in the genRepeatLoop"
			initFailure := LKMessageSend messageWithSelectorName: 'initWithInput:description:cause:'
				arguments: { inputStreamDeclaration. LKStringLiteral literalFromString: 'Unexpected token'. return  }.
			initFailure setTarget: failure.
				
			LKIfStatement ifStatementWithCondition: test
		                                   then: {  pop. initFailure  }
		                                   else: { return }
		]
	]

	genExternalGrammarReferenceFor: grammarName [
		^externalParsers at: grammarName ifAbsentPut: [
			LKDeclRef referenceWithSymbol: 'grammarName'
		]
	]

	genFailDescription: literal [
		| pkParseFail messageAlloc messageInit  |
		pkParseFail := LKSymbolRef referenceWithSymbol: 'PKParseFail'.
		messageAlloc := LKMessageSend messageWithSelectorName: 'alloc'.
		messageAlloc setTarget: pkParseFail.
		messageInit := LKMessageSend messageWithSelectorName: 'initWithInput:description:'
			arguments: {inputStreamDeclaration. literal}.
		messageInit setTarget: messageAlloc.
		^messageInit
	]

	" Reference to the superclass ivar for the delegate "
	delegateRef [ ^LKDeclRef referenceWithSymbol: 'delegate' ]

	" Gets a failure at the present position the description string will be 
	  turned into a literal, cause is supposed to be nil or a reference to 
	  the failure causing this one. "
	getFailureWithDescription: desc cause: cause [
		| descLiteral causeRef msg |
		cause == nil ifTrue: [ causeRef := LKNilRef builtin ]
		            ifFalse: [ causeRef := cause ].
		descLiteral := LKLiteral literalFromString: desc.
		msg := LKMessageSend messageWithSelectorName: 'getFailWithInput:description:cause:'
		arguments: { inputStreamDeclaration . descLiteral . causeRef }.
		msg setTarget: (LKSelfRef referenceWithSymbol: 'self').
		^msg
	]

	" Gets a match of the specified length. "
	genMatchOfLength: len [
		| msg |
		msg := LKMessageSend messageWithSelectorName: 'getMatchWithInput:length:'
		arguments: { inputStreamDeclaration . len }.
		msg setTarget: (LKSelfRef referenceWithSymbol: 'self').
		^msg
	]

	genEmptyMatch [
		| msg |
		msg := LKMessageSend messageWithSelectorName: 'getEmptyMatch:'
		arguments: { inputStreamDeclaration }.
		msg setTarget: (LKSelfRef referenceWithSymbol: 'self').
		^msg
	]

	ifAtEndThenFailElse: elseStatements [
		| isAtEnd |
		isAtEnd := LKMessageSend messageWithSelectorName: 'atEnd'.
		isAtEnd setTarget: inputStreamDeclaration.
		^LKIfStatement ifStatementWithCondition: isAtEnd
		                                   then: { self getFailureWithDescription: 'Unexpected end of stream' cause: nil }
		                                   else: elseStatements
		
	]

	makeLiteral: literal [
		| theLit litLen listHead comparison |
		(literal isKindOfClass: NSArray class) ifTrue: [
			theLit := literal componentsJoinedByString: ''.
		] ifFalse: [ theLit := literal ].
		" Build LKLiterals for the literal we are matching and its length. "
		litLen := LKNumberLiteral literalFromString: ((theLit matchSize) stringValue).
		theLit := LKLiteral literalFromString: theLit.

		" Message send to obtain the appropriate number of characters from the input
		  stream "
		listHead := LKMessageSend messageWithSelectorName: 'head:'
		                                        arguments: { litLen }.
		listHead setTarget: inputStreamDeclaration.

		" Message send to check whether the literal matches the head of the stream "
		comparison := LKMessageSend messageWithSelectorName: 'isEqual:'
		                                          arguments: { listHead }.
		comparison setTarget: theLit.
		^LKIfStatement ifStatementWithCondition: comparison
		                                   then: { self genMatchOfLength: litLen }
		                                   else: {
		  self getFailureWithDescription: ('Expected literal "', theLit description, '"') cause: nil }
	]

	makeToken: tok [ 
		ETTranscript show: 'makeToken:'; cr.
		self makeLiteral: tok 
	]

	makeWildcard [
		| isAtEnd getHead getHeadLength|
		ETTranscript show: 'makeWildcard'; cr.
		isAtEnd := LKMessageSend messageWithSelectorName: 'atEnd'.
		isAtEnd setTarget: inputStreamDeclaration.
		getHead := LKMessageSend messageWithSelectorName: 'head'.
		getHead setTarget: inputStreamDeclaration.
		getHeadLength := LKMessageSend messageWithSelectorName: 'length'.
		getHeadLength setTarget: getHead.
		^LKIfStatement ifStatementWithCondition: isAtEnd
		                                   then: { self getFailureWithDescription: 'Unexpected end of stream' cause: nil }
		                                   else: { self genMatchOfLength: getHeadLength }
		
	]

	makeEOF [ 
		| isAtEnd |
		ETTranscript show: 'makeEOF'; cr.
		isAtEnd := LKMessageSend messageWithSelectorName: 'atEnd'.
		isAtEnd setTarget: inputStreamDeclaration.
		^LKIfStatement ifStatementWithCondition: isAtEnd
		                                   then: { self genEmptyMatch }
		                                   else: { self getFailureWithDescription: 'Expected end of stream' cause: nil }

	]

	makeSuperGrammar: ident [
		"TODO"
		ETTranscript show: 'makeSuperGrammar:'; cr.
		^ ident.
	]

	makeGrammar: grammarName parent: parentName rules: methods [
		| parentClassName newGrammar |
		ETTranscript show: 'makeGrammar:';show: grammarName; show: ' parent:'; show: parentName; show: ' rules:'; show: methods; cr.

		parentClassName := (parentName = '') ifTrue: [ 'PKParser'] ifFalse: ['PK',parentName].
	
		newGrammar := LKSubclass subclassWithName: 'PK',grammarName
			superclassNamed: parentClassName
			cvars: {}
			ivars: {}
			methods: methods.
		"externalParsers := NSMutableDictionary new."
		^newGrammar
	]

	makeAlternativeExpression: exp1 alternative: alts [
		| matchFirst test isBlock exp if testLoop match |
		ETTranscript show: 'makeAlternativeExpression:alternative:'; cr.
		alts = '' ifTrue: [^exp1].
		matchFirst := self genTemp.
		methodStatements addObject: (LKAssignExpr assignWithTarget: matchFirst expr: exp1).
		test := LKMessageSend messageWithSelectorName: 'isFailure'.
		exp := LKIfStatement ifStatementWithCondition: test.
		exp setElseStatements: { matchFirst }.
		alts leftFoldWithInitialValue: exp intoBlock: [:acc :current | 
			match := self genTemp.
			testLoop := LKMessageSend messageWithSelectorName: 'isFailure'.
			testLoop setTarget: match.
			if := LKIfStatement ifStatementWithCondition: testLoop.
			if setElseStatements: { match }.
			"Then statemetns is override in the next iteration except for the last one."
			if setThenStatements: { match }.
			acc setThenStatements: { 
				LKAssignExpr assignWithTarget: match expr: current.
				if
			}.
			if
		].
		^exp
	]

	makeRule: ruleName expression: statement [
		| message method |
		ETTranscript show: 'makeRule:expression:'; cr.
		"TODO: Need to add the methodStatements and locals vars. statements should be
		 transformed into a return node"
		message := LKMessageSend messageWithSelectorName: ('parser', ruleName, 'FromInputStream:').
		methodStatements addObject: (LKReturn returnWithExpr: statement).
		method := LKMethod methodWithSignature: message locals: tempDecl statements: methodStatements.
		tempDecl := NSMutableDictionary new.
		methodStatements := NSMutableArray new.
		currentTempsCount := 0.
		^method
	]

	makeRuleLookup: ruleName [
		| msg |
		ETTranscript show: 'makeRuleLookup:'; cr.
		msg := LKMessageSend messageWithSelectorName: ('parser', ruleName, 'FromInputStream:')
			                 arguments: { inputStreamDeclaration }.
		msg setTarget: (LKSelfRef referenceWithSymbol: 'self').
		^msg.
	]

	makeRuleLookup: ruleName fromSuperGrammar: superGrammar [
		| msg |
		ETTranscript show: 'makeRuleLookup:fromSuperGrammar:'; cr.
		msg := LKMessageSend messageWithSelectorName: ('parse', ruleName, 'FromInputStream:')
			                 arguments: { inputStreamDeclaration }.
		msg setTarget: (LKSuperRef referenceWithSymbol: 'super').
		^msg.
	]

	makeRuleLookup: ruleName fromGrammar: grammarName [
		| lookupMsg parseMsg  |
		ETTranscript show: 'makeRuleLookup:fromGrammar:'; cr.
		" Foreign rule invocations require us to obtain a parser for
		  the grammar and invoke the method corresponding to the rule
		  from there.  The external parameter is going to be instance
		  variable initilize with the corresponding grammar."
		parseMsg := LKMessageSend messageWithSelectorName: ('parse', ruleName, 'FromInputStream:')
			                      arguments: { inputStreamDeclaration }.
		parseMsg setTarget: (self genExternalGrammarReferenceFor: grammarName).
		^parseMsg.
	]

	makeBuiltinRange: name [
		| listHead charAtIndex comparison |
		ETTranscript show: 'makeBuiltinRange:'; cr.

		listHead := LKMessageSend messageWithSelectorName: 'head'.
		listHead setTarget: inputStreamDeclaration.
		charAtIndex := LKMessageSend messageWithSelectorName: 'characterAtIndex:'
		                                           arguments: { LKNumberLiteral literalFromString: '0' }.
		charAtIndex setTarget: listHead.

		" look up the character class test selector and check whether the character matches"
		comparison := LKMessageSend messageWithSelectorName: (PKParserASTGenerator selectorForBuiltinRange: name).
		comparison setTarget: charAtIndex.
		^self ifAtEndThenFailElse: { 
		  LKIfStatement ifStatementWithCondition: comparison
		                                    then: { self genMatchOfLength: (LKNumberLiteral literalFromString: '1') }
		                                    else: {
		    self getFailureWithDescription: ('Expected character from class [:', name, ':]') cause: nil }
		  }
	]

	makeRangeFrom: first to: last [
		| block lteLast gteFirst predicate listHead charAtIndex charAssign matchIf blockInvoke |
		ETTranscript show: 'makeRangeFrom:to:'; cr.
		listHead := LKMessageSend messageWithSelectorName: 'head'.
		listHead setTarget: inputStreamDeclaration.
		charAtIndex := LKMessageSend messageWithSelectorName: 'characterAtIndex:'
		                                           arguments: { LKNumberLiteral literalFromString: '0' }.
		charAtIndex setTarget: listHead.
		charAssign := LKAssignExpr assignWithTarget: (LKDeclRef referenceWithSymbol: 'charValue')
		                                       expr: charAtIndex.
		lteLast := LKMessageSend messageWithSelectorName: 'isLessThanOrEqualTo:'
			                                   arguments:
		  { LKNumberLiteral literalFromString: ((last characterAtIndex: 0) stringValue) }.
		lteLast setTarget: (LKDeclRef referenceWithSymbol: 'charValue').
		gteFirst := LKMessageSend messageWithSelectorName: 'isGreaterThanOrEqualTo:'
			                                   arguments:
		  { LKNumberLiteral literalFromString: ((first characterAtIndex: 0) stringValue) }.
		gteFirst setTarget: (LKDeclRef referenceWithSymbol: 'charValue').
		predicate := LKMessageSend messageWithSelectorName: 'and:'
                                                 arguments: { lteLast }.
		predicate setTarget: gteFirst.
		matchIf := LKIfStatement ifStatementWithCondition: predicate
		  then: { self genMatchOfLength: (LKNumberLiteral literalFromString: '1') }
		  else: { self getFailureWithDescription: ('Expected character [', first, '-', last, ']') cause: nil }.
		block := LKBlockExpr blockWithArguments: {} locals: { 'charValue' } statements: {charAssign . matchIf }.
		blockInvoke := LKMessageSend messageWithSelectorName: 'value'.
		blockInvoke setTarget: block.
		^self ifAtEndThenFailElse: { blockInvoke }
	]

	makeExpression:exp modifier: modifier bind: name predicate: predicate [
		| suffixExp  lit temp msg |
		ETTranscript show: 'makeExpression:modifier:bind:predicate:'; cr.
		"TODO do the make Predicate stuff"
		suffixExp :=  modifier = '' ifTrue: [exp] ifFalse: [ 
			modifier value: exp ] .
		ETTranscript show: 'SuffixExp: '; show: suffixExp; cr.
		name = '' ifFalse: [
			temp := self genTemp.
			methodStatements addObject: (LKAssignExpr assignWithTarget: temp expr: suffixExp).
			lit := LKLiteral literalFromString: name.
			msg := LKMessageSend messageWithSelectorName: 'bind:'
										arguments: {lit}.
			msg setTarget: temp.
			suffixExp := msg.
		].
		^suffixExp
	]

	makeNullarySelector: sel [
		ETTranscript show: 'makeNullarySelector:'; cr.
		^sel selValue
	]

	makeKeywordMessagePart: keyword argument: arg [
		ETTranscript show: 'makeKeywordMessagePart:'; cr.
		^NSDictionary dictionaryWithObjects: { keyword componentsJoinedByString: ''. arg }
		                            forKeys: { 'selectorPart'. 'argumentName' }
	]

	makeSelectorAndArguments: components [
		| selector args |
		ETTranscript show: 'makeSelectorAndArguments:'; cr.
		selector := ''.
		args := NSMutableArray new.
		(components isKindOfClass: NSArray class) ifFalse: [ components := { components } ].
		components do: [ :each |
			selector := selector, (each objectForKey: 'selectorPart').
			args addObject: (each objectForKey: 'argumentName').
		].
		^ NSDictionary dictionaryWithObjects: { selector. args }
		                             forKeys: { 'selector'. 'arguments' }
	]

	makeAction: invokation [
		| pkParseAction messageAlloc messageInit arguments |
		ETTranscript show: 'makeAction:'; cr.
		(invokation isKindOfClass: NSDictionary class) ifTrue: [
			arguments := NSMutableArray new.
			pkParseAction := LKSymbolRef referenceWithSymbol: 'PKParseAction'.
			messageAlloc := LKMessageSend messageWithSelectorName: 'alloc'.
			messageAlloc setTarget: pkParseAction.

			"Should be Fix with selValue message send"
			arguments addObject: (LKLiteral  literalFromString: (invokation objectForKey: 'selector')).
			arguments addObject: (LKArrayExpr arrayWithElements: (invokation objectForKey: 'arguments')).
			messageInit := LKMessageSend messageWithSelectorName: 'initWithSelector:argumentNames:'
					arguments:(NSArray arrayWithArray: arguments).
			messageInit setTarget: messageAlloc.
			messageInit
		] ifFalse: [
			arguments := NSMutableArray new.
			pkParseAction := LKSymbolRef referenceWithSymbol: 'PKParseAction'.
			messageAlloc := LKMessageSend messageWithSelectorName: 'alloc'.
			messageAlloc setTarget: pkParseAction.
			arguments addObject: (LKLiteral literalFromString: invokation).
			arguments addObject: LKNilRef builtin.
			messageInit := LKMessageSend messageWithSelectorName: 'initWithSelector:argumentNames:'
					arguments:(NSArray arrayWithArray: arguments).
			messageInit setTarget: messageAlloc.
			messageInit 
		].
		^messageInit
	]

	makeRestriction: binding [
		| pkRestriction messageAlloc messageInit |
		ETTranscript show: 'makeRestriction:'; cr.
		pkRestriction := LKSymbolRef referenceWithSymbol: 'PKParseRestriction'.
		messageAlloc := LKMessageSend messageWithSelectorName: 'alloc'.
		messageAlloc setTarget: pkRestriction.

		"Should be Fix with selValue message send"
		messageInit := LKMessageSend messageWithSelectorName: 'initWithBinding:'
				arguments: { LKLiteral literalFromString: binding }.
		messageInit setTarget: messageAlloc.
		^messageInit
	]

	makeSequenceExpression: exp actionOrRestriction: action [
		| expression |
		ETTranscript show: 'makeSequenceExpression:actionOrRestriction:';cr.
		expression := (exp isKindOfClass: NSArray class) ifTrue: [
			exp leftFoldWithInitialValue: nil
				intoBlock: [:acc :exp | 
					acc == nil ifTrue: [exp]
						ifFalse: [self genSeq: acc alternate: exp]
				]
		]
			ifFalse: [ expression := exp].
		ETTranscript show: 'Expression after left fold: '; show: expression; cr.
		action = '' ifFalse: [
			| actionTemp actionExpr expressionValue expressionTemp |
			actionTemp := self genTemp.
			methodStatements addObject: (LKAssignExpr assignWithTarget: actionTemp
				expr: action).
			expressionTemp :=  self genTemp.
			methodStatements addObject: (LKAssignExpr assignWithTarget: expressionTemp expr: expression).
			expression := expressionTemp.
			expressionValue := LKMessageSend messageWithSelectorName: 'attachAction:' arguments:  { actionTemp}.
			expressionValue setTarget: expression.
			methodStatements addObject: expressionValue.
		].
		^expression
	]


	makePrefix: prefix exp: exp [
		| return temp test pop emptyMatch |
		ETTranscript show: 'makePrefix:..ex: ', exp description; cr.
		prefix = '!' ifTrue: [
			temp := self genTemp.
			methodStatements addObject: (LKAssignExpr assignWithTarget: temp expr: exp).
			test := LKMessageSend messageWithSelectorName: 'isFailure' arguments: {}.
			test setTarget: temp.
			pop := LKMessageSend messageWithSelectorName: 'popPosition'.
			pop setTarget: inputStreamDeclaration.
			methodStatements addObject: (LKIfStatement ifStatementWithCondition: test then: {temp} else: {pop}).
			return := temp.
		].
		prefix = '&' ifTrue: [
			temp := self genTemp.
			methodStatements addObject: (LKAssignExpr assignWithTarget: temp expr: exp).
			test := LKMessageSend messageWithSelectorName: 'isFailure' arguments: {}.
			test setTarget: temp.
			pop := LKMessageSend messageWithSelectorName: 'popPosition'.
			pop setTarget: inputStreamDeclaration.
			emptyMatch := LKMessageSend messageWithSelectorName: 'emptyMatch:' arguments: {inputStreamDeclaration}.
			emptyMatch setTarget: (LKSymbolRef referenceWithSymbol: 'PKParseMatch').
			return := LKIfStatement ifStatementWithCondition: test 
				then: { emptyMatch } 
				else: {
					pop. 
					self genFailDescription: (LKLiteral literalFromString: 'Expression is not expected')} 
		].
		return == nil ifTrue: [return := exp].
		ETTranscript show: 'MakePrefix return: '; show: return; cr.
		^return
	]

	join: list [
		| exp |
		ETTranscript show: 'join: '; show: list ; cr.
		exp := nil.
		"Need to fix how sequenceWith is working"
		(list respondsToSelector: #do: )  ifTrue: [
			list do: [:each | 
				exp = nil ifTrue: [exp := each] ifFalse: [exp := self genOr: exp alternate: each]
			]
		] ifFalse: [ exp :=  list ].
		^exp
	]
]
