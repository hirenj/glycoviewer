class EnzymeinfosController < ApplicationController
  layout 'standard'
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @enzymeinfo_pages, @enzymeinfos = paginate :enzymeinfos, :per_page => 10
  end

  def reaction_thumbs
    @enzymeinfo = Enzymeinfo.find(params[:id])
    render :layout => false
  end

  def show
    @enzymeinfo = Enzymeinfo.find(params[:id])
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @enzymeinfo.to_xml }
    end
  end

  def list_tissues
    @tissues = Enzymeinfo.All_Tissues
    respond_to do |wants|
      wants.html
    end
  end

  def show_tissue
    @enzymeinfos = Enzymeinfo.find(:all, :conditions => ['mesh_tissue = :mesh_tissue', { :mesh_tissue => params[:mesh_tissue]}])
    @unseen_genes = Geneinfo.find(:all) - @enzymeinfos.collect { |e| e.geneinfo }
    @expressed_tissues = get_expressed_tissues
    @seen_genes = @enzymeinfos.collect {|enz| enz.geneinfo }.uniq
    @unseen_reactions = @unseen_genes.collect { |g| g.reactions }.flatten.uniq
    @seen_reactions = @seen_genes.collect { |g| g.reactions }.flatten.uniq
    seen_reactions_deltas = @seen_reactions.collect { |r| r.residuedelta }
    @unseen_reactions.reject! { |r| seen_reactions_deltas.include?(r.residuedelta)}
    
    @reactions = @unseen_reactions
    
    render
  end

  def show_expression_hex
    @enzymeinfos = Enzymeinfo.find(:all, :conditions => ['mesh_tissue = :mesh_tissue', { :mesh_tissue => params[:mesh_tissue]}])
    hex_strings = expression_hex
    render :text => hex_strings.join(',')
  end

  def expression_hex
    genes = ((@enzymeinfos.collect { |e| e.geneinfo })+(['ALG1','ALG2','ALG3','ALG12','ALG13','ALG14'].collect { |name| Geneinfo.find(:first, :conditions => { :genename => name } ) })).uniq
    sum = 0
    genes.each  { |g| sum += 2**(g.id - 1) }

    hex_rep = sprintf('%048x',sum)
    hex_strings = []
    while hex_rep.size > 0
      hex_strings << "#{hex_rep.slice!(0,16)}"
    end
    return hex_strings    
  end

  def get_expressed_tissues
    worker_key = 'expression_worker'
    job_key = params[:mesh_tissue]
    session[:running_jobs] ||= []
    my_worker = MiddleMan.worker(:expressedstructures_worker, worker_key)
    if my_worker && my_worker.worker_info
      if my_worker.worker_info[:status] != :running
        MiddleMan.new_worker(:worker => :expressedstructures_worker, :worker_key => worker_key)
      else
        all_results = ["#{job_key}-n","#{job_key}-o"].collect { |job|
          results = my_worker.ask_result(job)
          logger.info("Current results for job are #{results == nil ? 'nil' : results} for key #{job}")
          if results != nil
            session[:running_jobs] -= [job]
          end
          results
        }
        all_results.compact!
        logger.info(all_results.size)
        if all_results.size == 2
          return all_results.flatten
        end
      end
    else
      MiddleMan.new_worker(:worker => :expressedstructures_worker, :worker_key => worker_key)
    end
    
    if session[:running_jobs].include?(job_key+'-o')
      logger.info("Job is currently running for key #{job_key}")
      return true
    end
    
    hex_strings = expression_hex
    
    logger.info("Dispatching job with job key #{job_key}-n")
    
    session[:running_jobs] << job_key+'-n'
    
    MiddleMan.worker(:expressedstructures_worker,worker_key).async_n_linked_expression(:arg => hex_strings,:job_key => job_key+'-n')

    logger.info("Dispatching job with job key #{job_key}-o")

    session[:running_jobs] << job_key+'-o'

    MiddleMan.worker(:expressedstructures_worker,worker_key).async_o_linked_expression(:arg => hex_strings,:job_key => job_key+'-o')
    return false
  end

  def new
    @enzymeinfo = Enzymeinfo.new
  end

  def create
    logger.info(params)
    logger.info("I got params of #{params}")
    @enzymeinfo = Enzymeinfo.new(params[:enzymeinfo])
    if @enzymeinfo.save
      flash[:notice] = 'Enzymeinfo was successfully created.'
      respond_to do |wants|
        wants.html { redirect_to :action => 'list' }
        wants.xml  { render :xml => @enzymeinfo.to_xml }
      end
    else
      respond_to do |wants|
        wants.html { redirect_to :action => 'new' }
        wants.xml  { render :xml => @enzymeinfo.to_xml }
      end
    end
  end

  def edit
    @enzymeinfo = Enzymeinfo.find(params[:id])
  end

  def update
    @enzymeinfo = Enzymeinfo.find(params[:id])
    if @enzymeinfo.update_attributes(params[:enzymeinfo])
      flash[:notice] = 'Enzymeinfo was successfully updated.'
      redirect_to :action => 'show', :id => @enzymeinfo
    else
      render :action => 'edit'
    end
  end

  def destroy
    Enzymeinfo.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
