class ConfigController < ApplicationController
  layout 'standard'
  
  def constants
    text = render_to_string :action => 'constants', :layout => false
    render :text => text, :content_type => 'text/javascript'
  end
  
  def rendering
    session[:sugarscheme] = params[:schema].to_sym
  end
end
