require 'SugarHelper'
require 'Glycotransferase'
require 'Render/Renderable'
require 'Sugar/IO/GlycoCT'
require 'Sugar/IO/CondensedIupac'

module Enumerable
  def uniq_by
    h = {}; inject([]) {|a,x| h[yield(x)] ||= a << x}
  end
end

class Glycotransferase
  attr_accessor :id
end

class StructureMapController < ApplicationController

  layout 'standard'

  class ICSug < Sugar
    include Sugar::IO::CondensedIupac::Builder
    include Sugar::IO::GlycoCT::Writer
  	include Renderable::Sugar
  	
  	class Residue < NamespacedMonosaccharide
  	  include Renderable::Residue
	  end
  	
  	class Linkage < Linkage
  	  include Renderable::Link
	  end
  	
  	def residueClass
  	  Residue
	  end
  	
  	def linkageClass
  	  Linkage
	  end

  end

  class RenderableSugar < Sugar
    include Sugar::IO::GlycoCT::Builder
    include Sugar::IO::GlycoCT::Writer
  	include Renderable::Sugar
  	
  	class Residue < NamespacedMonosaccharide
  	  include Renderable::Residue
	  end
  	
  	class Linkage < Linkage
  	  include Renderable::Link
	  end
  	
  	def residueClass
  	  Residue
	  end
  	
  	def linkageClass
  	  Linkage
	  end
  	
  end

  after_filter :garbage_collect

  def index
    input
    render :action => "input"
  end
  
  def input
    @reactions = Reaction.find(:all).uniq_by { |r| r.residuedelta }
  end
  
  def show
    @enzymes = Reaction.find(params[:ids]).collect { |reac|
        sug = RenderableSugar.new()
        sug.sequence = reac.residuedelta
        sug.name = reac.id
        sug
      }.collect { |sug|
        enz = Glycotransferase.CreateFromSugar(sug)
        enz.id = sug.name
        sug.finish
        enz
      }

    start_sugar = ICSug.new()

    start_sugar.input_namespace = :ic
    start_sugar.sequence = params[:start_seq]

    @result = Glycotransferase.Apply_Set(@enzymes, start_sugar, 8) { |enz, sugar, link|
      link.first_residue.labels << "enzyme-#{enz.id}"
      link.labels << "enzyme-#{enz.id}"
    }
    
  end

  private
  
  def garbage_collect
    (@result || []).each { |sug|
      sug.finish
    }
    (@enzymes || []).each { |enz|
      enz.finish
    }
  end

end
