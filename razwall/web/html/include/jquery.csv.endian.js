/**
 * csvToArray derives from:
 * http://www.bennadel.com/blog/1504-Ask-Ben-Parsing-CSV-Strings-With-Javascript-Exec-Regular-Expression-Command.htm
 */

(function($) {

	objPattern =  new RegExp((
			// Delimiters.
			"(\\,|\\r?\\n|\\r|^)" +	
			// Quoted fields.
			"(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +	
			// Standard fields.
			"([^\"\\,\\r\\n]*))"), "gi");
	escapedDoubleQuotePattern = new RegExp("\"\"", "g");

	/**
	 * Parse a CSV string into an array of arrays.
	 */
	$.csvToArray = function(strData) {
		if (strData.trim() == "")
			return []
		var arrData = [ [] ];
		var arrMatches = null;

		if (strData.charAt(0) == ",")
			arrData [arrData.length - 1].push ("")

		while (arrMatches = objPattern.exec(strData)) {		
			var strMatchedDelimiter = arrMatches[1];
			if (strMatchedDelimiter.length && (strMatchedDelimiter != ","))
				arrData.push([]);

			var strMatchedValue = null;
			if (arrMatches[2])
				strMatchedValue = arrMatches[2].replace(escapedDoubleQuotePattern, "\"");
			else
				strMatchedValue = arrMatches[3];
			arrData[arrData.length - 1].push(strMatchedValue);
		}

		return arrData;
	}

	/**
	 * Convert an array of arrays into a CSV string
	 */
	$.arrayToCsv = function(arrData) {
		var result = [];
		for (var i = 0; i < arrData.length; i++) {
			var line = [];
			for (var j = 0; j < arrData[i].length; j++) {
				var value = String(arrData[i][j]);
				if (value.indexOf("\"") != -1 || value.indexOf(",") != -1) {
					value = value.replace(/\"/g,'\"\"')
					value = "\"" + value + "\"";
				}
				line.push(value);
			}
			result.push(line.join(","));
		}
		result = result.join("\r\n");
		return result;
	}
	
})(jQuery);
