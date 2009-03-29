class GlycodbRefs < ActiveRecord::Migration
  def self.up
    add_column :glycodbs, :references, :string
  end

  def self.down
    remove_column :glycodbs, :references
  end
end
