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
		if user_id == nil
			false
		else
			true
		end
	end

	def display_notification(name, title, text)
		# Displays a flash snotification to the user
		flash[:notification][name] = {"title" => title, "text" => text}
	end
end
