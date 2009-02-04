class ReactionCheckedPapersField < ActiveRecord::Migration
  def self.up
    add_column :reactions, :checked_evidence, :string
  end

  def self.down
    remove_column :reactions, :checked_evidence
  end
end
