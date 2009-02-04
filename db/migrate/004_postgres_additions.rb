class PostgresAdditions < ActiveRecord::Migration
  def self.up
    remove_column "enzymeinfos", "uprot_name"
    remove_column "enzymeinfos", "uprot_description" 

    add_column "enzymeinfos", "uprot_name", :string, :limit => 1024
    add_column "enzymeinfos", "uprot_description", :string, :limit => 1024
  end

  def self.down
  end

end
