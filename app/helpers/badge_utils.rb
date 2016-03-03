require 'json'

module BadgeUtils
     def self.load_badges(json)
        badges = json['badges']
        badges.each do |badge|
            # IDs of pages that could trigger an object are below requires
            # Here we pull them out and put them in a new field
            # So that searching for potential rewards is easier
            triggers = []
            badge["requires"].each do |key,req|
                #key is e.g. "videos_watched"
                #req is a list of objects giving id/subreqs (e.g. marks)
                req.each do |req_obj|
                    triggers.push(req_obj["id"])
                end
            end
            badge["triggers"] = triggers
        end
        return badges
     end

    def self.is_any_trigger(page_id, badges)
        badges.each do |badge|
            if self.triggers(page_id, badge)
                return true
            end
        end
        return false
    end

    def self.triggers(page_id, badge)
        if badge["triggers"].include? page_id
            return true
        end
        return false
    end

    def self.get_potential_triggered_badges(page_id, badges)
        if not self.is_any_trigger(page_id, badges)
            return []
        end
        triggered = []
        badges.each do |badge|
            if self.triggers(page_id, badge)
                triggered.push(badge)
            end
        end
        return triggered
    end

    def self.are_requirements_met(user_id, badge)
        if self.has_badge(user_id, badge)
            return false
        end
        pass = self.check_watched_videos_req(user_id, badge)
        pass = self.check_quiz_result_req(user_id, badge)
        return pass
    end

    def self.are_team_requirements_met(user_id, badge, teams)
        team = TeamUtils.get_team_for_user(user_id, teams)
        # If user is not in a team, they are not eligible for a team badge
        if team == nil
            return false
        end
        if self.team_has_badge(team["name"], badge)
            return false
        end
        pass = self.check_team_result_req(user_id, badge, teams)
        return pass
    end

    def self.has_badge(user_id, badge)
        #User already has badge
        match = Badge.first(:user_id => user_id, :json_id => badge["id"])
        if match != nil
            return true
        end
        return false
    end

    def self.team_has_badge(team_name, badge)
        #Team already has badge
        match = TeamBadge.first(:team_name => team_name, :json_id => badge["id"])
        if match != nil
            return true
        end
        return false
    end
    
    def self.get_owner_count(badge)
        return Badge.count(:json_id => badge["id"])
    end

    def self.get_badge_count(user_id)
        return Badge.count(:user_id => user_id)
    end

    def self.get_date_earned(user_id, badge)
        match = Badge.first(:user_id =>user_id, :json_id => badge["id"])
        return match.date
    end

    def self.check_watched_videos_req(user_id, badge)
        #this badge has no videos_watched reqs
        if badge["requires"]["videos_watched"] == nil
            return true
        end
        badge["requires"]["videos_watched"].each do |video|
            #User has any videowatched matching this video_id
            matches = VideosWatched.first(:user_id => user_id, :json_id => video["id"])
            if matches == nil
                return false
            end
        end
        return true
    end

    def self.check_quiz_result_req(user_id, badge)
        #badge has no quiz_result reqs
        if badge["requires"]["quiz_result"] == nil
            return true
        end
        badge["requires"]["quiz_result"].each do |result|
            id = result["id"]
            mark = result["mark"]
            #Any matching result for this quiz for this user is > mark
            matches = QuizResult.first(:user_id => user_id, :json_id => id, :mark.gte => mark)
            if matches == nil
                return false
            end
        end
        return true
    end

    def self.check_team_result_req(user_id, badge, teams)
        team = TeamUtils.get_team_for_user(user_id, teams)
        if TeamUtils.team_has_logged_in(team) then
            puts "logged"
            team_members = TeamUtils.get_users_for_team(team)

            team_has_badge = true
            team_members.each do |team_member|
                if not has_badge(team_member.id, badge)
                    team_has_badge = false
                end
            end

            return team_has_badge
        else
            return false
        end
    end

    def self.award_badge(badge, user)
        Badge.create(:json_id => badge["id"], :date => Time.now, :user => user)
    end

    def self.award_team_badge(badge, user, teams)
        team = TeamUtils.get_team_for_user(user.id, teams)
        TeamBadge.create(:json_id => badge["id"], :date => Time.now, :team_name => team["name"])
    end

    def self.trigger_badges(user_id, resource_id, badges, teams)
        puts(resource_id) 
        awards = []
        badges_earnt = 0
        user = User.get(user_id)
        if self.is_any_trigger(resource_id, badges)
            potential_rewards = self.get_potential_triggered_badges(resource_id, badges)
            potential_rewards.each do |badge|
                if self.are_requirements_met(user_id, badge)
                   self.award_badge(badge, user)
                   badges_earnt += 1
                   awards.push(Hash["id" => badge["id"], "title" => badge["title"], "team" => false])
                   if self.are_team_requirements_met(user_id, badge, teams)
                       self.award_team_badge(badge, user, teams)
                       badges_earnt += 1
                       awards.push(Hash["id" => badge["id"], "title" => badge["title"], "team" => true])
                   end
                end
            end
        end
        return awards
    end

end
