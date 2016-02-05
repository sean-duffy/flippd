require 'open-uri'
require 'json'
require 'sinatra/base'

module GeneralUtils

	def get_user_id(session)
		# Returns the user id of the signed in user or nil if no user is signed in
		if session.has_key?("user_id")
		    session["user_id"]
		else
		    nil
		end
	end

	def is_user_logged_in(user_id)
		# Returns true if the user_id is not nil, else false
		if user_id == nil
			false
		else
			true
		end
	end

	def display_notification(name, title, text)
		# Displays a flash notification to the user
		flash[:notification][name] = {"title" => title, "text" => text}
	end

	def get_previous_and_next_page_links(@phases, pos)
		# Returns the link to the previous page and the next page, in that order
		p = get_by_pos(@phases, pos-1)
		n = get_by_pos(@phases, pos+1)
		return p, n
	end
end
