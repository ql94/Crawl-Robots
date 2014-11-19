#!/usr/local/bin ruby
require 'mechanize'
require './HTMLNodeParser.rb'
require './NewsObject.rb'

main_thread = Mechanize.new
minion_thread = Mechanize.new
news_index = main_thread.get('http://cwc.hit.edu.cn/news/main.asp?cataid=A0001&keyword=&pageno=1')
news_index.encoding = 'gb2312'
base_url = 'http://cwc.hit.edu.cn/news/'
# Incrementally update
should_stop = false
stop_index = 0
stop_link = nil
filePath = 'cwc.hit.edu.cn/news/last_update.json'
if File.exist?filePath
	file = File.read(filePath, :encoding => 'UTF-8')
	last_update = JSON.parse(file)
else
	last_update = {}
end
while !should_stop do
	table = news_index.search('/html/body/table[4]/tr/td[2]/table/tr[2]/td/table').search('tr/td/table[1]/tr') # use XPath query to get news_links
	table.each do |cell|
		news_title = cell.search('td[2]//a')[0].text.strip
		news_link = base_url + cell.search('td[2]//a')[0]['href']
		news_date = cell.search('td[2]//a')[1]['title']
		if stop_link == nil
			stop_link = news_link
		end
		if last_update["link"] != nil && news_link == last_update["link"]
			should_stop = 1
			break
		end
		news_page = minion_thread.get(news_link);
		news_page.encoding = 'gb2312'
		doc = Nokogiri::HTML(news_page.body, nil, 'gb2312')
		parser = ACHTMLNodeParser.new(doc.xpath('//*[@id="zoom"]'), base_url)
		parser.parse
		news_date = news_date + ' ' + DateTime.now.to_time.to_s.split(' ')[1]
		if news_date[5]!=1 
			news_date = news_date[0..4]+'0'+news_date[5..-1];
		end
		if news_date[8]!=1 
			news_date = news_date[0..7]+'0'+news_date[8..-1];
		end
		
		obj = {
			"title" => news_title,
			"link" => news_link,
			"date" => news_date,
			"content" => parser.string,
			"imgs" => parser.imgs
		}
		news = NewsObject.new(HNDepart::CWC, HNType::NEWS, obj)
		news.save
		stop_index += 1
	end
	if link = news_index.link_with(:text => '下一页')
		news_index = link.click
		news_index.encoding = 'gb2312'
	else
		break
	end
end
last_update = {
	"date" => DateTime.now.to_time.to_s[0..-7],
	"link" => stop_link,
	"count" => stop_index
}
File.open(filePath, 'w:UTF-8') { |file|
	string = JSON.pretty_generate(last_update)
	file.write(string)
}
