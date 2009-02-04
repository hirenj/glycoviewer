class GeneinfosController < ApplicationController
  layout 'standard'
  
  def index
    respond_to do |wants|
      wants.html { 
        list
        render :action => 'list'
      }
      wants.xml  { 
        list_all
        render :xml => @geneinfos.to_xml
      }
    end
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list_all
    @geneinfos = Geneinfo.find(:all)
  end

  def list
    @geneinfo_pages, @geneinfos = paginate :geneinfos, :per_page => 100
  end

  def list_with_reactions
    respond_to do |wants|
      wants.html {
        list
        render :action => 'list_with_reactions'
      }
      wants.txt {
        list_all
        render :action => 'list_by_reaction', :layout => false
      }
    end
  end

  def fulltext
    @geneinfos = Geneinfo.easyfind(:keywords => params[:id], :fieldnames => ['genename','synonyms'])
    if @geneinfos.size == 1
      @geneinfo = @geneinfos.shift
      render :action => 'associate'
    end
  end

  def show
    @geneinfo = Geneinfo.find(params[:id])
    respond_to do |wants|
      wants.html {
        render
      }
      wants.xml {
        render :xml => @geneinfo.to_xml
      }
    end
  end

  def show_tissue
    @geneinfo = Geneinfo.find(params[:id])
    respond_to do |wants|
      wants.html {
        render :partial => 'tissues', :locals => { :geneinfo => @geneinfo }
      }
    end    
  end

  def new
    @geneinfo = Geneinfo.new
  end

  def associate
    @geneinfo = Geneinfo.find(params[:id])
    render
  end

  def add_dummy_enzyme
    @geneinfo = Geneinfo.find(params[:id])
    enzinfo = Enzymeinfo.new()
    enzinfo.record_class = "gene"
    enzinfo.geneinfo = @geneinfo
    enzinfo.save()
  end

  def populate_proteins
    @geneinfo = Geneinfo.find(params[:id])
    @geneinfo.populate_uprot_ids
    @enzymeinfos = @geneinfo.enzymeinfo  
  end

  def deprecate
    @geneinfo = Geneinfo.find(params[:id])
    @new_geneinfo = Geneinfo.find(params[:new_id])
    new_enzymeinfo = @new_geneinfo.enzymeinfo.detect { |enzinf| enzinf.is_gene? }
    @geneinfo.enzymeinfo.each { |enzinfo|
      if enzinfo.is_gene?
        enzinfo.enzyme_reactions.each { |enz_reac|          
          new_reaction = EnzymeReaction.new()
          new_reaction.enzymeinfo = new_enzymeinfo
          new_reaction.reaction = enz_reac.reaction
          logger.error "About to delete Enzyme reaction #{enz_reac.id} and create a #{new_reaction.enzymeinfo.id} #{new_reaction.reaction.id} in it's place"
          enz_reac.destroy
          new_reaction.save
        }
      end
      enzinfo.destroy
    }
    
  end

  def create
    @geneinfo = Geneinfo.new(params[:geneinfo])
    if @geneinfo.save
      flash[:notice] = 'Geneinfo was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def populate
    @geneinfo = Geneinfo.find(params[:id])
    @geneinfo.populate
    render :action => 'edit'
  end

  def edit
    @geneinfo = Geneinfo.find(params[:id])
  end

  def update
    @geneinfo = Geneinfo.find(params[:id])
    if @geneinfo.update_attributes(params[:geneinfo])
      flash[:notice] = 'Geneinfo was successfully updated.'
      redirect_to :action => 'show', :id => @geneinfo
    else
      render :action => 'edit'
    end
  end

  def destroy
    Geneinfo.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
