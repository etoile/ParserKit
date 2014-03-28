
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


