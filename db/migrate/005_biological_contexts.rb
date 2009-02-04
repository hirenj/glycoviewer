class BiologicalContexts < ActiveRecord::Migration
  def self.up
    add_column "enzymeinfos", "mesh_tissue", :string, :limit => 1024
    add_column "enzymeinfos", "ncbi_taxonomy", :string, :limit => 1024
  end

  def self.down
    remove_column "enzymeinfos", "mesh_tissue"
    remove_column "enzymeinfos", "ncbi_taxonomy"
  end
end
