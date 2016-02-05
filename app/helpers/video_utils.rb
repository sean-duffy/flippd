require 'json'

module VideoUtils

	def is_video_watched(user_id, video_id)
		matches = VideosWatched.first(:user_id => user_id, :json_id => video_id)
		if matches == nil
		   	false
		else 
			true
		end
	end

end
