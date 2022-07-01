module vnntp

pub struct NewsGroup {
pub:
	name 	string
	high 	int
	low		int
	status 	string
}

pub fn new_news_group(group string) NewsGroup {
	chars_to_trim := ['\r', '\n', ' ']
	trimmed_group := trim_group(group, chars_to_trim)
	split_group := trimmed_group.split(' ')
	return NewsGroup {
		name: split_group[0],
		high: split_group[1].int(),
		low: split_group[2].int(),
		status: split_group[3]
	}
}
