class ExpandEnzyme < ActiveRecord::Migration
  def self.up

  	create_table "refs" do |t|
  		t.column "id", :integer
  		t.column "enzyme_reaction_id", :integer
  		t.column "pmid", :integer
		t.column "desc", :string
  	end
  	
  	
  	create_table "geneinfos" do |t|
  		t.column "id", :integer
  		t.column "genename", :string
  		t.column "geneid", :integer
  	end

	drop_table :reactions
  
  	create_table "enzymeinfos" do |t|
  		t.column "id", :integer
  		t.column "geneinfo_id", :integer
  		t.column "uprotid", :string, :default => "all"
  		t.column "cazyid", :string
  		t.column "ecid", :string
  	end
  	
  	create_table "reactions" do |t|
  		t.column "id", :integer
  		t.column "residuedelta", :string, :limit => 512
  		t.column "substrate", :string, :limit => 512
  		t.column "endstructure", :string, :limit => 512  	
  	end
  	
  	create_table "enzyme_reactions" do |t|
  		t.column "id", :integer
  		t.column "reaction_id", :integer
  		t.column "enzymeinfo_id", :integer
  	end
  end

  def self.down
  	drop_table :reactions
  	drop_table :geneinfos
  	drop_table :refs
  	drop_table :enzyme_reactions
  	drop_table :enzymeinfos
  end
end
