

NSObject subclass: PKParserAbstractGenerator [
	| delegate specialCharToChar |

	init [
		super init.
		specialCharToChar := NSMutableDictionary new.
		specialCharToChar setValue: '\n' forKey: 'n'.
		specialCharToChar setValue: '\t' forKey: 't'.
		specialCharToChar setValue: '\r' forKey: 'r'.
		specialCharToChar setValue: '\\' forKey: '\\'.
		specialCharToChar setValue: '''' forKey: ''''.
		specialCharToChar setValue: '"' forKey: '"'.
		specialCharToChar setValue: '[' forKey: '['.
		specialCharToChar setValue: ']' forKey: ']'.
		^self
	]

	setDelegate: aDelegate [
		delegate := aDelegate
	]	

	makeEmpty [^'']

	parseSpecialChar: char [
		^specialCharToChar objectForKey: char
	]

	parseHexChar: value [
		| scanner return |
		scanner := NSScanner scannerWithString: value.
		return := NSMutableString new.
		return appendCharacter: scanner hexIntegerValue.
		^return
	]

]
