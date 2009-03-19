require 'lax_residue_names'

module HitCounter
  attr_accessor :hits
  def hits
    @hits ||= 1
  end 
  def seen_structures
    @seen_structs ||= []
    @seen_structs
  end

end

class Monosaccharide
  include HitCounter
end

MATCH_BLOCK = lambda { |residue,other_res,matched_yet|
  residue.equals?(other_res) && ((! matched_yet && ((residue.hits += 1) > -1) && ( residue.seen_structures << other_res.seen_structures[0] != nil )) || true )
}

class GlycodbsController < ApplicationController
  layout 'standard'
  
  module SummaryStats
    def add_structure_count
      @struct_count = (@struct_count || 0) + 1
    end
    def structure_count
      @struct_count
    end
    
    def branch_points_count=(new_bc)
      @branch_points = new_bc
    end
    
    def branch_points_count
      @branch_points || { 0 => 0 }
    end
    
    def branch_point_totals
      @branch_point_totals || {}
    end
    
    def branch_point_totals=(totals)
      @branch_point_totals = totals
    end
  end
  
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
    @glycodbs = Glycodb.easyfind(:keywords => params[:id], :fieldnames => ['SYSTEM','DIVISION1','DIVISION2','DIVISION3','DIVISION4','SWISS_PROT'])
    @glycodbs.reject! { |glycodb| glycodb.SPECIES != 'HOMO SAPIENS'}
