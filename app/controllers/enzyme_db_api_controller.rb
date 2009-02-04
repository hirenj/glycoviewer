# class GeneinfoAPI < ActionWebService::API::Base
#   api_method :associate_protein, :expects => [{:gene_id=>:int}, {:protein_id=>:string}], :returns => [Enzymeinfo]
#   api_method :associate_context, :expects => [{:gene_id=>:int}, {:mesh_tissue=>:string},{:ncbi_taxonomy=>:string}], :returns => [Enzymeinfo]
# end
# 
# class EnzymeReactionAPI < ActionWebService::API::Base
#   api_method :associate_enzyme, :expects => [{:reaction_id=>:int}, {:enzyme_id=>:int}], :returns => [EnzymeReaction]
#   api_method :associate_reference, :expects => [{:enzyme_reaction_id=>:int},{:pubmed_id=>:int}], :returns => [Ref]
#   api_method :destroy, :expects => [{:enzyme_reaction_id=>:int}], :returns => [:boolean]
# end
# 
# class GeneinfoService < ActionWebService::Base
#   
#   web_service_api GeneinfoAPI
#   
#   def associate_protein(gene_id, protein_id)    
#     geneinfo = Geneinfo.find(gene_id)
#     enzyme = Enzymeinfo.new()
#     enzyme.uprotid = protein_id
#     enzyme.geneinfo = geneinfo
#     enzyme.save
#     enzyme
#   end
#   
#   def associate_context(gene_id, mesh_tissue, ncbi_taxonomy)
#     geneinfo = Geneinfo.find(gene_id)
#     enzyme = Enzymeinfo.new()
#     enzyme.mesh_tissue = mesh_tissue
#     enzyme.ncbi_taxonomy = ncbi_taxonomy
#     enzyme.geneinfo = geneinfo
#     enzyme.record_class = :context.to_s
#     enzyme.save
#     enzyme
#   end
#   
#   def get_uprot_ids(gene_id)
#     geneinfo = Geneinfo.find(gene_id)
#     geneinfo.all_uprot_ids
#   end
#   
# end
# 
# class EnzymeReactionService < ActionWebService::Base
#   
#   web_service_api EnzymeReactionAPI
#   
#   def associate_enzyme(reaction_id, enzyme_id)
#     reaction = Reaction.find(reaction_id)
#     enzyme = Enzymeinfo.find(enzyme_id)
#     enzyme_reaction  = EnzymeReaction.new(:reaction => reaction, :enzymeinfo => enzyme)
#     enzyme_reaction.save
#     enzyme_reaction
#   end
#   
#   def destroy(enzyme_reaction_id)
#     enzyme_reaction = EnzymeReaction.find(enzyme_reaction_id)
#     enzyme_reaction.refs.each { |ref|
#       ref.destroy
#     }
#     enzyme_reaction.destroy
#     true
#   end
#   
#   def associate_reference(enzyme_reaction_id, pubmed_id)
#     enzyme_reaction = EnzymeReaction.find(enzyme_reaction_id)
#     reference = Ref.new(:enzymeReaction => enzyme_reaction, :pmid => pubmed_id)
#     reference.save
#     reference
#   end
#   
# end
# 
# class EnzymeDbApiController < ApplicationController
#   wsdl_service_name 'EnzymeDb'
#   web_service_dispatching_mode :layered
#   web_service :geneinfo, GeneinfoService.new
#   web_service :enzyme_reaction, EnzymeReactionService.new
# end