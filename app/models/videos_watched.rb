class VideosWatched
  include DataMapper::Resource

  property :id, Serial
  property :json_id, String, required: true, :length => 1000
  property :date, Date, required: true

  belongs_to :user
end
