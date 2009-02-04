class RemoveCerSerPp < ActiveRecord::Migration
  def self.up
    to_switch = ['ser','thr','pp','cer']

    Reaction.find(:all).each { |reac|
      substr = reac.as_sugar(reac.substrate)
      endstr = reac.as_sugar(reac.endstructure)
      new_substr = nil
      new_endstr = nil
      if to_switch.include?(substr.root.name(:ecdb)) && substr.root.children.size > 0
        new_substr = substr.sequence_from_residue(substr.root.children[0][:residue])
        new_endstr = endstr.sequence_from_residue(endstr.root.children[0][:residue])
      end

      if new_substr != nil
        new_reac = Reaction.new( :substrate => new_substr, :endstructure => new_endstr, :evidence => reac.evidence, :checked_evidence => reac.checked_evidence, :residuedelta => reac.residuedelta )
        new_reac.save

        reac.enzyme_reactions.each { |enz_reac|
          new_enz_reac = EnzymeReaction.new()
          new_enz_reac.enzymeinfo = enz_reac.enzymeinfo
          new_enz_reac.reaction = new_reac
          new_enz_reac.save
        }

      end
    }
  end

  def self.down
  end
end
