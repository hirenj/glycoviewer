class SugarbuilderController < ApplicationController
  layout 'standard'
  
  def index
    params[:ns] = params[:ns] ? params[:ns].to_sym : nil
    generate_prototypes
    if params[:seq]
      get_sugar
      draw_sugar
    else
      draw_sugar
#      render :action => 'build_sugar_index'
    end
  end

  def pallette
    params[:ns] = params[:ns] ? params[:ns].to_sym : nil
    generate_prototypes
    render :action => 'pallette', :layout => false, :content_type => Mime::XML
  end

  def build_sugar
    params[:ns] = params[:ns] ? params[:ns].to_sym : nil
    get_sugar 
    if params[:identifier] != 'null'
      if params[:newresidue] == 'prune'
        prune_sugar
      else
        grow_sugar
      end
    else
      if params[:newresidue] == 'prune'
        @sugar = nil
      else
        get_sugar_from_residue
      end
    end
    draw_sugar
    render :action => 'build_sugar', :layout => false, :content_type => Mime::XHTML
  end

  def get_sugar_from_residue
    if params[:newresidue] != nil && params[:newresidue] != ''
      @sugar = SugarHelper.CreateSugar('',params[:ns])
      @sugar.root = @sugar.monosaccharide_factory(params[:newresidue])
      SugarHelper.MakeRenderable(@sugar)
      SugarHelper.SetWriterType(@sugar,params[:ns])
    end
  end
  

  def get_sugar
    if params[:seq] != nil && params[:seq] != ''
      @sugar = SugarHelper.CreateRenderableSugar(params[:seq],params[:ns])
      SugarHelper.SetWriterType(@sugar,params[:ns])
    end
  end

  def generate_prototypes
    @prototypes = NamespacedMonosaccharide.Supported_Residues.collect { |res|
      new_res = Monosaccharide.Factory(NamespacedMonosaccharide,res)
      (! params[:ns]) || new_res.alternate_name?(params[:ns]) ? SugarHelper.CreateRenderableSugar(new_res.name(:ic),:ic) : nil
    }.reject { |res| 
      res && res.name(:ic) == 'Nil'
    }.compact
  end

  def prune_sugar
    linkagepath = params[:identifier] ? params[:identifier].split(',').collect { |s| s.to_i } : nil
    target_residue = @sugar.find_residue_by_linkage_path(linkagepath)
    if target_residue.parent != nil
      target_residue.parent.remove_child(target_residue)
    else
      @sugar = nil
    end
  end

  def grow_sugar
    linkagepath = params[:identifier] ? params[:identifier].split(',').collect { |s| s.to_i } : nil
    target_residue = @sugar.find_residue_by_linkage_path(linkagepath)
    new_residue = @sugar.monosaccharide_factory(params[:newresidue])
    link = @sugar.linkage_factory()
    link.second_position = params[:firstposn].to_i
    link.first_position = params[:secondposn].to_i
    if (new_residue.name(:ic) == 'NeuAc' || new_residue.name(:ic) == 'NeuGc' )
      link.first_position = 2
    end
    target_residue.add_child(new_residue,link)
    new_residue.anomer = params[:anomer]
    Renderable::Sugar.extend_object(@sugar)
  end

  def draw_sugar
    return unless @sugar
    targets = Element.new('svg:g')
    @sugar.overlays << targets
    @sugar.residue_composition.each { |res|
      res.callbacks.push( lambda { |element|
        xcenter = -1*(res.center[:x]) 
        ycenter = -1*(res.center[:y])
        target = Element.new('svg:circle')
        target.add_attributes({ 'cx' => xcenter.to_s, 'cy' => ycenter.to_s, 'r'=> '100', 'fill' => 'red', 'style' => 'opacity:0.01' })
        target.add_attribute('linkid',@sugar.get_attachment_point_path_to_root(res).reverse.join(','))
        target.add_attribute('class','drop_target')
        targets.add_element(target)
      })
    }

    if params[:scale] && (params[:scale].to_f > 0)
      @scale = params[:scale].to_f
    else
      @scale = :auto
    end
  end
end
