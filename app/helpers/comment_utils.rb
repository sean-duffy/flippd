
module CommentUtils

	def self.is_comment_voting_on(settings)
		settings["voting_on"] == "true"
	end

	def self.get_comments(video_id, voting_on)
		get_replies(video_id, voting_on, -1)
	end

	def self.get_replies(video_id, voting_on, replying_to=-1)
		if voting_on
			order = [ :points.desc ]
		else
			order = [ :created.asc ]
		end
		Comment.all(:json_id => video_id, :order => order, :reply_to => replying_to)
	end

	def self.get_comment(comment_id, user=nil)
		if user == nil
			Comment.first(:id => comment_id)
		else
			Comment.first(:id => comment_id.to_i, :user => user)
		end
	end


	def self.get_existing_vote(comment_id, user)
		vote = Vote.first(:comment_id => comment_id, :user => user)
	end

	def self.create_vote(comment_id, user, upvote)
		Vote.create(:comment_id => comment_id, :is_upvote => upvote, :user => user)
	end

	def self.create_upvote(comment_id, user)
		self.create_vote(comment_id, user, true)
	end

	def self.create_downvote(comment_id, user)
		self.create_vote(comment_id, user, false)
	end
end
