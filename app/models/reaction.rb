require 'SugarHelper'

class Reaction < ActiveRecord::Base
	validates_uniqueness_of :endstructure, :scope => [:substrate, :residuedelta]
	validates_presence_of :endstructure, :substrate
	has_many :enzymeReaction
	
	def as_sugar(sequence)
	  SugarHelper.CreateSugar(sequence)
  end
		
	def enzyme_reactions
	  EnzymeReaction.find_all_by_reaction_id(id)
  end
	
	def before_validation
		reaction = Reaction.find(:first, :conditions => ["endstructure = ? and substrate = ?", self.endstructure, self.substrate ] )
		if reaction != nil
			@new_record = false
			self.id = reaction.id
		end
	end
	
  def genes
    return enzyme_reactions.collect { |ez| ez.enzymeinfo.geneinfo }
  end

  def donor
    delta = as_sugar(residuedelta)
    donor,delta_substrate = delta.paths[0]
    return donor
  end

  def substrate_residue
    delta = as_sugar(residuedelta)
    donor,delta_substrate = delta.paths[0]
    return delta_substrate
  end
  
  def linkage
    delta = as_sugar(residuedelta)
    donor,delta_substrate = delta.paths[0]
		link = donor.linkage_at_position
		return "#{donor.anomer}#{link.first_position}-#{link.second_position}"    
  end
  
  def has_enzyme?
    return self.enzyme_reactions.length > 0
  end
  
end
