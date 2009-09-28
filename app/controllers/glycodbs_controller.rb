require 'lax_residue_names'

class GlycodbsController < StructureSummaryController
  layout 'standard'
  caches_page :coverage_for_taxonomy, :coverage_for_tag
  self.page_cache_extension = '.xhtml'
  
  def home
  end
  
  def help
  end
  
  def help_output
  end
  
  def help_contact
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

    if ENV['RAILS_ENV'] == 'production'
      @sugars = @sugars.select{ |sug| ['GlcNAc','GalNAc','Gal','Glc'].include?(sug.root.name(:ic)) && sug.size > 0 }
    end

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
        all_keys = sug.collected_statistics[:branch_totals_by_point].keys
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
    render :action => 'compare_tag_summary', :content_type => Mime::XHTML
  end

  def perform_pruning(sugar)
    return if params[:dont_prune]
    sugar.residue_composition.each { |r|
      next unless r.parent
      if ! r.is_valid? && r.parent.is_valid?
        r.parent.remove_child(r)
      elsif r.get_counter(:ref).uniq.size < 2
        r.parent.remove_child(r)
      end
    }
  end

  def markup_sugarset(sugarset)
    sugarset.each { |sugar|
      markup_chains(sugar)
      markup_branch_points(sugar)
      markup_reference_counts(sugar)        
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
          if my_sug != last_sug
            res.extend(HitCounter)
          end
          
          res.initialise_counter(:id)
          res.get_counter(:id)
          res.increment_counter(glycodb.id,:id)

          res.initialise_counter(:ref)
          res.get_counter(:ref)
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

    self.statistic_collectors = [branch_collector,fuc_collector,neuac_collector]

    sugarset = execute_summary_for_sugars(individual_sugars,prune_structure)

    markup_sugarset(sugarset)
    
    sugarset
  end
  
end
