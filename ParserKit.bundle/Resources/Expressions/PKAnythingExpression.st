"
Interpret a success pase expression.
"
PKParseExpression subclass: PKAnythingExpression [
	| +instance |

	+initialize [
		instance := self new.
	]

	+uniqueInstance [
		^instance
	]

	parseInput: list  withCurrentParser: parser delegate: delegate [ ^PKParseMatch emptyMatch: list]

	description [ ^'']
]

