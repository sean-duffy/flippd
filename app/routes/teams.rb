require 'sinatra/base'
require './app/helpers/badge_utils'
require 'time'

class Flippd < Sinatra::Application
    helpers TeamUtils, BadgeUtils
    
    before do
        @teams = TeamUtils.load_teams(@module)
    end

    get '/teams/my_team' do
        if @user_id == nil
            redirect to("/")
        end
        @user = User.get(@user_id)
        @team = TeamUtils.get_team_for_user(@user_id, @teams)
        @members=[]
        @team_badge_count = 0
        @member_badges = 0
        @team["members"].each do |member|
            match = User.first(:email => member["email"])
            #Users might never have logged in, in which case there is no match
            badges = 0
            if match != nil
                badges = BadgeUtils.get_badge_count(match.id)
            end
            @member_badges = @member_badges + badges
            @members.push(Hash["name"=>member["name"], "badges"=>badges])
        end

        erb :team_view
    end

    get '/teams/member_badges' do
        if @user_id == nil
            redirect to("/")
        end
        @user = User.get(@user_id)
        @team = TeamUtils.get_team_for_user(@user_id, @teams)
        @members=[]
        @member_badges = 0
        @badge_count = @badges.count
        @team["members"].each do |member|
            match = User.first(:email => member["email"])
            # Users might never have logged in, in which case there is no match
            badges = 0
            if match != nil
                badges = BadgeUtils.get_badge_count(match.id)
            end
            @member_badges = @member_badges + badges
            badge_perc = badges.fdiv(@badge_count)*100
            @members.push(Hash["name"=>member["name"], "badges"=>badges, "percent"=>badge_perc])
        end
        erb :team_member_badges
    end

    get '/teams/team_badges' do
        # Placeholder
        redirect to("/teams/my_team")
    end

end
