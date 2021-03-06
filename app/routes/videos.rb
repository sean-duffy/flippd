require 'open-uri'
require 'json'
require 'sinatra/base'
require './app/helpers/badge_utils'
require './app/helpers/general_utils'
require './app/helpers/video_utils'
require './app/helpers/comment_utils'

class Flippd < Sinatra::Application
	helpers BadgeUtils, GeneralUtils, VideoUtils, CommentUtils

    get '/videos/:pos' do
        pos = params["pos"].to_i

        # Set the current video
        @phases.each do |phase|
            phase['topics'].each do |topic|
                topic['videos'].each do |video|
                      if video["pos"] == pos
                        @phase = phase
                        @video = video
                      end
                end
              end
        end

        @previous, @next = get_previous_and_next_page_links(@phases, pos)

        # Check if a user is logged in
        user_id = get_user_id(session)
        if is_user_logged_in(user_id)
            @video_watched = is_video_watched(user_id, @video["id"])
        else
            @video_watched = false
        end

    	# Load the comments for this video
		@comment_voting_on = CommentUtils.is_comment_voting_on(@settings)
		@comments = CommentUtils.get_comments(@video["id"], @comment_voting_on)

		@replies = Array.new
		@vote_states = Array.new
		@comments.each do |comment|
			existing_vote = CommentUtils.get_existing_vote(comment["id"], @user)
			if existing_vote 
				@vote_states[comment["id"]] = existing_vote.is_upvote
			end

    		if @settings["replies_on"] == "true"
    			@replies[comment["id"]] = CommentUtils.get_replies(@video["id"], @comment_voting_on, comment["id"])

        		@replies[comment["id"]].each do |reply|
					existing_vote = CommentUtils.get_existing_vote(reply["id"], @user)
					if existing_vote
						@vote_states[reply["id"]] = existing_vote.is_upvote
					end
        		end
	  		else
				@replies[comment["id"]] = []
     		end

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

            awards = BadgeUtils.trigger_badges(user_id, video_id, @badges, @teams)
            if !awards.empty?
                awards.each do |award|
                    if !award["team"]
                        display_notification("#{award["id"]}", "You earned a new badge!", "Well done, you just earned the '#{award["title"]}' badge")
                    else
                        display_notification("#{award["id"]}-team", "Your team earned a badge!", "Well done, everyone on your team has earned the '#{award["title"]}' team badge")
                    end
                end
            end
        end
        # Output something so that the AJAX knows we are done
        "done"
    end

end
