class StorePathwayInfo < ActiveRecord::Migration
  def self.up
    add_column :reactions, :kegg_id, :string
    add_column :reactions, :pathway, :string
  end

  def self.down
    remove_column :reactions, :kegg_id
    remove_column :reactions, :pathway
  end
end
