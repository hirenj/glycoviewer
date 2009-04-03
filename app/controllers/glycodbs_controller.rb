require 'lax_residue_names'

module HitCounter
  attr_accessor :hits
  
  def hits
    get_counter(:id).size
  end 
  def seen_structures
    get_counter(:id)
  end
  
  def counter_keys
    initialise_counter
    return @counters.keys
  end

  def reset_counters
    @counters = nil
    initialise_counter
  end

  def initialise_counter(id_key=:id)
    @counters = @counters || Hash.new() { |h,k| h[k] = Array.new() }
  end
  
  def increment_counter(value,id_key=:id)
    @counters[id_key] << value
  end
  
  def get_counter(id_key=:id)
    initialise_counter(id_key)
    @counters[id_key]
  end
  
  def merge_counter(other_residue,id_key=:id)
    @counters[id_key] += other_residue.get_counter(id_key)
    @counters[id_key].uniq!
  end
  
  MATCH_BLOCK = lambda { |residue,other_res,matched_yet|
    if residue.equals?(other_res)
      if ! matched_yet
        residue.counter_keys.each { |key|
          residue.merge_counter(other_res,key)
        }
      end
      true
    else
      false
    end
  }
  
end

class Monosaccharide
  include HitCounter
end


class GlycodbsController < ApplicationController
  layout 'standard'
  caches_page :coverage_for_taxonomy
  self.page_cache_extension = '.xhtml'
  
  module SummaryStats

    def reference_count
      self.residue_composition.collect { |r|
        r.get_counter(:ref)
      }.flatten.uniq.size
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
    
    attr_accessor :sialic_capping_averages
    
    def sialic_capping_averages
      @sialic_capping_averages = @sialic_capping_averages || []
      @sialic_capping_averages
    end

    attr_accessor :fucose_capping_averages
    
    def fucose_capping_averages
      @fucose_capping_averages = @fucose_capping_averages || []
      @fucose_capping_averages
    end
    
    attr_accessor :terminal_fucoses
    attr_accessor :terminal_sialics
    
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
#    tagged_sugars.collect! { |g| g.GLYCAN_ST }.uniq
    @sugars = execute_coverage_for_sequence_set(tagged_sugars,params[:dont_prune] ? false : true)
    @key_sugar = generate_key_sugar()
    render :action => 'coverage', :content_type => Mime::XHTML
  end

  def coverage_for_tag
    all_tags = params[:id].split(',')
    tagged_sugars = Glycodb.easyfind(:keywords => all_tags, :fieldnames => ['tags'])
    aa_sites = tagged_sugars.collect { |g| (g.GLYCO_AA_SITE || '').split(/\s*,\s*/) }.flatten.uniq
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
    # tagged_sugars_1.collect! { |g| g.GLYCAN_ST }
    # tagged_sugars_2.collect! { |g| g.GLYCAN_ST }

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
        xcenter = -1*(residue.center[:x]) 
        ycenter = -1*(residue.center[:y])
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
    
    last_sug = nil
    last_seq = nil
    
    individual_sugars = sequences.select { |glycodb|
      seq = glycodb.GLYCAN_ST
      if seq =~ /\?\)/ || seq =~ /u[1,2]/ || seq =~ /\?[1,2]/
        false
      else
        true
      end
    }.sort_by { |g| g.GLYCAN_ST }.collect { |glycodb|
      seq = glycodb.GLYCAN_ST
      seq_counter += 1
      my_seq = seq.gsub(/\+.*/,'').gsub(/\(\?/,'(u')
      my_seq.gsub!(/\(-/,'(u1-')
      my_sug = nil
      begin
        if last_seq != nil && my_seq == last_seq
          my_sug = last_sug
        else
          my_sug = SugarHelper.CreateMultiSugar(my_seq,:ic).get_unique_sugar
        end        
        my_sug.residue_composition.each { |res|

          res.initialise_counter(:id)
          res.increment_counter(glycodb.id,:id)
          
          res.initialise_counter(:ref)
          glycodb.references.split(',').each { |ref|
            res.increment_counter(ref,:ref)
          }
        }
        
        next unless last_seq != my_seq
        
        last_sug = my_sug
        last_seq = my_seq

      rescue Exception => e
        last_seq = nil
        last_sug = nil
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
      
      terminal_fucoses = []
      terminal_sialics = []
      
      ([sugar]+sugar_set).each { |sug|
        branch_points = sug.branch_points
        if sug != sugar
          sug.extend(CachingSugar)
          sugar.union!(sug,&HitCounter::MATCH_BLOCK)
        end
        branch_points = branch_points.collect { |r| sugar.find_residue_by_unambiguous_path(sug.get_unambiguous_path_to_root(r).reverse) }
        branch_points_totals << branch_points
        
        all_leaves = sug.leaves
        fuc_leaves = all_leaves.select { |r| r.name(:ic) == 'Fuc' && r.parent && r.parent.name(:ic) == 'Gal' }
        neuac_leaves = all_leaves.select { |r| r.name(:ic) == 'NeuAc' }
        gal_leaves = all_leaves.select { |r|
          ['Gal','GalNAc'].include?(r.name(:ic)) && r.anomer != 'a'          
        }
        
        if fuc_leaves.size > 0
          sugar.fucose_capping_averages << fuc_leaves.size.to_f / (gal_leaves.size + fuc_leaves.size)
        end
        if neuac_leaves.size > 0
          sugar.sialic_capping_averages << neuac_leaves.size.to_f / (gal_leaves.size + neuac_leaves.size)
        end

        fuc_leaves = all_leaves.select { |r| r.name(:ic) == 'Fuc' }
        
        fuc_leaves.select { |fuc| fuc.siblings.reject { |r| r.anomer == 'a' && ['Gal','GalNAc'].include?(r.name(:ic))}.size == 0 }.each { |fuc|
          terminal_fucoses << sugar.find_residue_by_unambiguous_path(sug.get_unambiguous_path_to_root(fuc).reverse)
        }

        neuac_leaves.select { |neuac| neuac.siblings.reject { |r| ['GalNAc'].include?(r.name(:ic)) }.size == 0 }.each { |neuac|
          terminal_sialics << sugar.find_residue_by_unambiguous_path(sug.get_unambiguous_path_to_root(neuac).reverse)
        }
        
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
      
      sugar.extend(CachingSugar)
      
      coverage_finder.execute_pathways_and_markup


      if prune_structure
        sugar.residue_composition.each { |r|
          next unless r.parent
          if ! r.is_valid? && r.parent.is_valid?
            r.parent.remove_child(r)
          elsif r.get_counter(:ref).uniq.size < 2
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

      terminal_sialics.each { |r|
        unless sugar_residues.include? r
            terminal_sialics.delete(r)
        end        
      }

      terminal_fucoses.each { |r|
        unless sugar_residues.include? r
            terminal_fucoses.delete(r)
        end        
      }
      
      sugar.terminal_sialics = terminal_sialics
      sugar.terminal_fucoses = terminal_fucoses
      
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
          renderer.render_text_residue_label(sugar,bp,bp.branch_label,:top_right)
          renderer.render_text_residue_label(sugar,bp,bp.hits,:bottom_right)
        }
        bp.callbacks << lambda { |element|
          render_text_residue_label(sugar,bp,bp.get_counter(:ref).uniq.size,:bottom_left)
        }
      }
      sugar.residue_composition.select { |r|
        sugar.residue_height(r) <= 1 && r.name(:ic) == 'Gal' && r.anomer == 'b'
      }.each { |r|
        r.callbacks << lambda { |element|
          render_text_residue_label(sugar,r,r.get_counter(:ref).uniq.size,:bottom_left)
        }
      }
      
      sugar
    }.compact
  end
end
