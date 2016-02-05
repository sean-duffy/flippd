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
		@phases.each do |phase|
			phase['topics'].each do |topic|
				topic['quizzes'].each do |quiz|
					#Set the current quiz
    				if quiz["pos"] == pos
						@phase = phase
						@quiz = quiz
					end
				end
      		end
    	end

		# Get the next and previous video/quiz to link to
		@previous = get_by_pos(@phases, pos-1)
		@next = get_by_pos(@phases, pos+1)

		pass unless @quiz
		erb :quiz
	end

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
		if user_id != nil
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

end
