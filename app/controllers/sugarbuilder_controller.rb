class SugarbuilderController < ApplicationController
  layout 'standard'
  
  def index
    params[:ns] = params[:ns] ? params[:ns].to_sym : nil
    generate_prototypes
    if params[:seq]
      get_sugar
      draw_sugar
    else
      render :action => 'build_sugar_index'
    end
  end

  def pallette
    generate_prototypes
    render :action => 'pallette', :layout => false, :content_type => Mime::XML
  end

  def build_sugar
    get_sugar    
    if params[:identifier] != 'null'
      if params[:newresidue] == 'prune'
        prune_sugar
      else
        grow_sugar
      end
    end
    draw_sugar
    render :action => 'build_sugar', :layout => false, :content_type => Mime::XHTML
  end

  def get_sugar
    if params[:seq] != nil
      @sugar = SugarHelper.CreateRenderableSugar(params[:seq],params[:ns])
    end
  end

  def generate_prototypes
    @prototypes = NamespacedMonosaccharide.Supported_Residues.collect { |res|
      new_res = Monosaccharide.Factory(NamespacedMonosaccharide,res)
      SugarHelper.CreateRenderableSugar(new_res.name(:ic),:ic)
    }
  end

  def prune_sugar
    linkagepath = params[:identifier] ? params[:identifier].split(',').collect { |s| s.to_i } : nil
    target_residue = @sugar.find_residue_by_linkage_path(linkagepath)
    if target_residue.parent != nil
      target_residue.parent.remove_child(target_residue)
    end    
  end

  def grow_sugar
    linkagepath = params[:identifier] ? params[:identifier].split(',').collect { |s| s.to_i } : nil
    target_residue = @sugar.find_residue_by_linkage_path(linkagepath)
    new_residue = @sugar.monosaccharide_factory(params[:newresidue])
    target_residue.add_child(new_residue,@sugar.linkage_factory({:from => params[:firstposn].to_i, :to => params[:secondposn].to_i}))
    new_residue.anomer = params[:anomer]
    Renderable::Sugar.extend_object(@sugar)
  end

  def draw_sugar
    targets = Element.new('svg:g')
    @sugar.overlays << targets
    @sugar.residue_composition.each { |res|
      res.callbacks.push( lambda { |element|
        xcenter = -1*(res.centre[:x]) 
        ycenter = -1*(res.centre[:y])
        target = Element.new('svg:circle')
        target.add_attributes({ 'cx' => xcenter, 'cy' => ycenter, 'r'=> 100, 'fill' => 'red', 'style' => 'opacity:0.01' })
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
