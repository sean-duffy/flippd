require 'open-uri'
require 'json'
require 'sinatra/base'
require './app/helpers/badge_utils'
require './app/helpers/phase_utils'
require './app/helpers/general_utils'
require './app/helpers/video_utils'

class Flippd < Sinatra::Application
	helpers BadgeUtils, PhaseUtils, GeneralUtils, VideoUtils

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

		# Check if a user is logged in
        user_id = get_user_id(session)
		if is_user_logged_in(user_id)
			@video_watched = is_video_watched(user_id, @video["id"])
		else 
			@video_watched = false
		end

		pass unless @video
		erb :video
	end

	post '/videos/:id' do
	  	video_id = params["id"]
	  	badges_earnt = 0

		user_id = get_user_id(session)
		if is_user_logged_in(user_id)
		    user = User.get(user_id)

	  		# Adds database entry marking the video as watched (if it isn't already)
		    if !is_video_watched(user_id, video_id)
		    	VideosWatched.create(:json_id => video_id, :date => Time.now, :user => user)
		    end

	  		if BadgeUtils.is_any_trigger(video_id, @badges)
	  			potential_rewards = BadgeUtils.get_potential_triggered_badges(video_id, @badges)
	  			potential_rewards.each do |badge|
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
