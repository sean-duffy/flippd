require 'open-uri'
require 'json'
require 'sinatra/base'
require './app/helpers/badge_utils'
require './app/helpers/phase_utils'
require './app/helpers/general_utils'

class Flippd < Sinatra::Application
    helpers BadgeUtils, PhaseUtils, GeneralUtils

	get '/quizzes/:pos' do
		pos = params["pos"].to_i

		#Set the current quiz
		@phases.each do |phase|
			phase['topics'].each do |topic|
				topic['quizzes'].each do |quiz|
    				if quiz["pos"] == pos
						@phase = phase
						@quiz = quiz
					end
				end
      		end
    	end

		@previous, @next = get_previous_and_next_page_links(@phases, pos)

		pass unless @quiz
		erb :quiz
	end

	post '/quizzes/:pos' do
		pos = params["pos"].to_i
		@post  = params[:post]
		#if @post = nil
		#	@post = {}
		#end
		@quiz  = get_by_pos(@phases, pos)

		@previous, @next = get_previous_and_next_page_links(@phases, pos)

		@score = 0

        if @post
    		@post.each do |question_no, answer|
    		    if @quiz["questions"][question_no.to_i]["correct answer"] == answer
    		        @score += 1
    		    end
    		end
        end
        @passed = false
        if @score >= @quiz["pass"]
            @passed = true
        end

		user_id = get_user_id(session)
		if is_user_logged_in(user_id)
			user = User.get(user_id)
			result = QuizResult.create(:json_id => @quiz["id"], :date => Time.now, :mark => @score, :user => user, :pass => @passed)
            awards = BadgeUtils.trigger_badges(user_id, @quiz["id"], @badges, @teams)
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

    	erb :quiz_result
	end

end
