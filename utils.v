module vnntp

pub fn trim_group(_str string, arr []string) string {
	mut str := _str
	for s in arr {
		str = str.trim(s)
	}
	return str
}

pub fn split_date(date_response string) (string, string) {
	return date_response[..8], date_response[8..]
}
