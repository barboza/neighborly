class Authorization < ActiveRecord::Base
  attr_accessible :oauth_provider, :oauth_provider_id, :uid, :user_id, :user
  schema_associations
  validates_presence_of :oauth_provider, :user, :uid

  scope :from_hash, ->(hash){
    joins(:oauth_provider).where("oauth_providers.name = :name AND uid = :uid", { name: hash['provider'], uid: hash['uid'] })
  }

  scope :from_hash_without_uid, ->(hash){
    joins(:oauth_provider).where("oauth_providers.name = :name", { name: hash['provider'] }).joins(:user).where('users.email = :email', { email: hash['info']['email'] })
  }

  def self.find_from_hash(hash)
    hash['provider'] == 'google_oauth2' ? from_hash_without_uid(hash).first : from_hash(hash).first
  end

  def self.create_from_hash(hash, user = nil)
    user ||= User.create_from_hash(hash)
    create!(user: user, uid: hash['uid'], oauth_provider: OauthProvider.find_by_name(hash['provider']))
  end

  def self.create_without_email_from_hash(hash, user = nil)
    return create_from_hash(hash, user) if user.present?

    hash['info']['email'] = "change-your-email+#{Time.now.to_i}@neighbor.ly"
    auth = create_from_hash(hash)
    auth.user.confirm!
    auth
  end
end
