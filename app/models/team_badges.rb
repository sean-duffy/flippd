class TeamBadge
  include DataMapper::Resource

  property :id, Serial
  property :json_id, String, :length => 1000
  property :date, Date
  property :team_name, String
end
