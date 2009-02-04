class DisaccharidesGlycosciencesid < ActiveRecord::Migration
  def self.up
    add_column :disaccharides, :glycosciences, :string
  end

  def self.down
    remove_column :disaccharides, :glycosciences
  end
end
