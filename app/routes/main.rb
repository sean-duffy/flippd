require 'open-uri'
require 'json'
require 'sinatra/base'
require './app/helpers/badge_utils'
require './app/helpers/phase_utils'
require './app/helpers/comment_utils'
require './app/helpers/general_utils'

class Flippd < Sinatra::Application
  helpers BadgeUtils, PhaseUtils, CommentUtils, GeneralUtils

    before do
        @session = session
        @user_id = get_user_id(session)

        # Load in the configuration (at the URL in the project's .env file)
        @json_loc = ENV['CONFIG_URL'] + "module.json"
        @module = JSON.load(open(@json_loc))
        @phases = load_phases(@module)
        @badges = BadgeUtils.load_badges(@module)
        @teams = TeamUtils.load_teams(@module)
		@settings = @module['settings']

		if !(flash[:notification])
        	flash[:notification] = {}
        end
    end

    get '/' do
        erb open(ENV['CONFIG_URL'] + "index.erb").read
    end

    get '/phases/:title' do
        @phase = nil
        @phases.each do |phase|
            @phase = phase if phase['title'].downcase.gsub(" ", "_") == params['title']
        end

        pass unless @phase
        erb :phase
    end

	get '/notification_alert' do
    	erb :notification_alert, :layout => false
	end
end
