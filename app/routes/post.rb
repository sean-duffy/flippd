require 'open-uri'
require 'json'
require 'sinatra/base'
require './app/helpers/badge_utils'
require './app/helpers/phase_utils'
require './app/helpers/general_utils'

class Flippd < Sinatra::Application
	helpers BadgeUtils, PhaseUtils, GeneralUtils

	post '/quizzes/:pos' do
		pos = params["pos"].to_i
		@phase = @phases.first # FIXME
		@post  = params[:post]
		@quiz  = get_by_pos(@phases, pos)

		# Get the next and previous video/quiz to link to
		@previous = get_by_pos(@phases, pos-1)
		@next = get_by_pos(@phases, pos+1)

		@score = 0
		@post.each do |question_no, answer|
		    if @quiz["questions"][question_no.to_i]["correct answer"] == answer
		        @score += 1
		    end
		end
		
		user_id = get_user_id(session)
		if user_id == nil
		    user = User.get(user_id)
		    result = QuizResult.create(:json_id => @quiz["id"], :date => Time.now, :mark => @score, :user => user)
		    rewards = BadgeUtils.get_triggered_badges(@quiz["id"], @badges)
		    rewards.each do |badge|
		        if BadgeUtils.check_requirements(user_id, badge)
		            BadgeUtils.award_badge(badge, user)

					display_notification("#{badge["id"]}", "You earned a new badge!", "Well done, you just earned the '#{badge["title"]}' badge")
		        end
		    end
		end

    	erb :quiz_result
	end

	post '/videos/:id' do
	  	video_id = params["id"]
	  	badges_earnt = 0

	  	# Check that the user is logged in
		user_id = get_user_id(session)
		if user_id == nil
		    user = User.get(user_id)

	  		# Mark the video as watched in the database (if it isn't already)
	  		matches = VideosWatched.first(:user_id => user_id, :json_id => video_id)
		    if matches == nil
		    	VideosWatched.create(:json_id => video_id, :date => Time.now, :user => user)
		    end

	  		# Check if video is a trigger for any badges
	  		if BadgeUtils.is_any_trigger(video_id, @badges)
	  			# Get all of the rewards for this video
	  			rewards = BadgeUtils.get_triggered_badges(video_id, @badges)
	  			# Loop through rewards, and if requirements are met then assign badge
	  			rewards.each do |badge|
		        	if BadgeUtils.check_requirements(user_id, badge)
		            	BadgeUtils.award_badge(badge, user)
		            	badges_earnt += 1
					
						display_notification("#{badge["id"]}", "You earned a new badge!", "Well done, you just earned the '#{badge["title"]}' badge")
		        	end
		        end
		    end
	  	end

	  	# Return a count of how many badges we have awarded
	  	badges_earnt.to_s
	end
end
