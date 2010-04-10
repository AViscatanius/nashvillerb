# This controller handles the login/logout function of the site.  
class SessionsController < BaseController
  
  def destroy  
    if facebook_session
      redirect_to facebook_connect_path(:logout => true) and return
    end
    cookies.delete :auth_token

    current_user_session.destroy
    reset_session    
    flash[:notice] = :youve_been_logged_out_hope_you_come_back_soon.l
    redirect_to new_session_path
  end

end
