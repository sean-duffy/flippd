require 'json'

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

    def self.team_has_logged_in(team)
        # This returns true if all members of a team
        # have logged in at some point
        team["emails"].each do |email|
            user = User.first(:email => email)
            if user == nil
                return false
            end
        end
        return true
    end

    def self.get_team_by_name(name, teams)
        teams.each do |team|
            if team["name"] == name
                return team
            end
        end
        return nil
    end

end


