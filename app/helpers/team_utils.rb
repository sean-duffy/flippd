require 'json'
require './app/helpers/badge_utils'

module TeamUtils

    def self.load_teams(json)
        teams = json["teams"]
        id = 0
        teams.each do |team|
            #Pull the emails out into an array so team membership can be easily checked
            emails = []
            team["members"].each do |member|
                emails.push(member["email"])
            end
            team["emails"]=emails
            team["id"] = id
            id = id + 1
        end
    end

    def self.get_team_from_email(email, teams)
        teams.each do |team|
            if team["emails"].include? email
                return team
            end
        end
        return nil
    end

    def self.get_team_for_user(user_id, teams)
        user = User.first(:id => user_id)
        if user == nil
            return nil  
        end
        teams.each do |team|
            if team["emails"].include? user.email
                return team
            end
        end
        return nil
    end

    def self.get_users_for_team(team)
        # Team members might not have logged in
        # So this might not be exhuastive
        # Rather it is "get users who have ever logged in of this team"
        users = []
        team["emails"].each do |email|
            user = User.first(:email => email)
            if user != nil
                users.push(user)
            end
        end
        return users
    end

    def self.get_team_by_name(name, teams)
        teams.each do |team|
            if team["name"] == name
                return team
            end
        end
        return nil
    end

    def self.get_members(team)
        ret = []
        team["members"].each do |member|
            # Members might not yet have logged in, so will not be in users
            match = User.first(:email => member["email"])
            badges = 0
            if match != nil
                badges = BadgeUtils.get_badge_count(match.id)
            end
            ret.push(Hash["name" => member["name"], "badges"=>badges, "email" => member["email"]])
        end
        return ret
    end

    def self.count_member_badges(members)
        return members.map { |m| m["badges"] }.reduce(0, :+)
    end

end

  
