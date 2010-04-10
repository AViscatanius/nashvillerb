class FacebookBlogMailer < ActionMailer::Base
  def new_post(params)
    recipients params[:email]
    from       params[:email]
    bcc        params[:recipients]
    subject    params[:subject]
    body       :params => params
  end
  
  def new_event(params)
    recipients params[:email]
    from       params[:email]
    bcc        params[:recipients]
    subject    params[:subject]
    body       :params => params
  end
end