PKComposeExpression subclass: PKAlphanumericExpression [

	init [
		self initWithExp: (  PKAlphabeticExpression new or: PKNumericExpression new )
	]
	
	description [^'[[:alnum:]]']
]


