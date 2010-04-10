require 'open-uri'
class FbUser < User
  attr_accessor :just_connected
  has_attached_file :avatar, :styles => { :large => "600x600>", :thumb => "120x120>", :tiny => "50x50#" },
                           :storage => :s3,
                           :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
                           :path => "avatar/:id/:style/:basename.:extension"

  
  def password_required?
    return false if facebook_id
    crypted_password.blank? || !password.blank?
  end
  
  def download_remote_image(image_url)
    self.avatar = do_download_remote_image(image_url)
  end
 
  def do_download_remote_image(image_url)
    io = open(URI.parse(image_url))
    def io.original_filename; base_uri.path.split('/').last; end
    io.original_filename.blank? ? nil : io
  rescue # catch url errors with validations instead of exceptions (Errno::ENOENT, OpenURI::HTTPError, etc...)
  end

  validates_uniqueness_of :facebook_id, :allow_nil => true


  def to_facebooker_user
    fb_session = Facebooker::Session::new(Facebooker.api_key, Facebooker.secret_key)
    fb_session.secure_with!(self.session_key, self.facebook_id)
    u = Facebooker::User.new(self.facebook_id, fb_session)
  end

  def account_id
    id
  end
  
  def self.link_with_existing_user(user, facebook_session)
    fb_user = user.becomes(FbUser)
    unless facebook_session.nil?        
      if facebook_session.user.to_i != fb_user.facebook_id.to_i
        fb_user.facebook_id = facebook_session.user.to_i 
        fb_user.just_connected = true
      end
      fb_user.email  = facebook_session.user.email unless fb_user.email
      fb_user.download_remote_image(facebook_session.user.pic_big)
      #fb_user.gender = fb_user.gender_from_fb_sex(facebook_session.user.sex) unless fb_user.gender
      fb_user.store_session(facebook_session.session_key)       
    end
    fb_user
  end
  

    
  def self.for(facebook_id,facebook_session)
    returning (self.find_by_facebook_id(facebook_id) || self.new(:facebook_id=>facebook_id)) do |user|
      unless facebook_session.nil?
        user.update_facebook_information(facebook_session)
        user.store_session(facebook_session.session_key) 
        user.just_connected = true if user.new_record?
      end
    end
  end
      
  def update_facebook_information(facebook_session)
    self.about = facebook_session.user.profile_blurb unless self.about
    self.download_remote_image(facebook_session.user.pic_big)
    self.email  = facebook_session.user.email unless self.email
    self.first_name = facebook_session.user.first_name unless self.first_name
    self.last_name = facebook_session.user.last_name unless self.last_name
  end

  def create_unique_login(string)
    counter = 1
    fb_login = string
    
    conditions = ["email = ?", fb_login]
    unless new_record?
      conditions.first << " and id != ?"
      conditions       << id
    end    
    
    self.email = conditions[1]
    while self.class.exists?(conditions)
      suffix = "#{counter += 1}"
      conditions[1] = "#{fb_login}#{suffix}"      
      self.email = conditions[1]    
    end
  end

  def store_session(session_key)
    if self.session_key != session_key
      self.session_key = session_key
    end
  end
  
  def facebook_session
    @facebook_session ||=  
      returning Facebooker::Session.create do |session| 
        session.secure_with!(session_key,facebook_id,1.day.from_now) 
      end
  end
  

    
end