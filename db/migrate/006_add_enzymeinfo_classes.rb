class AddEnzymeinfoClasses < ActiveRecord::Migration
  def self.up
    add_column :enzymeinfos, :record_class, :string, :default => 'gene'
    remove_column :enzymeinfos, :uprotid
    add_column :enzymeinfos, :uprotid, :string
  end

  def self.down
    remove_column :enzymeinfos, :record_class
    remove_column :enzymeinfos, :uprotid
    add_column :enzymeinfos, :uprotid, :string, :default => 'all'    
  end
end
