class AddGlycosuiteTags < ActiveRecord::Migration
  def self.up
    add_column :glycodbs, :tags, :string
  end

  def self.down
    remove_column :glycodbs, :tags
  end
end
