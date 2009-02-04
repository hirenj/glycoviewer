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

ActiveRecord::Schema.define(:version => 20090202055332) do

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
