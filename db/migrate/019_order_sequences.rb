class OrderSequences < ActiveRecord::Migration
  def self.up
    Reaction.find(:all).each { |reac|
      resdelta = reac.as_sugar(reac.residuedelta)
      substr = reac.as_sugar(reac.substrate)
      endstr = reac.as_sugar(reac.endstructure)
      reac.residuedelta = resdelta.sequence
      reac.substrate = substr.sequence
      reac.endstructure = endstr.sequence
      resdelta.finish
      substr.finish
      endstr.finish
      reac.save
    }
  end

  def self.down
  end
end
