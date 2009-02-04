require 'SugarHelper'


class DisaccharidesController < ApplicationController
  layout 'standard'

  class GlobalReaction < Reaction
  end
  
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @disaccharides_pages, @disaccharides = paginate :disaccharides, :per_page => 10
    @disaccharides.each { |di|
      begin
        di.sugar = SugarHelper.CreateSugarFromDisaccharide(di)        
      rescue Exception => e
        di.sugar = nil        
      end
    }
  end

  def matrix
    @disaccharides = Disaccharide.find_by_sql("select residuedelta, count(distinct structure_id_glycomedb) as count from disaccharides group by residuedelta" )
    residuedeltas = @disaccharides.collect { |d| d.residuedelta }
    @reactions = Reaction.find(:all).delete_if { |r| ! r.has_enzyme? || residuedeltas.include?(r.residuedelta) }
    
    generate_matrix
    respond_to do |wants|
      wants.html { render }
      wants.txt { render :layout => false }
    end    
  end

  def generate_matrix
  	donor_string_hash = Hash.new()
  	donor_hash = Hash.new() {|h,k| h[k] = Hash.new() {|h2,k2| h2[k2] = Array.new() } }

    logger.info("Disaccharide count pre-tolerance #{@disaccharides.size}")

  	@disaccahrides = @disaccharides.reject! { |di| di.residuedelta == nil || di.evidence_count < (params[:threshold].to_i || 0) } 

    logger.info("Disaccharide count post-tolerance #{@disaccharides.size}")

    residuedeltas = @disaccharides.collect { |d| d.residuedelta }

    temp_schema = nil

    if ActiveRecord::Base::connection.respond_to?(:schema_search_path)
      temp_schema = ActiveRecord::Base::connection.schema_search_path
      ActiveRecord::Base::connection.schema_search_path = 'public'
    end
    
    @all_genes = Reaction.find(:all).delete_if { |r| ! r.has_enzyme? || ! residuedeltas.include?(r.residuedelta) }.collect {|r| r.genes.collect {|g| g.genename } }.flatten.sort.uniq

    if ActiveRecord::Base::connection.respond_to?(:schema_search_path)
      ActiveRecord::Base::connection.schema_search_path = temp_schema
    end
  	for reaction in @disaccharides + @reactions
  		donor = nil
  		substrate = nil
  		begin
  			donor = reaction.donor
  			substrate = reaction.substrate_residue
  		rescue Exception => e
  			next
  		end

  		link = donor.linkage_at_position
  		reaction_linkage = reaction.linkage

  	  next unless params[:use_unknowns] || ( donor.anomer != 'u' && link.first_position != 0 && link.second_position != 0 )

  		donor_hash[donor.name][substrate.name] << reaction_linkage
  		donor_string_hash[donor.name] = donor
  		donor_string_hash[substrate.name] = substrate
  		def reaction_linkage.original_reaction 
  			return @reaction
  		end
  		def reaction_linkage.original_reaction=(something)
  			@reaction = something
  		end
  		reaction_linkage.original_reaction = reaction
  	end

  	@donor_string_hash = donor_string_hash
  	@donor_hash = donor_hash
  end

  def show
    @disaccharides = Disaccharide.find(params[:id])
  end

  def new
    @disaccharides = Disaccharide.new
  end

  def create
    @disaccharides = Disaccharide.new(params[:disaccharides])
    if @disaccharides.save
      flash[:notice] = 'Disaccharides was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @disaccharides = Disaccharide.find(params[:id])
  end

  def update
    @disaccharides = Disaccharide.find(params[:id])
    if @disaccharides.update_attributes(params[:disaccharides])
      flash[:notice] = 'Disaccharides was successfully updated.'
      redirect_to :action => 'show', :id => @disaccharides
    else
      render :action => 'edit'
    end
  end

  def destroy
    Disaccharide.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
