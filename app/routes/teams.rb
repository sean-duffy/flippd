require 'sinatra/base'
require './app/helpers/badge_utils'
require 'time'

class Flippd < Sinatra::Application
    helpers TeamUtils
    
    before do
        @teams = TeamUtils.load_teams(@module)
    end

end
