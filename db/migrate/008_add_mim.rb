class AddMim < ActiveRecord::Migration
  def self.up
    add_column :geneinfos, :mim_id, :string
  end

  def self.down
    remove_column :geneinfos, :mim_id
  end
end
