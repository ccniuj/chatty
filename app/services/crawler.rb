require 'nokogiri'
require 'open-uri'
require 'redis'

class Crawler
	def self.fetch_weather
		redis = Redis.new
		cwb_url = 'http://www.cwb.gov.tw/V7/observe/24real/Data/46692.htm'
		doc = Nokogiri::HTML(open(cwb_url))
		headers = doc.css('tr').first.children.map{|h|h.text}
		data = doc.css('tr')[1].children.map{|h|h.text}

		redis.set("temperature", data[1]+'°C')
  	redis.set("weather", ((data[3]=='X') ? '' : data[3]))
	  redis.set("humidity", data[8]+'%')

	  p "Time: #{Time.now}"
		p "Temperature: #{redis.get('temperature')}"
  	p "Weather: #{redis.get('weather')}"
	  p "Humidity: #{redis.get('humidity')}"
	end
end