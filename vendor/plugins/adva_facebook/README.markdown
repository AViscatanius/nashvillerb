Adva Facebook
==========================================================

Meant to help integrate facebook in to any Adva Application

Dependencies
============
- Facebooker Plugin (bborn's branch: git://github.com/bborn/facebooker.git)
- Adva CMS


Installation
===================


1. Install the adva_cms
2. (Facebooker gem is already in this plugin )Place config/facebooker.yml in to your config directory... sample configuration below:

development:
  api_key: 9fdfdsfdsafdsfadsfdfadsfdsfads
  secret_key: 9fdfdsfdsafdsfadsfdfadsfdsfads
  canvas_page_name: blah
  callback_url: blah.blah.blah:3000
  pretty_errors: true
  set_asset_host_to_callback_url: true

test:
  api_key: 9fdfdsfdsafdsfadsfdfadsfdsfads
  secret_key: 9fdfdsfdsafdsfadsfdfadsfdsfads
  canvas_page_name:
  callback_url:
  set_asset_host_to_callback_url: true
  tunnel:
    public_host_username:
    public_host:
    public_port: 4007
    local_port: 3000
    server_alive_interval: 0

production:
  api_key: 9fdfdsfdsafdsfadsfdfadsfdsfads
  secret_key: 9fdfdsfdsafdsfadsfdfadsfdsfads
  canvas_page_name: blah_blah
  callback_url: www.blah.com
  set_asset_host_to_callback_url: true

3. Create your application on Facebook. Go to [http://www.facebook.com/developers/createapp.php](http://www.facebook.com/developers/createapp.php)

    * `Application Name`: You app's name
      
    * In the **AUTHENTICATION** tab:
  
        `Post-Remove Callback URL` = `http://www.yourdomain.com/facebooker/disconnect`

        *If in development, all URLs should have port 10000 appended, so `http://www.yourdomain.com:10000/` for development*

        *I recommend starting out in development mode, then switching to production mode*      
     
  
    * In the **CANVAS** tab:

        `Canvas Callback URL` = `http://www.yourdomain.com/` 
      
        *If in development, this should have port 10000 appended, so `http://www.yourdomain.com:10000/` for development*      
      
        `Canvas Page URL` = `http://apps.facebook.com/yourappname/`
      
        _(Where `yourappname` is a URL-safe string)_
          
      
    * In the **CONNECT** tab: 
      
        `Connect URL` = `http://www.yourdomain.com/facebook/connect`
      
        `Base Domain` = `yourdomain.com` 
      
    * In the **ADVANCED** tab: 
      
        Select sandbox mode if you want to work on this app in development mode 
      
        *(allows debugging, prevents other users from seeing the app)*
      
              
    * In the **PROFILES** tab: 
      
        `Tab Name` = `Your Tab Name`
      
        `Tab URL`  = `http://apps.facebook.com/[CANVAS_URL]/profile_tab`
      
    * **Remember to save your changes**
    
4. Modify `config/facebooker.yml' with the correct keys you got from facebook         
    
5. Generate cross-domain receiver file:

        script/generate xd_receiver
6. Create directory 'public/facebook/connect' and move xd_receiver.html in 'public' to that directory
        
7. Run your migrations again to catch the new migrations from this plugin      

8. Start your local server (`mongrel_rails start` or `script/server` or whatever)

11. Override the layout (if you haven't already), and in the header tag, insert:

      <%= render :partial => 'facebooker/fb_connect' %>
      <%= render :partial => 'facebooker/fb_require' %>

12. Put this or something like it whereever you want your login button and/profile pic:

        <% if facebook_session && current_user.facebook_id %>
           <fb:profile-pic uid="<%= current_user.facebook_id%>" facebook-logo="true" size="thumb" ></fb:profile-pic>
            <p><a href="#" onclick='FB.Connect.logoutAndRedirect("/logout")'>Logout</a></p>
        <% else %>
           <fb:login-button v="2" size="medium" onlogin="window.location = '/facebooker/authenticate';">Login with Facebook</fb:login-button>
        <% end %>

13. Make sure that the the stylesheets and javascript from the plugin are in the base application public directory.
    copy adva_facebook/public/stylesheets/adva_facebook/fb.css to RAILS_ROOT/public/stylesheets/adva_facebook/fb.css
    copy adva_facebook/public/javascripts/adva_facebook/fb.js to RAILS_ROOT/public/javascripts/adva_facebook/fb.js           
14. Go to http://www.facebook.com/code_gen.php?v=1.0&api_key=YOUR_API_KEY while you are logged in with a facebook user who has admin rights over the application
15. Put the code it gives you in to environment.rb
     FACEBOOK_SESSION_TOKEN = 'XXXXX'       
16. Test your installation! You should be able to click wherever you put the facebook connect button and have it connect


# First image in body needs to be removed and put somewhere else
## NOTES ##


# ALERT - I changed the site.rb model in adva_cms to make the user query return all users
    def find_users_and_superusers(id, options = {})
      #condition = ["memberships.site_id is NULL OR memberships.site_id = ? OR (memberships.site_id IS NULL AND roles.name = ?)", id, 'superuser']
      User.find :all #, options.merge(:include => [:roles, :memberships], :conditions => condition)
    end
# Currently the default is for this plugin to ask for maximum permissions (email, posting to a wall without authorization, etc..)
# Currently the default is for this plugin to post content to a the facebook user who creates the content's wall and all users in the database who have a facebook id (works for events and blog articles) This
  is almost a broadcast model which can be useful but may not be ideal for every solution
# Probably needs a generator to do some of the tasks above.
# Needs a more elegant way of mixing in to the user model
# Needs a more elegant way of mixing in to the base controller (right now it just overrides the application controller)
# Needs some code cleanup
# Needs some configuration options
# Needs some testing


Copyright (c) 2010 William Bridges & Localwrkx.com
