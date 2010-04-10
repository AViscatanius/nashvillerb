class FbPostObserver < ActiveRecord::Observer
  observe Content
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods # Required for rails 2.2

  def after_create( content )
    return unless content.type == 'Article'
    return unless content.published?
    return unless content.author.facebook_id
    post = content
    fb_user = post.author.becomes(FbUser).to_facebooker_user
  
    attachment = Facebooker::Attachment.new
    attachment.name = "NEW BLOG ARTICLE: #{post.title}"
    attachment.description = strip_tags("#{post.body_html[0..200]}....")
    image_url = first_image_in_body(post.body_html)
    a = post
    attachment.href = "http://" + a.site.host + '/' + a.created_at.year.to_s + '/' + a.created_at.month.to_s + '/' + a.created_at.day.to_s + '/' + a.permalink    
    attachment.add_image(image_url, attachment.href) unless image_url.nil?
    
    params = {:image_url=>image_url,:attachment => attachment, :action_links => {:text => (post.site.title + ': ' + attachment.name), :href => attachment.href}}
    action_link = "[#{{:text => (post.site.title + ': ' + attachment.name), :href => attachment.href}.to_json}]"
    fbs = Facebooker::Session.create
    fbs.auth_token = FACEBOOK_SESSION_TOKEN
    fbs.secure_with!(post.author.becomes(FbUser).fb_session_key)
    fbs.post('facebook.stream.publish', {:uid=>fbs.user.facebook_id,:message=>'Check out my link below!',:action_links=>action_link,:target_id=>FAN_PAGE_ID,:attachment=>attachment.to_hash.to_json}, false) rescue ''
    y = []
    User.find(:all,:conditions=>['facebook_id IS NOT NULL']).each do |x|
      y.push(x.email) if x.becomes(FbUser).to_facebooker_user.has_permission?('email')
      if x.becomes(FbUser).to_facebooker_user.has_permission?('publish_stream') && x.becomes(FbUser).to_facebooker_user.has_permission?('offline_access')
        fbs2 = Facebooker::Session.create
        fbs2.secure_with!(x.fb_session_key)
        fbusr = fbs2.user
        FacebookPublisher.deliver_publish_stream(fbs.user, fbusr, params) rescue ''    
      end
    end
    
    FacebookBlogMailer.deliver_new_post(:recipients=>y,:email=>Site.find(:first).email,:subject=>"#{Site.find(:first).title}: #{post.title}",:post_url=>attachment.href,:post_title=>post.title) 
    
  end

  def first_image_in_body(body,size = nil, options = {})
    doc = Hpricot( body )
    image = doc.at("img")
    image ? image['src'] : nil
  end

  private
  def logger
    RAILS_DEFAULT_LOGGER
  end

end