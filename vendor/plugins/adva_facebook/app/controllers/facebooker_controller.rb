class FacebookerController < BaseController
  skip_before_filter :check_facebook_session_state, :only => [:disconnect]
  skip_before_filter :set_facebook_session, :only => [:disconnect]
  skip_before_filter :verify_authenticity_token, :only => [:disconnect]
  # before_filter :verify_uninstall_signature, :only => [:disconnect]  seems to be broken on FB's side!!!
  before_filter :login_required, :only => [:invite]
  
  before_filter :check_facebook_auth, :only => [:profile_tab]

  def check_facebook_auth
    if params[:fb_sig_profile_user]
      @fb_user = Facebooker::User.new(params[:fb_sig_profile_user]) 
      @user    = User.find_by_facebook_id(@fb_user.id)            
      @is_tab  = true
    elsif facebook_session
      ensure_authenticated_to_facebook
      ensure_application_is_installed_by_facebook_user
      
      @fb_user = facebook_session.user
      @user    = FbUser.for(facebook_session.user.to_i, facebook_session)
      @user.save!
      user_session = UserSession.create(@user)
      self.current_user = user_session.record
    else
      render :text => 'Not found.' and return false
    end    
  end
  
  def whyconnect
    render 'whyconnect', :layout=>'default'
  end
  
  def profile_tab
    render :action => 'profile_tab', :layout => "application" and return
  end

  def invite
    respond_to do |format|
      format.html {render :action => 'invite', :layout => 'application'}
      format.fbml {render :action => 'invite', :layout => false}      
    end
      
  end
    
  def connect
    if params[:logout] && !facebook_session
      redirect_to logout_path
    end
  end
  
  def disconnect
    if request.post?
      if fb_user = FbUser.find_by_facebook_id(params[:fb_sig_user])
        fb_user.facebook_id = nil
        if !fb_user.email && !fb_user.password
          #not worth keeping them
          fb_user.destroy
        else
          fb_user.save!
        end
      end
      render :nothing => true, :layout => false
    end
  end
    
  def authenticate
    unless facebook_session #must be logged in to facebook
      domain = Facebooker.facebooker_config['callback_url'].gsub('www', '').gsub(":10000", '')
      cookies.each {|k, v| 
        cookies.delete k, :domain => domain #delete stale FB cookies (i.e. if the user's FB session expired, but the cookie is still on the site)
      }
      logger.warn("Facebook:InvalidLoginError - tried to hit authenticate but wasn't logged in.")
      redirect_to home_url and return
    end
    
    if logged_in?
      fb_user = FbUser.link_with_existing_user(current_user, facebook_session)
      if fb_user.save
        Membership.create(:site_id=>Site.find(:first).id,:user_id=>fb_user.id) if !Membership.find(:first,:conditions=>['user_id = ? and site_id = ?',Site.find(:first).id,fb_user.id])
        flash[:notice] = "Great, your Facebook account was linked."
      elsif fb_user.errors.on(:facebook_id)
        flash[:notice] = "A different account has already been linked to your Facebook profile so we've logged you in to that one."
        fb_user = FbUser.find_by_facebook_id(facebook_session.user.to_i).becomes(User)
        session[:uid] = fb_user.id
        set_user_cookie!(fb_user)
      else
        flash[:notice] = "There was an error linking your Facebook account, so you've been logged out."
        redirect_to facebook_connect_path(:logout => true) and return
      end
      # redirect_back_or_default (dashboard_user_path(fb_user, :facebook => fb_user.just_connected ? 'connected' : 'logged-in')) 
      redirect_to '/' and return     
    else
      #logging in with FB, creating new account if needed
      fb_user = FbUser.for(facebook_session.user.to_i,facebook_session)
      #debugger
      unless fb_user.valid?
        flash[:notice] = fb_user.errors.full_messages.to_sentence
        redirect_to facebook_connect_path(:logout => true) and return        
      else
        fb_user.save!
        Membership.create(:site_id=>Site.find(:first).id,:user_id=>fb_user.id) if !Membership.find(:first,:conditions=>['user_id = ? and site_id = ?',Site.find(:first).id,fb_user.id])
        session[:uid] = fb_user.id
        set_user_cookie!(fb_user)
        #redirect_back_or_default(dashboard_user_path(fb_user, :facebook => fb_user.just_connected ? 'connected' : 'logged-in')) and return
        redirect_to '/' and return  
      end      
    end
  end
  
  protected
    def verify_uninstall_signature 
      signature = '' 
      keys = params.keys.sort
      keys.select{|k| k != 'fb_sig'}.each do |key|
        next unless key.include?('fb_sig')
        key_name = key.gsub('fb_sig_', '')          
        signature += key_name 
        signature += '=' 
        if params[key].is_a?(Hash)
          signature += params[key].values.join(',')
        else
          signature += params[key]
        end
      end
    
      signature += Facebooker.secret_key 
      calculated_sig = Digest::MD5.hexdigest(signature) 
      logger.info "\nUNINSTALL :: Signature (fb_sig param from facebook) :: #{params[:fb_sig]}" 
      logger.info "\nUNINSTALL :: Signature String (pre-hash) :: #{signature}" 
      logger.info "\nUNINSTALL :: MD5 Hashed Sig :: #{calculated_sig}" 
    
      if calculated_sig != params[:fb_sig] 
        logger.warn "\n\nUNINSTALL :: WARNING :: expected signatures did not match\n\n" 
        return false 
      else 
        logger.warn "\n\nUNINSTALL :: SUCCESS!! Signatures matched.\n" 
        return true         
      end 
    end   

end