module vnntp

import net

const (
	// carriage return
	cr  = u8(0x0d)
	// line feed
	lf  = u8(0x0a)
	// dot
	dot = u8(0x2e)
)

pub struct NntpsStream {
mut:
	stream &net.TcpConn
}

// Creates an NNTP Stream.
pub fn connect(addr string) ?NntpsStream {
	tcp_conn := net.dial_tcp(addr)?
	mut socket := NntpsStream { stream: tcp_conn }

	_, _ := socket.read_response(200) or {
		return error('failed to read greeting response')
	}

	return socket
}

// The article indicated by the current article number in the currently selected newsgroup is selected.
pub fn (mut stream NntpsStream) article() ?Article {
	return stream.retrieve_article('ARTICLE\r\n')
}

// The article indicated by the article id is selected.
pub fn (mut stream NntpsStream) article_by_id(id string) ?Article {
	return stream.retrieve_article('ARTICLE $id\r\n')
}

// The article indicated by the article number in the currently selected newsgroup is selected.
pub fn (mut stream NntpsStream) article_by_number(number int) ?Article {
	return stream.retrieve_article('ARTICLE $number\r\n')
}

fn (mut stream NntpsStream) retrieve_article(command string) ?Article {
	stream.stream.write_string(command) or {
		return error('failed to retrieve article')
	}

	stream.read_response(220)?

	res := stream.read_multiline_response()?
	return new_article(res)
}

// Retrieves the body of the current article number in the currently selected newsgroup.
pub fn (mut stream NntpsStream) body() ?[]string {
	return stream.retrieve_body('BODY\r\n')
}

// Retrieves the body of the article id.
pub fn (mut stream NntpsStream) body_by_id(id string) ?[]string {
	return stream.retrieve_body('BODY $id\r\n')
}

// Retrieves the body of the article number in the currently selected newsgroup.
pub fn (mut stream NntpsStream) body_by_number(number int) ?[]string {
	return stream.retrieve_body('BODY $number\r\n')
}

fn (mut stream NntpsStream) retrieve_body(command string) ?[]string {
	stream.stream.write_string(command)?

	stream.read_response(222)?

	return stream.read_multiline_response()
}

// Gives the list of capabilities that the server has.
pub fn (mut stream NntpsStream) capabilities() ?[]string {
	capabilities_command := 'CAPABILITIES\r\n'

	stream.stream.write_string(capabilities_command)?

	stream.read_response(101)?

	return stream.read_multiline_response()
}

// Retrieves the date as the server sees the date.
pub fn (mut stream NntpsStream) date() ?string {
	date_command := 'DATE\r\n'

	stream.stream.write_string(date_command)?

	_, msg := stream.read_response(111)?
	return msg
}

// Retrieves the headers of the current article number in the currently selected newsgroup.
pub fn (mut stream NntpsStream) head() ?[]string {
	return stream.retrieve_head('HEAD\r\n')
}

// Retrieves the headers of the article id.
pub fn (mut stream NntpsStream) head_by_id(id string) ?[]string {
	return stream.retrieve_head('HEAD $id\r\n')
}

// Retrieves the headers of the article number in the currently selected newsgroup.
pub fn (mut stream NntpsStream) head_by_number(number int) ?[]string {
	return stream.retrieve_head('HEAD $number\r\n')
}

fn (mut stream NntpsStream) retrieve_head(command string) ?[]string {
	stream.stream.write_string(command)?

	stream.read_response(221)?

	return stream.read_multiline_response()
}

// Moves the currently selected article number back one
pub fn (mut stream NntpsStream) last() ?string {
	last_command := 'LAST\r\n'

	stream.stream.write_string(last_command)?

	_, msg := stream.read_response(223)?
	return msg
}

// Lists all of the newgroups on the server.
pub fn (mut stream NntpsStream) list() ?[]NewsGroup {
	list_command := 'LIST\r\n'

	stream.stream.write_string(list_command)?

	stream.read_response(215)?

	lines := stream.read_multiline_response()?
	return lines.map(new_news_group(it))
}

// Selects a newsgroup
pub fn (mut stream NntpsStream) group(group string) ? {
	group_command := 'GROUP $group\r\n'

	stream.stream.write_string(group_command)?

	stream.read_response(211)?
}

