class RenameMim < ActiveRecord::Migration
  def self.up
    rename_column :geneinfos, :mim_id, :mimid
  end

  def self.down
    rename_column :geneinfos, :mimid, :mim_id
  end
end
