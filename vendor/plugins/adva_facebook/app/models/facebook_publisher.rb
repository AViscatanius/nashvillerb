class FacebookPublisher < Facebooker::Rails::Publisher
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods # Required for rails 2.2
  
  def publish_stream(user_with_session_to_use, user_to_update, params)
    send_as :publish_stream
    from  user_with_session_to_use
    target user_to_update if user_to_update
    attachment params[:attachment].to_hash
    message params[:message]
    action_links params[:action_links]
  end
  
  def comment_created(comment, commentable_url)
    fb_user = comment.user.becomes(FbUser).to_facebooker_user
    commentable_string = %(a e i o u).include?(comment.commentable_name.downcase.first) ? 'an ' : 'a '
    commentable_string += comment.commentable_name.downcase

    attachment = Facebooker::Attachment.new
    attachment.href = commentable_url
    attachment.name = commentable_string
    attachment.add_image(comment.commentable.public_filename(:thumb), commentable_url) if comment.commentable_type.eql?('Photo')
    
    params = {:message => strip_tags(comment.comment), :attachment => attachment}
    publish_stream(fb_user, fb_user, params)
  end  
  
  def connected(user)
    fb_user = user.becomes(FbUser).to_facebooker_user
  
    if user.friends_ids.any?
      friend_data = " There are #{pluralize user.friends_ids.size,'friends'} in my network."
    else
      friend_data = " Want to join me?"
    end
  
    attachment = Facebooker::Attachment.new
    attachment.name = "I linked my #{@site.name} account with Facebook.#{friend_data}"
    attachment.caption = "#{@site.title} - #{@site.subtitle}"
    attachment.href = APP_URL+"?fb_user=true"
    attachment.add_image(user.avatar_photo_url(:thumb), attachment.href)
    
    params = {:attachment => attachment, :action_links => [action_link("Join {*actor*}'s network.","{*href*}")]}

    publish_stream(fb_user, fb_user, params)
  end
  
  def blog_post_created(post)

  end
  
  def event_created(post)

  end



  
  def friendship_created(friendship)
    fb_user = friendship.user.becomes(FbUser).to_facebooker_user
    
    attachment = Facebooker::Attachment.new
    attachment.name = "I became friends with #{friendship.friend.login.capitalize} on #{AppConfig.community_name}"
    attachment.caption = "#{AppConfig.community_name} - #{AppConfig.community_description}"
    attachment.href = user_url(friendship.friend, :host => default_host)
    attachment.add_image(friendship.friend.avatar_photo_url(:thumb), attachment.href)

    params = {:attachment => attachment}
    publish_stream(fb_user, fb_user, params)    
  end
    
  def default_host
    APP_URL.sub('http://', '')    
  end
    
end