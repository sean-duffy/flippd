require 'sinatra/base'
require './app/helpers/team_utils'

class Flippd < Sinatra::Application
    helpers TeamUtils
    
    before do
        @teams = TeamUtils.load_teams(@module)
        @user = User.get(@user_id)
        @team = TeamUtils.get_team_for_user(@user_id, @teams)
    end

    get '/teams/my_team' do
        if @user_id == nil
            redirect to("/")
        end
        if @team == nil
            redirect to("/teams/no_team")
        end 
        @members = TeamUtils.get_members(@team)
        # Sum member badges from the array of member hashes
        @member_badges = TeamUtils.count_member_badges(@members)
        @team_badge_count = 0
        erb :team_view
    end

    get '/teams/member_badges' do
        if @user_id == nil
            redirect to("/")
        end
        if @team == nil
            redirect to("/teams/no_team")
        end
        @members=TeamUtils.get_members(@team)
        @member_badges = TeamUtils.count_member_badges(@members)
        @badge_count = @badges.count
        erb :team_member_badges
    end

    get '/teams/team_badges' do
        # Placeholder
        redirect to("/teams/my_team")
    end

    get '/teams/no_team' do
        erb :team_not_set
    end

end
