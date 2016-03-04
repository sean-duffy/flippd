require 'open-uri'
require 'json'
require 'sinatra/base'
require './app/helpers/general_utils'
require './app/helpers/phase_utils'
require './app/helpers/comment_utils'

class Flippd < Sinatra::Application
  helpers PhaseUtils, CommentUtils, GeneralUtils

	post '/post_comment/:id' do
		video_id = params["id"]
    	body = params[:body]

		user_id = get_user_id(session)
		if is_user_logged_in(user_id)
			@user = User.get(user_id)

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

		user_id = get_user_id(session)
		if is_user_logged_in(user_id)
			user = User.get(user_id)
      		comment = CommentUtils.get_comment(comment_id.to_i, user)

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

		user_id = get_user_id(session)
		if is_user_logged_in(user_id)
			user = User.get(user_id)
      		comment = CommentUtils.get_comment(comment_id.to_i)

      		existing_vote = CommentUtils.get_existing_vote(comment_id.to_i, user)
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
				CommentUtils.create_upvote(comment_id.to_i, user)
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

		user_id = get_user_id(session)
		if is_user_logged_in(user_id)
			user = User.get(user_id)
      		comment = CommentUtils.get_comment(comment_id.to_i)

		    existing_vote = CommentUtils.get_existing_vote(comment_id.to_i, user)
      		if existing_vote

				if existing_vote.is_upvote
					# The user has upvoted, change to a downvote
		          	existing_vote.is_upvote = false
          			existing_vote.save
          			comment.points -= 2
				else
					# The user has already downvoted, undo the vote
					existing_vote.destroy
        			comment.points += 1
				end

      		else
        		CommentUtils.create_downvote(comment_id.to_i, user)
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
