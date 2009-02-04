class DisaccharideIndexes < ActiveRecord::Migration
  def self.up
    add_index :disaccharides, :parent
  end

  def self.down
    remove_index :disaccharides, :parent
  end
end
