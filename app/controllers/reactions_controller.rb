require 'SugarHelper'
require 'tempfile'

module PathwayReaction
  attr_accessor :parent,:next
end

class ReactionsController < ApplicationController

  before_filter :normalise_sequence, :only => [:edit, :new, :create, :update]
  before_filter :remove_anomer, :only => [:create, :new]
  after_filter  :pretty_print_sequences, :only => [:new, :create]

  layout 'standard'

  def index
    matrix
    render :action => 'matrix'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def matrix
    @reactions = Reaction.find(:all).reject { |reac| ! reac.has_enzyme? }
  end

  def list_by_donor
    @reactions = Reaction.find(:all)
    
    if params[:donor] != nil
      @reactions = @reactions.select { |reac| reac.donor.name == params[:donor] }
    end
    if params[:acceptor] != nil
      @reactions = @reactions.select { |reac| reac.substrate_residue.name == params[:acceptor]}
    end
    if params[:linkage] != nil
      @reactions = @reactions.select { |reac| reac.linkage == params[:linkage]}      
    end

    @pathways = @reactions.collect { |r| (r.pathway || '').split(',')}.flatten.uniq
        
    @invalid_glycosciences = @reactions.collect { |r| (r.checked_evidence||'').split(',')  }.flatten.uniq
    
    @disaccharides = @reactions.collect { |r| Disaccharide.find_all_by_residuedelta(r.residuedelta) }.flatten.uniq
    
    @disaccharides = @disaccharides.delete_if { |d| @invalid_glycosciences.include? d.glycosciences }
    
    respond_to do |wants|
      wants.html
      wants.xhtml
      wants.xml { render :action => 'list.rxml', :layout => false }
    end
  end

  def list
    @reactions = Reactions.paginate :page => params[:page], :order => 'id ASC'
    respond_to do |wants|
      wants.html
      wants.xhtml 
      wants.xml { render :action => 'list.rxml', :layout => false }
    end
  end

  def show
    @reaction = Reaction.find(params[:id])
    respond_to do |wants|
      wants.html { render :action => 'show.rhtml' }
      wants.xhtml { render :action => 'show.rhtml' }
      wants.xml { render :action => 'show', :layout => false }
      wants.svg { params[:compact] ? render_compact_svg(@reaction) : render_svg(@reaction) }
      wants.png { render_png(@reaction) }
      wants.txt { render_txt(@reaction) }
    end
  end

  def show_delta
    if params[:schema]
      session[:sugarscheme] = params[:schema].to_sym
    end
    @reaction = Reaction.find(params[:id])
    respond_to do |wants|
      wants.html 
      wants.xhtml
      wants.xml { render :action => 'show', :layout => false }
      wants.svg { render_residuedelta_svg(@reaction) }
    end
  end

  alias :disp :show

  def new
    @reaction = Reaction.new
  end

  def create
    @reaction = Reaction.new(params[:reaction])
    if @reaction.save
      flash[:notice] = 'Reaction was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @reaction = Reaction.find(params[:id])
    pretty_print_sequences
  end

  def update
    @reaction = Reaction.find(params[:id])
    if @reaction.update_attributes(params[:reaction])
      flash[:notice] = 'Reaction was successfully updated.'
      redirect_to :action => 'show', :id => @reaction
    else
      render :action => 'edit'
    end
  end

  def destroy
    Reaction.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def pathway
    unless params[:id]
      return pathway_index
    end    
    
    if params[:id] != 'all'
      @reactions = Reaction.find_by_sql ["select * from reactions where pathway like ?","%#{params[:id]}%"]
    else
      @reactions = Reaction.find_by_sql ["select * from reactions where pathway is not null"]
    end
    
    if params[:filter] && params[:filter][:donor]
      @reactions.reject! { |r| r.donor.name(:ic) != params[:filter][:donor] }
    end
    if params[:filter] && params[:filter][:linkage]
      @reactions.reject! { |r| r.linkage != params[:filter][:linkage] }      
    end
    
    endstructs = {}
    @reactions.each { |r|
      r.extend(PathwayReaction)
      r.next = []
      endstructs[r.endstructure] = r
    }
    @reactions.each { |r|
      if endstructs[r.substrate] != nil
        r.parent = endstructs[r.substrate]
        r.parent.next << r
      end
    }
    if params[:filter] && params[:filter][:downstreamgene]
      gene = Geneinfo.easyfind(:keywords => params[:filter][:downstreamgene], :fieldnames => ['genename']).first
      @reactions.delete_if { |r| ! r.genes.include?(gene) }
      make_summary_sugar
    else
      make_summary_sugar
      @reactions.delete_if { |r| r.parent != nil }
    end

    @reactions
  end
  def make_summary_sugar
    summary_maker = StructureSummaryController.new()
    input_sugars = @reactions.collect { |r|
      end_sug = SugarHelper.CreateMultiSugar(r.endstructure)
      start_sug = SugarHelper.CreateSugar(r.substrate)
      end_sug.residue_composition.each { |res|
        res.extend(HitCounter)
        res.initialise_counter
        res.get_counter(:genes)
      }
      end_sug.subtract(start_sug).each { |donor|
        r.genes.each { |gene|
          donor.increment_counter(gene,:genes)
        }
      }
      end_sug.root.anomer = 'u'
      end_sug
    }
    @sugars = summary_maker.execute_summary_for_sugars(input_sugars,false)
    summary_maker.markup_sugarset(@sugars)
    @sugars.each { |sug|
      sug.callbacks << lambda { |element,renderer|
        container_element = Element.new('svg:g')
        sug.overlays << container_element
        sug.residue_composition.each { |res|
          next unless res.parent
          if res.get_counter(:genes).size > 0 && ! res.is_stub?
            res.linkage_at_position.callbacks << renderer.callback_make_element_label(container_element,res.linkage_at_position,res.get_counter(:genes).collect { |g| g.genename },'#0000ff')
          end
        }
      }
    }
  end

  def pathway_index
    @reactions = Reaction.find_by_sql ["select * from reactions where pathway is not null"]
    @pathway_names = @reactions.collect { |reac|
      reac.pathway.split(',')
    }.flatten.uniq
    render :action => 'pathway_index'
  end

  private

  def pretty_print_sequences
    @reaction.residuedelta = SugarHelper.ConvertToIupac(@reaction.residuedelta) if @reaction.residuedelta != nil
    @reaction.substrate = SugarHelper.ConvertToIupac(@reaction.substrate) if @reaction.substrate != nil
    @reaction.endstructure = SugarHelper.ConvertToIupac(@reaction.endstructure) if @reaction.endstructure != nil
  end

  def normalise_sequence
    if params[:reaction] != nil
    [:residuedelta, :substrate, :endstructure].each { |field|
      if params[:reaction][field] != nil && params[:reaction][field].length > 0
        sug = SugarHelper.CreateSugar(params[:reaction][field],:ic)
        params[:reaction][field] = sug.sequence
        logger.error("Sequence is now "+sug.sequence)
        sug.finish
      end
    }
    end
  end

  def remove_anomer
    if params[:reaction] != nil
    [:residuedelta, :substrate, :endstructure].each { |field|
      if params[:reaction][field] != nil && params[:reaction][field].length > 0
        sug = SugarHelper.CreateSugar(params[:reaction][field])
        if field == :substrate || field == :endstructure
          sug.root.anomer = 'u'
        end
        params[:reaction][field] = sug.sequence
        logger.error("Sequence is now "+sug.sequence)
        sug.finish
      end
    }
    end
  end


  def render_svg(reaction)
    get_svg(reaction)
    render :action => 'svg', :layout => false
  end
  
  def render_compact_svg(reaction)
    get_compact_svg(reaction)
    render :text => @text_result, :content_type => Mime::SVG, :layout => false
  end

  def render_residuedelta_svg(reaction)
    get_residuedelta_svg(reaction)
    render :text => @text_result, :content_type => Mime::SVG, :layout => false
  end


  def get_residuedelta_svg(reaction, mode=:full)
    sug = SugarHelper.CreateRenderableSugar(reaction.residuedelta)    
    sug.name = "endstructure-#{@id}"
    @endstructure = SugarHelper.RenderSugar(sug,mode,session[:sugarscheme])
    sug.finish
    sug = SugarHelper.CreateRenderableSugar(reaction.substrate_residue.shallow_clone.to_sugar)
    sug.name = "substrate-#{@id}"
    @substrate = SugarHelper.RenderSugar(sug,mode,session[:sugarscheme])
    sug.finish
    sug = reaction.as_sugar(reaction.residuedelta)
    sug_root = sug.root
    def sug_root.raw_data_node
      Document.new
    end
    sug = SugarHelper.CreateRenderableSugar(sug)
    sug.name = "donor-#{@id}"
    @delta = SugarHelper.RenderSugar(sug,mode,session[:sugarscheme])
    sug.finish
    
    @endstructure.root.add_attribute('width','100')
    @substrate.root.add_attribute('width','100')
    @delta.root.add_attribute('width','100')
    @endstructure.root.add_attribute('height','100')
    @substrate.root.add_attribute('height','100')
    @substrate.root.add_attribute('viewBox','-150 -150 200 200')
    @delta.root.add_attribute('viewBox','-550 -250 400 400')
    @delta.root.add_attribute('height','100')
    @delta.root.add_attribute('preserveAspectRatio', 'xMinYMid')    
    @substrate.root.add_attribute('preserveAspectRatio', 'xMinYMid')    
    @endstructure.root.add_attribute('preserveAspectRatio', 'xMinYMid')    
    @text_result = render_to_string :action => 'svg.rxml', :layout => false, :content_type => Mime::XML
    @text_result    
  end

  def get_svg(reaction, mode=:full)
    sug = SugarHelper.CreateRenderableSugar(reaction.residuedelta)
    sug.name = "delta-#{@id}"
    @delta = SugarHelper.RenderSugar(sug,mode,session[:sugarscheme])
    sug.finish
    sug = SugarHelper.CreateRenderableSugar(reaction.substrate)
    sug.name = "substrate-#{@id}"
    @substrate = SugarHelper.RenderSugar(sug,mode,session[:sugarscheme])
    sug.finish
    sug = SugarHelper.CreateRenderableSugar(reaction.endstructure)
    sug.name = "substrate-#{@id}"
    @endstructure = SugarHelper.RenderSugar(sug,mode,session[:sugarscheme])
    sug.finish
    
    @endstructure.root.add_attribute('width','100')
    @substrate.root.add_attribute('width','100')
    @delta.root.add_attribute('width','100')
    @endstructure.root.add_attribute('height','100')
    @substrate.root.add_attribute('height','100')
    @delta.root.add_attribute('height','100')
    @delta.root.add_attribute('preserveAspectRatio', 'xMinYMid')    
    @substrate.root.add_attribute('preserveAspectRatio', 'xMinYMid')    
    @endstructure.root.add_attribute('preserveAspectRatio', 'xMinYMid')    
    @text_result = render_to_string :action => 'svg.rxml', :layout => false, :content_type => Mime::XML
    @text_result
  end
  
  def get_compact_svg(reaction, mode=:full)
    endstruct = SugarHelper.CreateRenderableSugar(reaction.endstructure)
    startstruct = SugarHelper.CreateSugar(reaction.substrate)
    endstruct.subtract(startstruct).each { |donor|
      parent_link = donor.linkage_at_position()
      if parent_link
        parent_link.labels << 'donor'
        donor.labels << 'donor'
        donor.parent.labels << 'attachment_point'
      end
    }

    substrate = SugarHelper.RenderSugar(endstruct, mode,session[:sugarscheme])

    if (mode == :full)
      style = substrate.elements['//svg:defs'].add_element 'svg:style', {'type' => 'text/css'}
      style.text = ".donor *, .donor { stroke: #999999 !important; fill: #999999 !important; fill-opacity: 0.7 !important; } .attachment_point * { stroke: #ff0000 !important; stroke-width: 10 !important;}"
    else
      substrate.elements.each("//*[contains(@class,'donor')]/*") { |el|
        el.add_attribute('style','fill: #999999; fill-opacity: 0.7; stroke: #999999;')
      }
      substrate.elements.each("//*[contains(@class,'donor')]") { |el|
        el.add_attribute('style','stroke: #999999;')
      }
      substrate.elements.each("//*[contains(@class,'attachment_point')]/*") { |el|
        style = el.attribute('style').value || ''
        el.add_attribute('style',"#{style}; stroke: #ff0000; stroke-width: 10")
      }      
    end

    substrate << XMLDecl.new()
        
    @text_result = substrate.to_s
    @text_result
  end
  
  def render_png(reaction)
    require 'RMagick'

    svg = params[:compact] ? get_compact_svg(reaction, :basic) : get_svg(reaction, :basic)
    svg_string = svg.to_s
    svg_string.gsub!(/svg\:/,'')
    temp_svg = Tempfile.new('svgrender.svg')
    temp_svg << svg_string
    temp_svg.close
    the_svg = File.new(temp_svg.path)
    img = Magick::Image::read(the_svg) { self.format = 'SVG' }
    the_svg.close
    if (params[:width] != nil && params[:height] != nil)
      img.first.resize_to_fit!(params[:width],params[:height])
    end
    render :text => img.first.to_blob { self.format = 'PNG' }, :content_type => Mime::PNG
  end
  
  def render_txt(reaction)
    pretty_print_sequences
    logger.error("#{@reaction.substrate} + #{@reaction.residuedelta} = #{@reaction.endstructure}")
    render :text => "#{@reaction.substrate} + #{@reaction.residuedelta} = #{@reaction.endstructure}", :content_type => Mime::TEXT
  end
  
end
