module vnntp

pub struct Article {
pub:
	headers map[string]string
	body    []string
}

pub fn new_article(lines []string) Article {
	mut headers := map[string]string{}
	mut body := []string{}
	mut parsing_headers := true
	mut last_header := ''

	for line in lines {
		if line == '\r\n' {
			parsing_headers = false
			continue
		}
		if parsing_headers {
			mut header := line.split_nth(':', 2)
			if header.len == 1 {
				headers[last_header] += header[0]
				continue
			}

			chars_to_trim := ['\r', '\n']
			key   := trim_group(header[0], chars_to_trim)
			value := trim_group(header[1], chars_to_trim)
			headers[key] = value
			last_header = key
		} else {
			body << line
		}
	}

	return Article { headers: headers, body: body }
}
