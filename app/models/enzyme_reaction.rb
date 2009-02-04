class EnzymeReaction < ActiveRecord::Base
	belongs_to :reaction
	belongs_to :enzymeinfo
	has_many :refs
	validates_associated :reaction, :enzymeinfo
		
	def validate_on_create
		if (EnzymeReaction.find_by_reaction_id_and_enzymeinfo_id(reaction.id, enzymeinfo.id))
			errors.add('enzyme_reaction','Record exists')
		end
		super
	end
		
end
