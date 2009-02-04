class ReactionDeltaIndex < ActiveRecord::Migration
  def self.up
    add_index :reactions, :residuedelta
  end

  def self.down
    remove_index :reactions, :residuedelta
  end
end
