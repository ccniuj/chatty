require 'rufus-scheduler'

namespace :robot do
	desc "test"
	task test: :environment do
		scheduler = Rufus::Scheduler.new
    scheduler.every '5s' do
      puts 'test'
    end
    scheduler.join
	end
end