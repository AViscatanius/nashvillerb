ActionController::Routing::Routes.draw do |map|
  
 map.facebook_connect 'facebook/connect', :controller => "facebooker", :action => 'connect'

 map.facebook_invite 'invite_facebook_friends', :controller => 'facebooker', :action => 'invite'

 map.facebook_profile_tab 'profile_tab', :controller => 'facebooker', :action => 'profile_tab', :format => 'fbml'

end