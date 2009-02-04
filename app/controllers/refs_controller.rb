class RefsController < ApplicationController
  layout 'standard'
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @ref_pages, @refs = paginate :refs, :per_page => 10
  end

  def show
    @ref = Ref.find(params[:id])
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @ref.to_xml }
    end
  end

  def new
    @ref = Ref.new
  end

  def create
    @ref = Ref.new(params[:ref])
    if @ref.save
      flash[:notice] = 'Ref was successfully created.'
      respond_to do |wants|
        wants.html { redirect_to :action => 'list' }
        wants.xml { render :xml => @ref.to_xml }
      end
    else
      respond_to do |wants|
        wants.html { render :action => 'new' }
        wants.xml { render :xml => @ref.to_xml }
      end
    end
  end

  def edit
    @ref = Ref.find(params[:id])
  end

  def update
    @ref = Ref.find(params[:id])
    if @ref.update_attributes(params[:ref])
      flash[:notice] = 'Ref was successfully updated.'
      redirect_to :action => 'show', :id => @ref
    else
      render :action => 'edit'
    end
  end

  def destroy
    Ref.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
