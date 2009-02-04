class Uprotinfocache < ActiveRecord::Migration
  def self.up
    add_column "enzymeinfos", "uprot_name", :string
    add_column "enzymeinfos", "uprot_description", :string    
    add_column "enzymeinfos", "uprot_organism", :string
  end

  def self.down
    remove_column "enzymeinfos", "uprot_name"
    remove_column "enzymeinfos", "uprot_description" 
    remove_column "enzymeinfos", "uprot_organism"
  end
end
