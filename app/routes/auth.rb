require 'omniauth'
require './app/helpers/team_utils'

class Flippd < Sinatra::Application
  helpers TeamUtils

  if ENV['AUTH'] == "GOOGLE"
    require 'omniauth-google-oauth2'
    use OmniAuth::Strategies::GoogleOauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
    get('/auth/new') { redirect to('/auth/google_oauth2') }
  else
    use OmniAuth::Strategies::Developer
    get('/auth/new') { redirect to('/auth/developer') }
  end

  before do
    @user = nil
    @user = User.get(session[:user_id]) if session.key?(:user_id)
    @lecturers = @module["lecturers"]
    @teams = TeamUtils.load_teams(@module)
  end

  route :get, :post, '/auth/:provider/callback' do
    auth_hash = env['omniauth.auth']
    email = auth_hash.info.email
    user = User.first_or_create({ email: email }, { name: auth_hash.info.name})
    is_lecturer = @lecturers.include? email
    user.update(:lecturer => is_lecturer)
    team = TeamUtils.get_team_from_email(email, @teams)
    puts "team is"
    puts team["name"]
    if team != nil
        puts "team not nil"
        user.update(:team_name => team["name"])
    end
    puts "user team name"
    puts user.team_name
    session[:user_id] = user.id

    origin = env['omniauth.origin'] || '/'
    redirect to(origin)
  end

  get '/auth/failure' do
    flash[:error] = "Could not sign you in due to: #{params[:message]}"
    origin = env["HTTP_REFERER"] || '/'
    redirect to(origin)
  end

  get '/auth/destroy' do
    session.delete(:user_id)
    origin = env["HTTP_REFERER"] || '/'
    redirect to(origin)
  end
end
