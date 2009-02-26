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

end
