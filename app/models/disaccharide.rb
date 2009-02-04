class Disaccharide < ActiveRecord::Base
  attr_accessor :sugar

	def as_sugar(sequence)
	  SugarHelper.CreateSugar(sequence)
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

  def evidence_count
    reaction = Reaction.find(:first, :conditions => ["residuedelta = ? AND checked_evidence IS NOT NULL", self.residuedelta])

    invalid_glycosciences = reaction ? (reaction.checked_evidence || '').split(',') : []

    disaccharides = Disaccharide.find_all_by_residuedelta(self.residuedelta)
    
    disaccharides.delete_if { |d| invalid_glycosciences.include? d.glycosciences }.size
  end

    
  def linkage
    delta = as_sugar(residuedelta)
    donor,delta_substrate = delta.paths[0]
    link = donor.linkage_at_position
    return "#{donor.anomer}#{link.first_position}-#{link.second_position}"    
  end

  def is_evidenced?(delta=self.residuedelta)
    return ! Reaction.find_all_by_residuedelta(delta).reject { |r| r.enzyme_reactions.length == 0 && r.evidence.length == 0 }.empty?
  end

  def cites(delta=self.residuedelta)
    return Reaction.find(:first, :conditions => ["residuedelta = ? AND evidence IS NOT NULL", delta]).evidence.scan(/cite\:\w{3}\d+/) || []
  end

  def has_enzyme?(delta=self.residuedelta)
    return ! Reaction.find_all_by_residuedelta(delta).reject { |r| r.enzyme_reactions.length == 0 }.empty?
  end

  def has_been_checked?(delta=self.residuedelta)
    reactions = Reaction.find_all_by_residuedelta(delta)
    if reactions.empty?
      return false
    end
    return reactions.reject { |r| r.checked_evidence != nil }.empty?
  end

end
