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
		@phase = @phases.first # FIXME
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

		user_id = get_user_id(session)
		if is_user_logged_in(user_id)
			user = User.get(user_id)
			result = QuizResult.create(:json_id => @quiz["id"], :date => Time.now, :mark => @score, :user => user)

			potential_rewards = BadgeUtils.get_potential_triggered_badges(@quiz["id"], @badges)
			potential_rewards.each do |badge|
			    if BadgeUtils.are_requirements_met(user_id, badge)
			        BadgeUtils.award_badge(badge, user)
					display_notification("#{badge["id"]}", "You earned a new badge!", "Well done, you just earned the '#{badge["title"]}' badge")
			    end
			end
		end

    	erb :quiz_result
	end

end
