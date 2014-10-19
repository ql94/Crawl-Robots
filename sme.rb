#!/usr/bin/env ruby

require 'mechanize'
require 'Nokogiri'
require 'JSON'
require './HTMLNodeParser.rb'
require './NewsObject.rb'

# 学院新闻 http://sme.hit.edu.cn/news/main.asp?cataid=A00010003
# 学院公告 http://sme.hit.edu.cn/news/main.asp?cataid=A00010004
# Encoding: GB2312

main_thread = Mechanize.new
minion_thread = Mechanize.new

sme = {
	"news" => 'http://sme.hit.edu.cn/news/main.asp?cataid=A00010003',
	"announcement" => 'http://sme.hit.edu.cn/news/main.asp?cataid=A00010004'
}

base_url = 'http://sme.hit.edu.cn/news/'

filePath = 'sme.hit.edu.cn/last_update.json'
if File.exist?filePath
	file = File.read(filePath, :encoding => 'UTF-8')
	last_update = JSON.parse(file)
else
	last_update = {}
end

sme.each do |type, link|
	index = main_thread.get(link)
	index.encoding = 'gb2312'

	# Incrementally update
	should_stop = false
	stop_index = 0
	stop_link = nil

	while !should_stop do
		table = index.search('//*[@id="container"]/table/tr/td[2]/table/tr[2]/td/table/tr/td/table[1]/tr') # use XPath query to get links

		table.each do |cell|
			title = cell.search('td[2]//a')[0].text.strip
			#puts title
			link = base_url + cell.search('td[2]//a')[0]['href']
			#puts link
			date = cell.search('td[2]//a')[1]['title']
			#puts date
			# Debug
			#next

			if last_update != nil && last_update[type]["link"] != nil && link == last_update[type]["link"]
				should_stop = 1
				stop_link = link
				break
			end

			detail_page = minion_thread.get(link);
			detail_page.encoding = 'gb2312'

			doc = Nokogiri::HTML(detail_page.body, nil, 'gb2312')

			parser = ACHTMLNodeParser.new(doc.xpath('//*[@id="container"]/table/tr/td[2]/table/tr[2]/td/table/tr[2]'), base_url)
			parser.parse

			date = date.gsub('/', '-') # + ' ' + DateTime.now.to_time.to_s.split(' ')[1]

			obj = {
				"title" => title,
				"link" => link,
				"date" => date,
				"content" => parser.string,
				"imgs" => parser.imgs
			}
			case type
			when "news"
				news = NewsObject.new(HNDepart::SME, HNType::NEWS, obj)
			else "announcement"
				news = NewsObject.new(HNDepart::SME, HNType::ANNOUNCEMENT, obj)
			end
			news.save

			stop_index += 1
		end

		if link = index.link_with(:text => '下一页')
			index = link.click
			index.encoding = 'gb2312'
		else
			break
		end
	end

	last_update[type] = {
		"date" => DateTime.now.to_time.to_s[0..-7],
		"link" => stop_link,
		"count" => stop_index
	}
end

File.open(filePath, 'w:UTF-8') { |file|
	string = JSON.pretty_generate(last_update)
	file.write(string)
}