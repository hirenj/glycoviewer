class CreateGlycodbs < ActiveRecord::Migration
  def self.up
  create_table "glycodbs", :id => false, :force => true do |t|
    t.string  "COMPOSITION_ID",           :limit => 28,                                  :null => false
    t.string  "COMPOSITION2",             :limit => 32,                                  :null => false
    t.integer "HEXOSE",                   :limit => 2,                                   :null => false
    t.integer "HEXNAC",                   :limit => 2,                                   :null => false
    t.integer "DEOXYHEXOSE",              :limit => 2,                                   :null => false
    t.integer "NEUAC",                    :limit => 2,                                   :null => false
    t.integer "NEUGC",                                                                   :null => false
    t.integer "PENTOSE",                                                                 :null => false
    t.integer "SULFATE",                                                                 :null => false
    t.integer "PHOSPHATE",                                                               :null => false
    t.integer "KDN",                                                                     :null => false
    t.integer "KDO",                                                                     :null => false
    t.integer "HEXA",                                                                    :null => false
    t.integer "METHYL",                                                                  :null => false
    t.integer "ACETYL",                                                                  :null => false
    t.integer "OTHER",                                                                   :null => false
    t.decimal "OTHER_MASS",                               :precision => 10, :scale => 4, :null => false
    t.decimal "OTHER_MASS_MONOISOTOPIC",                  :precision => 10, :scale => 4, :null => false
    t.decimal "GLYCAN_MASS",                              :precision => 10, :scale => 4, :null => false
    t.decimal "GLYCAN_MASS_MONOISOTOPIC",                 :precision => 10, :scale => 4, :null => false
    t.integer "TOTAL_RESIDUES",           :limit => 3,    :precision => 3,  :scale => 0, :null => false
    t.integer "STRUCTURE_ID",             :limit => 5,    :precision => 5,  :scale => 0, :null => false
    t.string  "GLYCAN_ST",                :limit => 500,                                 :null => false
    t.string  "AMINO_ACID_LINK",          :limit => 15
    t.string  "CORE_TYPE",                :limit => 25
    t.string  "LINK_SUGAR",               :limit => 38
    t.string  "GLYCAN_TYPE",              :limit => 30
    t.integer "SOURCE_ID",                :limit => 5,    :precision => 5,  :scale => 0
    t.string  "SPECIES",                  :limit => 80
    t.string  "CLASS",                    :limit => 40,                                  :null => false
    t.string  "COMMON_NAME",              :limit => 60
    t.string  "PROTEIN_NAME",             :limit => 70
    t.string  "SWISS_PROT",               :limit => 40
    t.string  "DISEASE",                  :limit => 80
    t.string  "BLOOD_GROUP",              :limit => 40
    t.string  "STRAIN",                   :limit => 35
    t.string  "CELL_LINE",                :limit => 26
    t.string  "SPECIAL",                  :limit => 1000
    t.string  "SYSTEM",                   :limit => 25
    t.string  "DIVISION1",                :limit => 30
    t.string  "DIVISION2",                :limit => 36
    t.string  "DIVISION3",                :limit => 30
    t.string  "DIVISION4",                :limit => 25
    t.string  "LIFE_STAGE",               :limit => 25
    t.string  "GLYCO_AA",                 :limit => 1000
    t.string  "GLYCO_AA_SITE",            :limit => 300
    t.string  "RECOMBINANT",              :limit => 60
    t.decimal "RELATIVE_ABUND",                           :precision => 5,  :scale => 2
    t.string  "CONFIRMED",                :limit => 1
    t.string  "NOTE",                     :limit => 750
    t.string  "AMINO_ACID_POSITION",      :limit => 75
    t.string  "LINKAGE",                  :limit => 10,                                  :null => false
    t.date    "RELEASE_DATE",                                                            :null => false
    t.date    "LAST_UPDATE"
    t.string  "GLYCODB_NO",               :limit => 23
  end
  end

  def self.down
    drop_table :glycodbs
  end
end
