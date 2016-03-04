require 'open-uri'
require 'json'
require 'sinatra/base'
require './app/helpers/badge_utils'
require './app/helpers/phase_utils'

class Flippd < Sinatra::Application
  helpers BadgeUtils, PhaseUtils

	post '/post_comment/:id' do
		video_id = params["id"]
    	body = params[:body]

    	if session.has_key?("user_id")
      		@user = User.get(session['user_id'])

      		if params[:replyID]
        		Comment.create(:body => body, :json_id => video_id, :created => DateTime.now, :user => @user, :reply_to => params[:replyID])
      		else
        		Comment.create(:body => body, :json_id => video_id, :created => DateTime.now, :user => @user)
      		end

      		origin = env["HTTP_REFERER"] || '/'
      		redirect to(origin)
    	else
      		status 500
      		return "Error: User not logged in."
    	end
	end

	post '/remove_comment/:id' do
    	comment_id = params["id"]

    	if session.has_key?("user_id")
      		user = User.get(session['user_id'])
      		comment = Comment.first(:id => comment_id.to_i, :user => user)

      		if comment
        		comment.destroy
        		origin = env["HTTP_REFERER"] || '/'
        		redirect to(origin)
      		else
        		status 500
        		return "Error: You can only remove your own comments."
      		end

    	else
      		status 500
      		return "Error: User not logged in."
    	end
	end

	post '/upvote_comment/:id' do
	  	comment_id = params["id"]

    	if session.has_key?("user_id")
     		user = User.get(session['user_id'])
      		comment = Comment.first(:id => comment_id.to_i)

      		existing_vote = Vote.first(:comment_id => comment_id.to_i, :user =>user)
      		if existing_vote

        		if existing_vote.is_upvote
          			# If the user has already upvoted, undo the vote
          			existing_vote.destroy
          			comment.points -= 1
        		else
          			# If the user has downvoted, change to an upvote
          			existing_vote.is_upvote = true
          			existing_vote.save
	          		comment.points += 2
      			end

			else
				Vote.create(:comment_id => comment_id.to_i, :is_upvote => true, :user => user)
    	 		comment.points += 1
      		end
      		comment.save

      		origin = env["HTTP_REFERER"] || '/'
      		redirect to(origin)
    	else
      		status 500
      		return "Error: User not logged in."
    	end
	end

	post '/downvote_comment/:id' do
    	comment_id = params["id"]

    	if session.has_key?("user_id")
      		user = User.get(session['user_id'])
      		comment = Comment.first(:id => comment_id.to_i)

		    existing_vote = Vote.first(:comment_id => comment_id.to_i, :user =>user)
      		if existing_vote

        		if not existing_vote.is_upvote
          			# If the user has already downvoted, undo the vote
		        	existing_vote.destroy
        			comment.points += 1
        		else
		        	# If the user has upvoted, change to a downvote
		          	existing_vote.is_upvote = false
          			existing_vote.save
          			comment.points -= 2
        		end

      		else
        		Vote.create(:comment_id => comment_id.to_i, :is_upvote => false, :user => user)
        		comment.points -= 1
      		end
      			comment.save

      		origin = env["HTTP_REFERER"] || '/'
      		redirect to(origin)
    	else
      		status 500
      		return "Error: User not logged in."
    	end
	end
end
