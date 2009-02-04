class ReactionEvidenceField < ActiveRecord::Migration
  def self.up
    add_column :reactions, :evidence, :string
  end

  def self.down
    remove_column :reactions, :evidence
  end
end
