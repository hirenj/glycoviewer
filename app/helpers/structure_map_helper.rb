module StructureMapHelper
  def write_enzyme(enzyme)
    sug = SugarHelper.CreateRenderableSugar(Reaction.find(enzyme.id).residuedelta)
    sug.name = "enzyme-#{enzyme.id}"
    @sugar = sug
    rendered = render :partial =>'sviewer/render', :locals => { :sugar => @sugar, :scale => nil }
    sug.finish
    return rendered
  end
end
