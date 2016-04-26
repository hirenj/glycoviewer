
delete from geneinfos;

populate: id (autoincrement) genename geneid (null) synonyms (null) mimid (null)

delete from reactions;

populate: id(autoincrement) residuedelta (Glyco-CT) substrate (null) enstructure (null) evidence (null) checked_evidence (null) kegg_id (null) pathway (valid-value)

delete from enzyme_reactions;

populate: id (autoincrement) reaction_id (from reactions) enzymeinfo_id (from enzymeinfo)

delete from enzymeinfos;

populate: id (autoincrement) geneinfo_id (from genes) cazyid (null) ecid (null) uprot_organism (null) uprot_name (null) uprot_description (null) mesh_tissue (cell line variability) ncbi_taxonomy (null) record_class ('gene') uproid (null) 