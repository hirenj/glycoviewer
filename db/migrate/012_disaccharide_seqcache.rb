class DisaccharideSeqcache < ActiveRecord::Migration
  def self.up
    add_column :disaccharides, :residuedelta, :string
    rename_column :disaccharides, :linkage, :substitutions
  end

  def self.down
    remove_column :disaccharides, :residuedelta
    rename_column :disaccharides, :substitutions, :linkage
  end
end