#    @glycodbs.reject! { |glycodb| glycodb.SPECIES != 'MUS MUSCULUS'}
  end

  def proteins
    @glycodbs = Glycodb.find(:all,:conditions => ["species = 'HOMO SAPIENS' and protein_name != ''"],:select => 'SWISS_PROT,PROTEIN_NAME,SPECIES,count(distinct SYSTEM) as system_count,count(*) as record_count',:group => 'protein_name', :order => 'record_count')
    @glycodbs.reject! { |glycodb| glycodb.SPECIES != 'HOMO SAPIENS'}    
  end

  def coverage_for_taxonomy
    tagged_sugars = Glycodb.find(:all, :conditions => ["species = ?", params[:id]])
    tagged_sugars.collect! { |g| g.GLYCAN_ST }.uniq
    @sugars = execute_coverage_for_sequence_set(tagged_sugars,params[:dont_prune] ? false : true)
    @key_sugar = generate_key_sugar()
    render :action => 'coverage', :content_type => Mime::XHTML
  end

  def coverage_for_tag
    all_tags = params[:id].split(',')
    tagged_sugars = Glycodb.easyfind(:keywords => all_tags, :fieldnames => ['tags'])
    aa_sites = tagged_sugars.collect { |g| (g.GLYCO_AA_SITE || '').split(/\s*,\s*/) }.flatten.uniq
    tagged_sugars.collect! { |g| g.GLYCAN_ST }
    @sugars = execute_coverage_for_sequence_set(tagged_sugars,params[:dont_prune] ? false : true)
    @sugars.each { |sugar| 
      coverage_finder = EnzymeCoverageController.new()
      coverage_finder.sugar = sugar
      sugar.root.anomer = 'u'
      gene_tissue = (all_tags.collect { |tag| tag.gsub!(/anat\:/,'') }.compact.first || 'nil').humanize
      coverage_finder.markup_linkages(coverage_finder.execute_genecoverage(gene_tissue))
    }
    if params[:id] =~ /prot:(.+),?/
      @aa_sites = aa_sites
    else
      @aa_sites = ''
    end
    @key_sugar = generate_key_sugar()
    render :action => 'coverage', :content_type => Mime::XHTML
  end

  def compare_tag_summary
    tagged_sugars_1 = Glycodb.easyfind(:keywords => params[:tags1].split(','), :fieldnames => ['tags'])
    tagged_sugars_2 = Glycodb.easyfind(:keywords => params[:tags2].split(','), :fieldnames => ['tags'])
    tagged_sugars_1.collect! { |g| g.GLYCAN_ST }
    tagged_sugars_2.collect! { |g| g.GLYCAN_ST }

    sugars_tag1 = execute_coverage_for_sequence_set(tagged_sugars_1)
    sugars_tag2 = execute_coverage_for_sequence_set(tagged_sugars_2)
    sugars_tag1.each { |sug| sug.name = params[:tags1] }
    sugars_tag2.each { |sug| sug.name = params[:tags2] }
    
    @sugars = ['GlcNAc','GalNAc','Gal','Glc'].collect { |a_name|
      [sugars_tag1.select { |sug| sug.root.name(:ic) == a_name }.first,
      sugars_tag2.select { |sug| sug.root.name(:ic) == a_name }.first ]
    }.compact.reject { |sugs|
      sugs.compact.size == 0
    }
    
    @sorted_branch_points = []

    max_branch_point_size = 0
    
    @sugars.each { |sugset|
      all_branch_points = sugset.compact.collect { |sug|
        all_keys = sug.branch_point_totals.keys
        if all_keys.size > max_branch_point_size
          max_branch_point_size = all_keys.size
        end
        all_keys
      }.flatten
      labels = ('S'..'Z').to_a.reverse
      all_branch_points.sort_by { |bp| bp.sort_key }.group_by { |bp|
        bp.sort_key
      }.each { |sort_key,points|
        label = labels.shift
        points.each { |bp|
          bp.branch_label = label
          @sorted_branch_points << bp
        }        
      }
    }
    
    @max_branch_point_size = max_branch_point_size
    
    @key_sugar = generate_key_sugar()
    render :action => 'compare_tag_summary', :content_type => Mime::XHTML
  end
  
  def generate_key_sugar
      key_sug = SugarHelper.CreateMultiSugar('NeuAc(a2-6)[GalNAc(a1-3)]Gal(b1-3)[Fuc(a1-4)]GlcNAc(b1-3)[Fuc(a1-3)[Fuc(a1-2)[NeuAc(a2-3)][Gal(a1-3)]Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)]GlcNAc(b1-6)]Gal(b1-3)[Fuc(a1-6)]GlcNAc',:ic)

      SugarHelper.MakeRenderable(key_sug)        
      
      all_gals = key_sug.residue_composition.select { |r| r.name(:ic) == 'Gal' && r.parent && r.parent.name(:ic) == 'GlcNAc' }
      type_i = all_gals.select { |r| r.paired_residue_position == 3 }
      type_ii = all_gals.select { |r| r.paired_residue_position == 4 }
      all_glcnacs = key_sug.residue_composition.select { |r| r.name(:ic) == 'GlcNAc' && r.parent && r.parent.name(:ic) == 'Gal' }
      type_i_glcnac = all_glcnacs.select { |r| (r.paired_residue_position == 3) && r.parent.paired_residue_position == 3 }
      type_ii_glcnac = all_glcnacs.select { |r| (r.paired_residue_position == 3) && r.parent.paired_residue_position == 4 }
      branching = all_glcnacs.select { |r| r.paired_residue_position == 6 }

      labelled_stuff =
      [ key_sug.find_residue_by_linkage_path([3,6,4,3,4]), # Neuac a2-3 sialylation and Fuc(a1-2)
        key_sug.find_residue_by_linkage_path([3,3,3]), # Neuac a2-6 sialylation
        key_sug.find_residue_by_linkage_path([3,3]).linkage_at_position, # Type 1 chain
        key_sug.find_residue_by_linkage_path([3,6,4]).linkage_at_position, # Type 2 chain
        key_sug.find_residue_by_linkage_path([3,6]).linkage_at_position, # 6-Branching
        key_sug.find_residue_by_linkage_path([3,3]), # Fuc(a1-4)
        key_sug.find_residue_by_linkage_path([3,6]), # Fuc(a1-3)
        key_sug.find_residue_by_linkage_path([]) # Fuc(a1-6)
      ]

      labelled_stuff = labelled_stuff.zip(('a'..'z').to_a[0..(labelled_stuff.size-1)])


      key_sug.callbacks << lambda { |sug_root,renderer|
        renderer.chain_background_width = 20
        renderer.chain_background_padding = 65
        renderer.render_simplified_chains(key_sug,[type_i+type_i_glcnac],'sugar_chain sugar_chain_type_i','#FFEFD8')
        renderer.render_simplified_chains(key_sug,[type_ii+type_ii_glcnac],'sugar_chain sugar_chain_type_ii','#C9F6C6')
        renderer.render_simplified_chains(key_sug,[branching],'sugar_chain sugar_chain_branching','#C5D3EF')
        labelled_stuff.each { |thing,lab|
          next unless thing
          position = :center
          ratio = 0.2
          if thing.kind_of?(Monosaccharide)
            position = :bottom_right
            ratio = 0.5
          end
          thing.callbacks << renderer.callback_make_object_badge(key_sug.overlays[-1],thing,lab,ratio,position,'#222222')
        }
      }
      
      
      key_sug.residue_composition.each { |r|
        def r.hits
          1
        end
      }
      key_sug
  end

  def markup_hits(sugar)    
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
  end

  def execute_coverage_for_sequence_set(sequences,prune_structure=true)
    seq_counter = 0
    individual_sugars = sequences.collect { |seq|
      seq_counter += 1
      my_seq = seq.gsub(/\+.*/,'').gsub(/\(\?/,'(u')
      my_seq.gsub!(/\(-/,'(u1-')
      my_sug = nil
      begin
        my_sug = SugarHelper.CreateMultiSugar(my_seq,:ic).get_unique_sugar        
        my_sug.residue_composition.each { |res|
          res.seen_structures << seq_counter
        }
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
      
      if sugar == nil
        next
      end

      sugar = sugar.extend(SummaryStats)
      
      # Branch point comparison
      # For each branch point for the new sugar collect
      #    get the unambiguous path to root for the branch point
      #    find the analgous residue in the target sugar
      # end
      # Update the counter hash for each branch point
      # counts[a_branch_point][co-occuring_branch_point] += 1
      # counts[a_branch_point][self] += 1
      #
      # Profit!
      
      branch_points_totals = []
      
      sugar_set.each { |sug|
        branch_points = sug.branch_points
        sugar.union!(sug,&MATCH_BLOCK)
        branch_points = branch_points.collect { |r| sugar.find_residue_by_unambiguous_path(sug.get_unambiguous_path_to_root(r).reverse) }
        branch_points_totals << branch_points
        sugar.add_structure_count
      }

      branch_totals_by_point = {}
      branch_points_totals.each { |branching_rec|
        branching_rec.each { |point|
          branch_totals_by_point[point] ||= {}
          branching_rec.each { |other_point|
            branch_totals_by_point[point][other_point] ||= 0
            branch_totals_by_point[point][other_point] += 1            
          }
        }
      }

      sugar.branch_point_totals = branch_totals_by_point

      SugarHelper.MakeRenderable(sugar)        
      
    
      coverage_finder = EnzymeCoverageController.new()
      coverage_finder.sugar = sugar
      sugar.root.anomer = 'u'
      
      coverage_finder.execute_pathways_and_markup

      if prune_structure
        sugar.residue_composition.each { |r|
          if ! r.is_valid? && r.parent && r.parent.is_valid?
            r.parent.remove_child(r)
          end
        }
      end
      
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
      
      sugar_residues = sugar.residue_composition
      branch_totals_by_point.keys.each { |bp|
        unless sugar_residues.include? bp
            branch_totals_by_point.delete(bp)
        end
      }
      all_ids = branch_totals_by_point.keys.collect { |bp|
        bp.seen_structures
      }.flatten.sort

      zero_count = sugar.root.hits
      sizes = {}
      all_id_sizes = all_ids.group_by { |i| i }.collect { |arr| arr[1].size }.group_by { |i| i }.each { |b_num,scount|
        sizes[b_num] = scount.size
        zero_count -= scount.size
      }
      sizes[0] = zero_count
      sugar.branch_points_count = sizes

      labels = ('A'..'Z').to_a.reverse
      branch_totals_by_point.keys.each { |bp|
        sort_key = sugar.depth(bp).to_s+'|'+sugar.get_unambiguous_path_to_root(bp).collect {|path| path[:residue].paired_residue_position.to_s+path[:residue].name(:ic) }.join(',')
        def bp.sort_key=(key)
          @sort_key = key
        end
        def bp.sort_key
          @sort_key
        end
        bp.sort_key = sort_key
      }
      branch_totals_by_point.keys.sort_by { |bp|
        bp.sort_key
      }.each { |bp|
        branch_label_text = labels.shift
        def bp.branch_label
          @branch_label
        end
        def bp.branch_label=(new_label)
         @branch_label = new_label
        end
        bp.branch_label = branch_label_text
        sugar.callbacks << lambda { |sug_root,renderer|
          renderer.render_text_residue_label(sugar,bp,bp.branch_label)
        }
      }

      sugar
    }.compact
  end
end
