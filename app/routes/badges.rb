require 'sinatra/base'
require './app/helpers/badge_utils'
require 'time'

class Flippd < Sinatra::Application
    helpers BadgeUtils

    #only accessible if logged in, as link is in user profile dropdown
    get '/badges/my_badges' do
        user = User.get(@user_id)
        @earnt = []
        @not_earnt = []
        @total_badges = @badges.length
        @badges.each do |badge|
            if @user.lecturer
                count = BadgeUtils.get_owner_count(badge)
                badge["count"] = BadgeUtils.get_owner_count(badge)
            end
            if BadgeUtils.has_badge(@user_id, badge)
                #add date earnt to badge data struct
                badge["date"] = BadgeUtils.get_date_earned(@user_id, badge).strftime("%A %-d %B %Y")
                @earnt.push(badge)
            else
                @not_earnt.push(badge)
            end
        end
        erb :badges
    end
end
