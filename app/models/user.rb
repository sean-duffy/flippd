class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String, required: true, length: 150
  property :email, String, required: true, length: 150
  property :team_name, String, required:false, length: 150, default: "unset"
  property :lecturer, Boolean, required: false, default: false

  has n, :badges
  has n, :videos_watched
  has n, :quiz_results
  has n, :comments
  has n, :votes
end
