class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :ensure_domain
  before_filter :check_facebook_session_state   
  before_filter :set_facebook_session
  before_filter :set_fb_session_key
  helper_method :facebook_session

 
  TheDomain = Site.find(:first).host
 
  def ensure_domain
    if request.env['HTTP_HOST'] != TheDomain
    redirect_to ("http://" + TheDomain) if RAILS_ENV != 'development'
    end
  end
  
  def set_fb_session_key
     if facebook_session && logged_in? && facebook_session.infinite? && !current_user.fb_session_key
      current_user.update_attribute(:fb_session_key, facebook_session.session_key)
     end
  end

    def check_facebook_session_state 
      begin 
        fb_name = facebook_session.user.name
      rescue 
        delete_facebook_session
      end
      
    end

    def delete_facebook_session 
      clear_facebook_session_information
    end
end
      




