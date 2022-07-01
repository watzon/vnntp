module main

import vnntp

fn main() {
	mut nntp_stream := vnntp.connect("nntp.aioe.org:119")?

	caps := nntp_stream.capabilities()?
	println('CAPABILITIES:\n${caps.join('')}')

	groups := nntp_stream.list()?
	println('GROUPS:')
	for group in groups {
		println('Name: ${group.name}, High: ${group.high}, Low: ${group.low}, Status: ${group.status}')
	}

	// Select a group
	nntp_stream.group('comp.sys.raspberry-pi')?

	news := nntp_stream.newnews('comp.sys.raspberry-pi', '20220622', '000000', true)?

	// Get an article by number
	article := nntp_stream.article_by_id(news[news.len - 1])?
	for key, value in article.headers {
		println('${key}: ${value}')
	}
	if article.body.len > 0 {
		println('Body: ${article.body.join('')}')
	}
}
