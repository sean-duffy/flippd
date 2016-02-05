require 'open-uri'
require 'json'
require 'sinatra/base'
require './app/helpers/badge_utils'
require './app/helpers/phase_utils'
require './app/helpers/general_utils'

class Flippd < Sinatra::Application
	helpers BadgeUtils, PhaseUtils, GeneralUtils

	get '/videos/:pos' do
		pos = params["pos"].to_i
    	@phases.each do |phase|
		    phase['topics'].each do |topic|
				topic['videos'].each do |video|
          			# Set the current video
          			if video["pos"] == pos
            			@phase = phase
            			@video = video
          			end
        		end
      		end
    	end

		# Get the next and previous video/quiz to link to
		@previous = get_by_pos(@phases, pos-1)
		@next = get_by_pos(@phases, pos+1)
		
		# Mark this video as unwatched - we will correct this if necessary
		@video_watched = false
		
		# Check if a user is logged in
        user_id = get_user_id(session)
		if user_id != nil	  		
	  		# If a user is logged in we will check if they have watched this video before
	  		matches = VideosWatched.first(:user_id => user_id, :json_id => @video["id"])
		    if matches != nil
		    	@video_watched = true
		    end
		end

		pass unless @video
		erb :video
	end

	post '/videos/:id' do
	  	video_id = params["id"]
	  	badges_earnt = 0

	  	# Check that the user is logged in
		user_id = get_user_id(session)
		if user_id != nil
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
