class Badge
  include DataMapper::Resource

  property :id, Serial
  property :json_id, String, :length => 1000
  property :date, Date

  belongs_to :user
end