// Show the help command given on the server.
pub fn (mut stream NntpsStream) help() ?[]string {
	help_command := 'HELP\r\n'

	stream.stream.write_string(help_command)?

	stream.read_response(100)?

	return stream.read_multiline_response()
}

// Quits the current session.
pub fn (mut stream NntpsStream) quit() ? {
	quit_command := 'QUIT\r\n'

	stream.stream.write_string(quit_command)?

	stream.read_response(205)?
}

// Retrieves a list of newsgroups since the date and time given.
pub fn (mut stream NntpsStream) newgroups(date string, time string, use_gmt bool) ?[]string {
	newgroups_command := match use_gmt {
		true  { 'NEWSGROUP $date $time GMT\r\n' }
		false { 'NEWSGROUP $date $time\r\n' }
	}

	stream.stream.write_string(newgroups_command)?

	stream.read_response(231)?

	return stream.read_multiline_response()
}

// Retrieves a list of new news since the date and time given.
pub fn (mut stream NntpsStream) newnews(wildmat string, date string, time string, use_gmt bool) ?[]string {
	newnews_command := match use_gmt {
		true  { 'NEWNEWS $wildmat $date $time GMT\r\n' }
		false { 'NEWNEWS $wildmat $date $time\r\n' }
	}

	stream.stream.write_string(newnews_command)?

	stream.read_response(230)?

	return stream.read_multiline_response()
}

// Moves the currently selected article number forward one
pub fn (mut stream NntpsStream) next() ?string {
	next_command := 'NEXT\r\n'

	stream.stream.write_string(next_command)?

	_, msg := stream.read_response(223)?
	return msg
}

// Posts a message to the NNTP server.
pub fn (mut stream NntpsStream) post(message string) ? {
	if !stream.is_valid_message(message) {
		return error('Invalid message format. Message must end with "\\r\\n.\\r\\n\"')
	}

	post_command := 'POST\r\n'

	stream.stream.write_string(post_command)?

	stream.read_response(340)?

	stream.stream.write_string(message)?

	stream.read_response(240)?
}

// Gets information about the current article.
pub fn (mut stream NntpsStream) stat() ?string {
	return stream.retrieve_stat('STAT\r\n')
}

// Gets the information about the article id.
pub fn (mut stream NntpsStream) stat_by_id(id string) ?string {
	return stream.retrieve_stat('STAT $id\r\n')
}

// Gets the information about the article number.
pub fn (mut stream NntpsStream) stat_by_number(number int) ?string {
	return stream.retrieve_stat('STAT $number\r\n')
}

fn (mut stream NntpsStream) retrieve_stat(command string) ?string {
	stream.stream.write_string(command) or {
		return error('write error')
	}

	_, msg := stream.read_response(223)?
	return msg
}

fn (mut stream NntpsStream) is_valid_message(message string) bool {
	message_bytes := message.bytes()
	length := message.len

	return length >= 5 && message_bytes[length - 1] == lf && message_bytes[length - 2] == cr &&
		message_bytes[length - 3] == dot && message_bytes[length - 4] == lf && message_bytes[length - 5] == cr
}

// Retrieve single line response
fn (mut stream NntpsStream) read_response(expected_code int) ?(int, string) {
	mut line_buffer := []string{}

	for line_buffer.len < 2 {
		line := stream.stream.read_line()
		line_buffer << line
		if line[line.len - 1] == lf && line[line.len - 2] == cr {
			break
		}
	}

	response := line_buffer.join('')
	chars_to_trim := ['\r', '\n']
	trimmed_response := trim_group(response, chars_to_trim)
	if trimmed_response.len < 5 || trimmed_response.substr(3, 4) != ' ' {
		return error('invalid response')
	}

	v := trimmed_response.split_nth(' ', 2)
	code := v[0].int()
	message := v[1]
	if code != expected_code {
		return error('invalid response; $code $message')
	}

	return code, message
}

fn (mut stream NntpsStream) read_multiline_response() ?[]string {
	mut response := []string{}
	mut line_buffer := []string{}
	mut complete := false

	for !complete {
		for line_buffer.len < 2 {
			line := stream.stream.read_line()
			line_buffer << line
			if line[line.len - 1] == lf && line[line.len - 2] == cr {
				break
			}
		}

		res := line_buffer.join('')
		if res == '.\r\n' {
			complete = true
		} else {
			response << res
			line_buffer.clear()
		}
	}

	return response
}
