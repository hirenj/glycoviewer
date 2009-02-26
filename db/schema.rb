# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090226012236) do

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "disaccharides", :force => true do |t|
    t.string  "parent",                 :limit => 200, :null => false
    t.string  "child",                  :limit => 200, :null => false
    t.string  "substitutions",          :limit => 200, :null => false
    t.string  "anomer",                 :limit => 200, :null => false
    t.integer "structure_id_glycomedb",                :null => false
    t.string  "residuedelta"
    t.string  "glycosciences"
  end

  add_index "disaccharides", ["residuedelta"], :name => "disac_residuedelta_idx"

  create_table "enzyme_reactions", :force => true do |t|
    t.integer "reaction_id"
    t.integer "enzymeinfo_id"
  end

  add_index "enzyme_reactions", ["id", "reaction_id", "enzymeinfo_id"], :name => "enzyme_reactions_id_reaction_id_enzymeinfo_id_idx"

  create_table "enzymeinfos", :force => true do |t|
    t.integer "geneinfo_id"
    t.string  "cazyid"
    t.string  "ecid"
    t.string  "uprot_organism"
    t.string  "uprot_name",        :limit => 1024
    t.string  "uprot_description", :limit => 1024
    t.string  "mesh_tissue",       :limit => 1024
    t.string  "ncbi_taxonomy",     :limit => 1024
    t.string  "record_class",                      :default => "gene"
    t.string  "uprotid"
  end

  add_index "enzymeinfos", ["id", "geneinfo_id"], :name => "enzymeinfos_id_geneinfo_id_idx"

  create_table "gene_masks", :id => false, :force => true do |t|
    t.integer "struct_id",  :limit => 8
    t.string  "sequence",   :limit => 1024
    t.integer "gene_count"
    t.integer "bitfield1",  :limit => 8
    t.integer "bitfield2",  :limit => 8
    t.integer "bitfield3",  :limit => 8
  end

  add_index "gene_masks", ["struct_id", "bitfield1", "bitfield2", "bitfield3"], :name => "gene_masks_idxs"
  add_index "gene_masks", ["struct_id", "bitfield1", "bitfield2", "bitfield3"], :name => "gene_masks_struct_id_bitfields"
  add_index "gene_masks", ["struct_id", "gene_count"], :name => "gene_masks_struct_id_gene_count"
  add_index "gene_masks", ["struct_id"], :name => "gene_masks_struct_id_idx"

  create_table "gene_masks_o", :id => false, :force => true do |t|
    t.integer "struct_id",  :limit => 8
    t.string  "sequence",   :limit => 1024
    t.integer "gene_count"
    t.integer "bitfield1",  :limit => 8
    t.integer "bitfield2",  :limit => 8
    t.integer "bitfield3",  :limit => 8
  end

  create_table "gene_masks_test", :force => true do |t|
    t.integer "struct_id",  :limit => 8
    t.string  "sequence",   :limit => 1024
    t.integer "gene_count"
    t.integer "bitfield1",  :limit => 8
    t.integer "bitfield2",  :limit => 8
    t.integer "bitfield3",  :limit => 8
  end

  add_index "gene_masks_test", ["bitfield1", "bitfield2", "bitfield3", "struct_id", "id"], :name => "gene_masks_test_id_bmasks_rev_all_idx"
  add_index "gene_masks_test", ["bitfield1", "bitfield2", "bitfield3", "struct_id"], :name => "gene_masks_test_id_bmasks_rev_idx"
  add_index "gene_masks_test", ["id", "bitfield1", "bitfield2", "bitfield3"], :name => "gene_masks_test_id_bmasks_idx"
  add_index "gene_masks_test", ["id", "bitfield1"], :name => "gene_masks_test_id_bmask1_idx"
  add_index "gene_masks_test", ["id", "bitfield2"], :name => "gene_masks_test_id_bmask2_idx"
  add_index "gene_masks_test", ["id", "bitfield3"], :name => "gene_masks_test_id_bmask3_idx"
  add_index "gene_masks_test", ["id"], :name => "gene_masks_test_id_idx", :unique => true

  create_table "geneinfos", :force => true do |t|
    t.string  "genename"
    t.integer "geneid"
    t.string  "synonyms"
    t.string  "mimid"
  end

  add_index "geneinfos", ["id", "genename"], :name => "geneinfos_id_genename_idx"
  add_index "geneinfos", ["id"], :name => "geneinfos_id_idx"

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

  create_table "reactions", :force => true do |t|
    t.string "residuedelta",     :limit => 512
    t.string "substrate",        :limit => 512
    t.string "endstructure",     :limit => 512
    t.string "evidence",                        :default => ""
    t.string "checked_evidence"
    t.string "kegg_id"
    t.string "pathway"
  end

  add_index "reactions", ["id", "residuedelta"], :name => "geneinfos_id_residuedelta_idx"
  add_index "reactions", ["id"], :name => "geneinfos_id_idx"
  add_index "reactions", ["residuedelta", "checked_evidence"], :name => "reactions_residuedelta_checked_idx"
  add_index "reactions", ["residuedelta"], :name => "index_reactions_on_residuedelta"
  add_index "reactions", ["residuedelta"], :name => "reactions_residuedelta_idx"

  create_table "refs", :force => true do |t|
    t.integer "enzyme_reaction_id"
    t.integer "pmid"
    t.string  "desc"
  end

end
