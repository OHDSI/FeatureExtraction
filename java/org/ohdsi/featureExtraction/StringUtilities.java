package org.ohdsi.featureExtraction;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

public class StringUtilities {

	// private static String[] UPPER_CASE_LETTERS = new String[]{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S',
	// 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};

	public static String join(Collection<?> s, String delimiter) {
		StringBuffer buffer = new StringBuffer();
		Iterator<?> iter = s.iterator();
		if (iter.hasNext()) {
			buffer.append(iter.next().toString());
		}
		while (iter.hasNext()) {
			buffer.append(delimiter);
			buffer.append(iter.next().toString());
		}
		return buffer.toString();
	}

	public static String join(Object[] objects, String delimiter) {
		StringBuffer buffer = new StringBuffer();
		if (objects.length != 0)
			buffer.append(objects[0].toString());
		for (int i = 1; i < objects.length; i++) {
			buffer.append(delimiter);
			buffer.append(objects[i].toString());
		}
		return buffer.toString();
	}

	public static List<String> safeSplit(String string, char delimiter) {
		List<String> result = new ArrayList<String>();
		if (string.length() == 0) {
			result.add("");
			return result;
		}
		boolean literal = false;
		boolean escape = false;
		int startpos = 0;
		int i = 0;
		char currentchar;
		while (i < string.length()) {
			currentchar = string.charAt(i);
			if (currentchar == '"' && !escape) {
				literal = !literal;
			}
			if (!literal && (currentchar == delimiter && !escape)) {
				result.add(string.substring(startpos, i));
				startpos = i + 1;
			}
			if (currentchar == '\\') {
				escape = !escape;
			} else {
				escape = false;
			}
			i++;
		}
		result.add(string.substring(startpos, i));
		return result;
	}

	public static String camelCaseToSnakeCase(String string) {
		StringBuilder result = new StringBuilder();
		int start = 0;
		for (int i = 0; i < string.length(); i++) {
			int charInt = (int) string.charAt(i);
			if (charInt < 91 && charInt > 64) {
				result.append(string.substring(start, i) + "_" + string.substring(i, i + 1).toLowerCase());
				start = i + 1;
			}
		}
		if (start < string.length())
			result.append(string.substring(start));
		return result.toString();
	}
}
