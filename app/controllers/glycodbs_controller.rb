require 'lax_residue_names'

module HitCounter
  attr_accessor :hits
  def hits
    @hits ||= 0
  end  
end

class Monosaccharide
  include HitCounter
end

MATCH_BLOCK = lambda { |residue,other_res,matched_yet|
  residue.equals?(other_res) && ((! matched_yet && ((residue.hits += 1) > -1)) || true )
}

class GlycodbsController < ApplicationController
  layout 'standard'
  
  # GET /glycodbs
  # GET /glycodbs.xml
  def index
    @glycodbs = Glycodb.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @glycodbs }
    end
  end

  # GET /glycodbs/1
  # GET /glycodbs/1.xml
  def show
    @glycodb = Glycodb.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @glycodb }
    end
  end

  # GET /glycodbs/new
  # GET /glycodbs/new.xml
  def new
    @glycodb = Glycodb.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @glycodb }
    end
  end

  # GET /glycodbs/1/edit
  def edit
    @glycodb = Glycodb.find(params[:id])
  end

  # POST /glycodbs
  # POST /glycodbs.xml
  def create
    @glycodb = Glycodb.new(params[:glycodb])

    respond_to do |format|
      if @glycodb.save
        flash[:notice] = 'Glycodb was successfully created.'
        format.html { redirect_to(@glycodb) }
        format.xml  { render :xml => @glycodb, :status => :created, :location => @glycodb }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @glycodb.errors, :status => :unprocessable_entity }
      end
    end
  end

  def tag
    @glycodb = Glycodb.find(params[:id])
    new_tag = params[:tag]    
    my_tags = (@glycodb.tags || '').split(',').reject { |tag| tag == new_tag }
    my_tags << new_tag
    @glycodb.tags = my_tags.join(',')
    respond_to do |format|
      if @glycodb.save
        format.txt { render :text => @glycodb.tags }
        format.html { render :action => 'show' }
      end
    end
  end

  def tags
    @tags = Glycodb.All_Tags
    @defined_tissues = Enzymeinfo.All_Tissues
    respond_to do |format|
        format.txt { render :text => @tags.join(',') }
        format.html { render :action => 'list_tags' }
    end
  end

  def untag
    @glycodb = Glycodb.find(params[:id])
    new_tag = params[:tag]    
    my_tags = (@glycodb.tags || '').split(',').reject { |tag| tag == new_tag }
    @glycodb.tags = my_tags.join(',')
    respond_to do |format|
      if @glycodb.save
        format.txt { render :text => @glycodb.tags }
        format.html { render :action => 'show' }
      end
    end
  end

  # PUT /glycodbs/1
  # PUT /glycodbs/1.xml
  def update
    @glycodb = Glycodb.find(params[:id])

    respond_to do |format|
      if @glycodb.update_attributes(params[:glycodb])
        flash[:notice] = 'Glycodb was successfully updated.'
        format.html { redirect_to(@glycodb) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @glycodb.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /glycodbs/1
  # DELETE /glycodbs/1.xml
  def destroy
    @glycodb = Glycodb.find(params[:id])
    @glycodb.destroy

    respond_to do |format|
      format.html { redirect_to(glycodbs_url) }
      format.xml  { head :ok }
    end
  end

  def tissue
    @glycodbs = Glycodb.easyfind(:keywords => params[:id], :fieldnames => ['SYSTEM','DIVISION1','DIVISION2','DIVISION3','DIVISION4'])
    @glycodbs.reject! { |glycodb| glycodb.SPECIES != 'HOMO SAPIENS'}
  end

  def coverage_for_tag
    @sugars = execute_coverage_for_tag(params[:id])
    render :action => 'coverage', :content_type => Mime::XHTML
  end

  def execute_coverage_for_tag(tags)
    individual_sugars = Glycodb.easyfind(:keywords => tags.split(','), :fieldnames => ['tags']).collect { |entry|
      my_seq = entry.GLYCAN_ST.gsub(/\+.*/,'').gsub(/\(\?/,'(u')
      my_sug = nil
      begin
        my_sug = SugarHelper.CreateMultiSugar(my_seq,:ic).get_unique_sugar        
      rescue Exception => e
      end      
      my_sug
    }.compact
    sugar_sets = 
      [ individual_sugars.reject { |sug| sug.root.name(:ic) != 'GlcNAc'},
        individual_sugars.reject { |sug| sug.root.name(:ic) != 'GalNAc'},
        individual_sugars.reject { |sug| sug.root.name(:ic) != 'Gal'},
        individual_sugars.reject { |sug| sug.root.name(:ic) != 'Glc'}
      ].compact
    return sugar_sets.collect { |sugar_set|
      sugar = sugar_set.shift
      def sugar.add_structure_count
        @struct_count = (@struct_count || 0) + 1
      end
      def sugar.structure_count
        @struct_count
      end
      
      if sugar == nil
        next
      end
      
      begin
        sugar_set.each { |sug|
          sugar.union!(sug,&MATCH_BLOCK)
          sugar.add_structure_count
        }
        SugarHelper.MakeRenderable(sugar)        
      rescue Exception => e
        logger.info(e)
      end
      
    
      coverage_finder = EnzymeCoverageController.new()
      coverage_finder.sugar = sugar
      sugar.root.anomer = 'u'
      def coverage_finder.do_stuff
        execute_pathways_and_markup()
        return [@chains,@valid_residues,@invalid_residues]
      end
      
      chains,valid_residues,invalid_residues = coverage_finder.do_stuff
      
      all_gals = sugar.residue_composition.select { |r| r.name(:ic) == 'Gal' && r.parent && r.parent.name(:ic) == 'GlcNAc' }
      type_i = all_gals.select { |r| r.paired_residue_position == 3 }
      type_ii = all_gals.select { |r| r.paired_residue_position == 4 }
      all_glcnacs = sugar.residue_composition.select { |r| r.name(:ic) == 'GlcNAc' && r.parent && r.parent.name(:ic) == 'Gal' }
      type_i_glcnac = all_glcnacs.select { |r| (r.paired_residue_position == 3) && r.parent.paired_residue_position == 3 }
      type_ii_glcnac = all_glcnacs.select { |r| (r.paired_residue_position == 3) && r.parent.paired_residue_position == 4 }
      branching = all_glcnacs.select { |r| r.paired_residue_position == 6 }
      
      sugar.callbacks << lambda { |sug_root,renderer|
        renderer.chain_background_width = 20
        renderer.chain_background_padding = 65
#        renderer.render_valid_decorations(sugar,valid_residues.uniq)
#        renderer.render_invalid_decorations(sugar,invalid_residues.uniq)
        renderer.render_simplified_chains(sugar,[type_i+type_i_glcnac],'sugar_chain sugar_chain_type_i','#FFEFD8')
        renderer.render_simplified_chains(sugar,[type_ii+type_ii_glcnac],'sugar_chain sugar_chain_type_ii','#C9F6C6')
        renderer.render_simplified_chains(sugar,[branching],'sugar_chain sugar_chain_branching','#C5D3EF')
      }
      
      sugar.residue_composition.each { |r|
        if ! r.is_valid? && r.parent && r.parent.is_valid?
          r.parent.remove_child(r)
        end
      }


      targets = Element.new('svg:g')
      targets.add_attributes({'class' => 'hits_overlay', 'display' => 'none'})
      sugar.overlays << targets
      sugar.residue_composition.each { |residue|
        residue.hits += 1
        residue.callbacks.push( lambda { |element|
          xcenter = -1*(residue.centre[:x]) 
          ycenter = -1*(residue.centre[:y])
          label = Element.new('svg:text')
          label.add_attributes({'x' => xcenter, 'y' => ycenter, 'text-anchor' => 'middle', 'style' => 'dominant-baseline: middle;','font-size' => '40px' })
          label.text = residue.hits
          label_back = Element.new('svg:circle')
          label_back.add_attributes({'cx' => xcenter, 'cy' => ycenter, 'r' => '40px', 'fill' => '#ffffff', 'stroke-width' => '2px', 'stroke' => '#0000ff'})

          targets.add_element(label_back)
          targets.add_element(label)
          
        })
      }

      gene_tissue = (tags.split(',').collect { |tag| tag.gsub!(/anat\:/,'') }.compact.first || 'nil').humanize
      coverage_finder.markup_linkages(coverage_finder.execute_genecoverage(gene_tissue))
      sugar
    }.compact
  end

end
