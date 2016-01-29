class StaticsController < ApplicationController
	def index
		binding.pry
	end

	def check_if_signed_in
    authenticate_user!
    redirect_to "/chatroom/index?#{current_user.id.to_s}"
	end
end