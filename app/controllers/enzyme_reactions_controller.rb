class EnzymeReactionsController < ApplicationController
  layout 'standard'
  
  before_filter :normalise_sequence, :only => [:new_with_reaction, :create_with_reaction]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @enzyme_reaction_pages, @enzyme_reactions = paginate :enzyme_reactions, :per_page => 10
  end

  def show
    @enzyme_reaction = EnzymeReaction.find(params[:id])
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @enzyme_reaction.to_xml }
    end
  end

  def new
    @enzyme_reaction = EnzymeReaction.new
  end

  def create
    @enzyme_reaction = EnzymeReaction.new(params[:enzyme_reaction])
    if @enzyme_reaction.save
      flash[:notice] = 'EnzymeReaction was successfully created.'
      respond_to do |wants|
        wants.html { redirect_to :action => 'list' }
        wants.xml  { render :xml => @enzyme_reaction.to_xml }
      end
    else
      respond_to do |wants|
        wants.html { redirect_to :action => 'new' }
        wants.xml  { render :xml => @enzyme_reaction.to_xml }
      end
    end
  end

  def new_with_reaction
    if params[:enzymeinfo] != nil && params[:enzymeinfo][:id] != nil
      @enzymeinfo = Enzymeinfo.find(params[:enzymeinfo][:id])
    else
      flash[:notice] = 'No enzyme specified'
    end
    @reaction = Reaction.new()
    @enzyme_reaction = EnzymeReaction.new()
  end

  def create_with_reaction
    @reaction = params[:reaction][:id] ? Reaction.find(params[:reaction][:id]) : Reaction.new(params[:reaction])
    if @reaction.save
      @enzymeinfo = Enzymeinfo.find(params[:enzymeinfo][:id])
      @enzyme_reaction = EnzymeReaction.new(params[:enzyme_reaction])
      @enzyme_reaction.enzymeinfo = @enzymeinfo
      @enzyme_reaction.reaction = @reaction
      if @enzyme_reaction.save
        flash[:notice] = 'EnzymeReaction was successfully created.'
        respond_to do |wants|
          wants.html { redirect_to :controller => 'geneinfos', :action => 'associate', :id => @enzymeinfo.geneinfo.id }
          wants.xml  { render :xml => @enzyme_reaction.to_xml }          
        end
      else
        respond_to do |wants|
          wants.html { redirect_to :action => 'new_with_reaction' }
          wants.xml  { render :xml => @enzyme_reaction.to_xml }
        end        
      end
    else
      respond_to do |wants|
        wants.html { redirect_to :action => 'new_with_reaction' }
        wants.xml  { render :xml => @enzyme_reaction.to_xml }
      end      
    end
  end

  def edit
    @enzyme_reaction = EnzymeReaction.find(params[:id])
  end

  def update
    @enzyme_reaction = EnzymeReaction.find(params[:id])
    if @enzyme_reaction.update_attributes(params[:enzyme_reaction])
      flash[:notice] = 'EnzymeReaction was successfully updated.'
      redirect_to :action => 'show', :id => @enzyme_reaction
    else
      render :action => 'edit'
    end
  end

  def destroy
    EnzymeReaction.find(params[:id]).destroy
    redirect_to :action => 'list'
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

  private :normalise_sequence

end
