require 'rufus-scheduler'
require 'redis'

namespace :robot do
	desc "test"
	task fetch_weather: :environment do
		redis = Redis.new
		session = ObjectSpace.each_object(ActionDispatch::Integration::Session)
		scheduler = Rufus::Scheduler.new
    scheduler.every '15m' do
   		Crawler.fetch_weather
    end
    scheduler.join
	end
end