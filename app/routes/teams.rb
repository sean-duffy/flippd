require 'sinatra/base'
require './app/helpers/team_utils'
require './app/helpers/quiz_utils'

class Flippd < Sinatra::Application
    helpers TeamUtils, VideoUtils, QuizUtils, BadgeUtils, GeneralUtils

    before do
        @teams = TeamUtils.load_teams(@module)
        @user = User.get(@user_id)
        @team = TeamUtils.get_team_for_user(@user_id, @teams)
    end


    @@progress_good = "Y"
    @@progress_bad  = "N"
    @@progress_na   = "-"

    def page_guard()
        if @user_id == nil
            redirect to("/")
        end
        if @team == nil
            redirect to("/teams/no_team")
        end 
    end

    def check_team_badge(res_id)
        resource_badges = BadgeUtils.get_badges_for_resource(res_id, @badges)
        if resource_badges.empty?
            return @@progress_na
        end
        team_badge = true
        resource_badges.each do |badge|
            team_badge = BadgeUtils.team_has_badge(@team["name"], badge)
        end
        return team_badge == true ? @@progress_good : @@progress_bad
    end
    
    get '/teams/my_team' do
        page_guard()
        @members = TeamUtils.get_members(@team)
        # Sum member badges from the array of member hashes
        @member_badges = TeamUtils.count_member_badges(@members)
        @team_badge_count = 0
        @page = 'my_team'
        erb :team_view
    end

    get '/teams/member_badges' do
        page_guard()
        @members = TeamUtils.get_members(@team)
        @member_badges = TeamUtils.count_member_badges(@members)
        @badge_count = @badges.count
        @page = 'member_badges'
        erb :team_member_badges
    end

    get '/teams/team_badges' do
        page_guard()
        @members = TeamUtils.get_members(@team)
        @total_badges = @badges.length

        @earnt = []
        @not_earnt = []

        @badges.each do |badge|
            if BadgeUtils.team_has_badge(@team["name"], badge)
                #add date earnt to badge data struct
                badge["date"] = BadgeUtils.get_date_earned(@team["name"], badge).strftime("%A %-d %B %Y")
                @earnt.push(badge)
            else
                @not_earnt.push(badge)
            end
        end

        @page = 'team_badges'
        erb :team_badges
    end

    get '/teams/team_progress' do
        page_guard()
        #Fixed length array of "N" ie. no member has progressed
        default_progress = Array.new(@team["members"].length) { |i| @@progress_bad }
        # N/A progress ie. when there is no quiz for a topic
        null_progress = Array.new(@team["members"].length) { |i| @@progress_na }
        # N/A hash for a topic with no formatives
        null_formative = Hash["title"=>"-", "progress"=> null_progress, "team_knowledge"=>@@progress_na, "team_badge"=>@@progress_na]

        @headings = ["Subject", "", "Progress"]
        @progress_headings = ["Team Knowledge", "Team Badge"]
        #Half the team, rounding up, must watch a video/pass a quiz to mark off team knowledge
        team_knowledge_min = @team["members"].length.fdiv(2).ceil
        @progress = Hash.new
        
        #Users might not have logged in yet
        #Push logged in users first to simplify data gathering
        users = TeamUtils.get_users_for_team(@team)
        done = []
        @initials = []
        users.each do |user|
            @initials.push(get_user_initials(user.name))
            done.push(user.email)
        end
        #Now push the remainder
        @team["members"].each do |member|
            #Skip initialised users
            if done.include? member["email"]
                next
            end
            @initials.push(get_user_initials(member["name"]))
        end
        
        @video_total = Array.new(@team["members"].length) {|i| 0}
        @quiz_total = Array.new(@team["members"].length) {|i| 0}
        @video_knowledge_total = 0
        @video_badge_total = 0 
        @quiz_knowledge_total = 0
        @quiz_badge_total = 0

        @phases.each do |phase|
            phase_hash = Hash["title" => phase["title"], "topics" => []]
            phase["topics"].each do |topic|
                topic_hash = Hash["title" => topic["title"], "videos"=>[]]
                topic["videos"].each do |video|
                    #must use .dup to deep copy the default array
                    prog = default_progress.dup
                    pos = 0
                    count = 0
                    users.each do |user|
                        if is_video_watched(user.id, video["id"])
                            prog[pos] = @@progress_good
                            @video_total[pos]+=1
                            count += 1
                        end
                        pos += 1
                    end
                    knowledge = @@progress_bad
                    if count >= team_knowledge_min
                        knowledge = @@progress_good
                        @video_knowledge_total += 1
                    end
                    team_badge = check_team_badge(video["id"])
                    if team_badge == @@progress_good
                        @video_badge_total += 1
                    end 
                    video_hash = Hash["title" => video["title"], "progress" => prog, "team_knowledge" => knowledge, "team_badge" => team_badge]
                    topic_hash["videos"].push(video_hash)
                end
                if topic["quizzes"].empty?
                    #The comma after null_formative keeps this an array
                    #Ruby will otherwise make it back into a single object
                    topic_hash["formative"] = [null_formative,]
                else
                    topic_hash["formative"] = []
                    topic["quizzes"].each do |quiz|
                        prog = default_progress.dup
                        pos = 0
                        count = 0
                        users.each do |user|
                            if is_quiz_passed(user.id, quiz["id"])
                                prog[pos] = @@progress_good
                                @quiz_total[pos]+=1
                                count += 1
                            end
                            pos += 1
                        end
                        knowledge = @@progress_bad
                        if count >= team_knowledge_min
                            knowledge = @@progress_good
                            @quiz_knowledge_total += 1
                        end
                        team_badge = check_team_badge(quiz["id"])
                        if team_badge == @@progress_good
                            @quiz_badge_total += 1
                        end
                        quiz_hash = Hash["title" => quiz["title"], "progress" => prog, "team_knowledge"=>knowledge, "team_badge"=>team_badge]
                        topic_hash["formative"].push(quiz_hash)
                    end
                end
                phase_hash["topics"].push(topic_hash)
            end
            @progress[phase["title"]] = phase_hash
        end
        @progress_good = @@progress_good
        @progress_bad = @@progress_bad
        @progress_na = @@progress_na
        @page = 'team_progress'
        erb :team_progress
    end

    get '/teams/no_team' do
        erb :team_not_set
    end

end
