class EvidenceDefaultValue < ActiveRecord::Migration
  def self.up
    change_column :reactions, :evidence, :string, :default => ''
    Reaction.find(:all).each { |reac|
      if reac.evidence == nil
        reac.evidence = ''
        reac.save
      end
    }
  end

  def self.down
    change_column :reactions, :evidence, :string, :default => nil
  end
end
