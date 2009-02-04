class Enzymes < ActiveRecord::Migration
  def self.up
  
  	create_table "reactions" do |t|
  		t.column "id", :integer
  		t.column "genename", :string
  		t.column "uprotid", :string
  		t.column "residuedelta", :string, :limit => 512
  		t.column "substrate", :string, :limit => 512
  		t.column "endstructure", :string, :limit => 512
  		t.column "donor", :string
  	end
  	
  end

  def self.down
  	drop_table :reactions
  end
end
