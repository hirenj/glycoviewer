class GeneSynonyms < ActiveRecord::Migration
  def self.up
    add_column :geneinfos, :synonyms, :string
  end

  def self.down
    remove_column :geneinfos, :synonyms
  end
end