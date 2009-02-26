require 'SugarHelper'
require 'Render/CondensedLayout'
require 'Render/GridLayout'
require 'Render/SvgRenderer'
require 'Render/PngRenderer'
require 'Render/TextRenderer'
require 'Render/HtmlTextRenderer'
require 'Render/HtmlRenderer'

class SviewerController < ApplicationController

  after_filter :set_response_length

  attr_accessor :width, :height
  attr_accessor :input_sugar

  def index
    @seq = params[:seq].gsub(/\+.*$/,'')
    @width = params[:width]
    @height = params[:height]

    respond_to do |wants|
      wants.html { render_html }
      wants.xhtml { render_div }
      wants.txt { render_seq }
      wants.xml
      wants.svg { render_svg }
      wants.png { render_png }
    end
  end

  def show
    render :layout => 'standard'
  end

  def render_html
    do_rendering(HtmlTextRenderer)
    @text_result = @result
    render
  end

  def render_div
    do_rendering(HtmlRenderer)
    render :layout => 'standard'
  end

  def render_png
    do_rendering(PngRenderer)
    @text_result = @result
    render :text => @result, :content_type => Mime::PNG
  end

  def render_svg
    do_rendering(SvgRenderer)
    @result << XMLDecl.new(nil,'UTF-8')
    @text_result = @result.to_s
    render :text => @text_result, :content_type => Mime::SVG
  end

  def render_seq
    do_rendering(TextRenderer)
    render :text => @result, :content_type => 'text/plain'
  end

  def do_rendering(rendering_class)
    renderer = rendering_class.new()
    if ( width != nil && height != nil )
      renderer.width = width
      renderer.height = height
    end
    sugar = get_sugar
    renderer.sugar = sugar
    renderscheme = session[:sugarscheme] ? session[:sugarscheme] : 'text:ic'
    
    begin
      if renderscheme == :boston
        renderer.scheme = 'boston'
        CondensedLayout.new().layout(sugar)
      elsif renderscheme == :oxford
        renderer.scheme = 'oxford'
        GridLayout.new().layout(sugar)    
      else
        renderer.scheme = 'text:ic'
        CondensedLayout.new().layout(sugar)    
      end

      if renderer.is_a? TextRenderer
        renderer.scheme = params[:ns].to_sym
      end

      renderer.initialise_prototypes()
      @result = renderer.render(sugar)
    rescue Exception => e
      logger.error(e)
      logger.error(e.backtrace.join("\n"))
      render :nothing => true
    ensure
      sugar.finish
    end
  end

  def get_sugar
    if @input_sugar != nil
      return @input_sugar
    end
    seq = @seq
    in_ns = :ecdb

    params[:ns] = params[:ns] || 'none'

    if params[:ns].to_sym == :ic
      in_ns = :ic
    end
    if params[:ns].to_sym == :glyde
      in_ns = :glyde
    end
    if params[:ns].to_sym == :glycoct
      in_ns = :glycoct
    end    
    sugar = SugarHelper.CreateRenderableSugar(seq, in_ns)
    return sugar    
  end

  private :do_rendering, :get_sugar

  def set_response_length
    if @text_result != nil
      response.headers["Content-Length"] = @text_result.length
      response.headers["Cache-Control"] = "max-age: 3600"
    end
  end

  
  # def read_post_data
  #   return unless request.post?
  #   slurp_method = "read_post_#{request.post_format}"
  #   if respond_to?(slurp_method)
  #     send(slurp_method)
  #   else
  #     return false
  #   end
  # end

  def read_post_xml
    sugar_xml = @request.raw_post.dup
    sugar = SugarHelper.CreateRenderableSugar(sugar_xml, :glyde)
    @input_sugar = sugar
  end

  def read_post_url_encoded
    sugar_xml = @request.raw_post.dup
    sugar = SugarHelper.CreateRenderableSugar(sugar_xml)
    @input_sugar = sugar    
  end

end