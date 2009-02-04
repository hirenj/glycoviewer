#!/usr/bin/env ruby

# This script converts KEGG to the default namespace for the enzymedb

require File.dirname(__FILE__) + '/script_common'

require 'postgres'

gem 'builder', '~> 2.0'
gem 'xml-mapping'

require "rexml/document"
include REXML

require 'app/models/reaction.rb'

require 'optparse'

opts = {
	:verbose => 5,
	:test => false
}
verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby kegg_to_glycoct.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.on("-I", "--infile FILE", String, "Import data into database") { |opts[:infile]| }
  opt.on("-t", "--test",String, "Test only") { opts[:test] = true }
  opt.parse!

}

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = opts[:verbose]

logger = ActiveRecord::Base.logger

reactions = Hash.new() { |h,k| h[k] = Array.new() }
all_glycans = {}

doc = Document.new File.new(opts[:infile])
doc.elements.each('//reaction') {|reac|
  reac_id = reac.attributes['name']
  logger.info "INFO: Reaction #{reac_id}"
  reac.get_elements('substrate').each { |substr|
    substr_id = substr.attributes['name']
    if ! substr_id.match(/(gl:)?G\d+/)
      substr_id = nil
#      alt_element = substr.get_elements('alt')[0]
#      substr_id = alt_element ? alt_element.attributes['name'] : nil
    end
    if substr_id != nil
      substr_id.gsub!('gl:','')
      all_glycans[substr_id] = nil
    end
    reac.get_elements('product').each { |product|
      product_id = product.attributes['name']
      if ! product_id.match(/(gl:)?G\d+/)
        product_id = nil
        # alt_element = product.get_elements('alt')[0]
        # product_id = alt_element ? alt_element.attributes['name'] : nil
      end 
      if product_id != nil  
        product_id.gsub!('gl:','')
        all_glycans[product_id] = nil
      end
      if product_id != nil && substr_id != nil
        logger.info "INFO: For substrate #{substr_id}"
        logger.info "INFO: use product id #{product_id}"

        reactions[reac_id] << { :substrate => substr_id, :product => product_id }
      end
    }
  }
}

glycan_ids = all_glycans.keys.collect {|i| "'#{i}'"}

exit unless glycan_ids.size > 0

get_structures_sql = <<__SQL__
select remote_local.kegg_id, structure.glyco_ct
from (select structure_id, remote_structure.resource_id as kegg_id
from  core.remote_structure join core.remote_structure_has_structure
      on remote_structure.remote_structure_id = remote_structure_has_structure.remote_structure_id
where resource_id in (#{glycan_ids.join(',')})
) as remote_local join core.structure on remote_local.structure_id = structure.structure_id
__SQL__

conn = PGconn.connect("zsweb3",5432,'','','glycome','postgres','postgres')


res = conn.exec(get_structures_sql)

res.each { |res| 
  sug = SugarHelper.CreateSugar(res[1],:glycoct)
  sug.root.anomer = 'u'
  all_glycans[res[0]] = sug.sequence
  sug.finish
}
logger.info "INFO: We have #{reactions.keys.size} reactions"
reactions.keys.each { |reac_id|
  logger.info "INFO: Looping through #{reac_id} with #{reactions[reac_id].size}"
  reactions[reac_id].each { |reac_detail|
    substrate = all_glycans[reac_detail[:substrate]]
    product = all_glycans[reac_detail[:product]]
    logger.info "INFO: Product/Substrate for reaction #{reac_id} - #{reac_detail[:substrate]}/#{reac_detail[:product]}"
    if product.is_a?(String)
      sug =  SugarHelper.CreateSugar(product, :ecdb)
      sug.extend(Sugar::IO::CondensedIupac::Writer)
      sug.target_namespace = :ic
      logger.info "INFO: Product sequence #{sug.sequence}"
      sug.finish
    end
    if substrate.is_a?(String)
      sug =  SugarHelper.CreateSugar(substrate, :ecdb)
      sug.extend(Sugar::IO::CondensedIupac::Writer)
      sug.target_namespace = :ic
      logger.info "INFO: Substrate sequence #{sug.sequence}"
      sug.finish
    end
    logger.info "INFO: End Product/Substrate for reaction #{reac_id}"
  
    db_reactions = Reaction.find_by_sql(['select * from reactions where endstructure = ? and substrate = ?',product,substrate])
    reac = nil
    if db_reactions && db_reactions.size > 0
      reac = db_reactions.first
    elsif product != nil && substrate != nil && product.size > substrate.size
      reac = Reaction.new()
      reac.endstructure = product
      reac.substrate = substrate
      prod_sug = SugarHelper.CreateSugar(product)
      substrate_sug = SugarHelper.CreateSugar(substrate)
      substr_point = prod_sug.subtract(substrate_sug).first.parent
      substr_point.anomer = 'u'
      reac.residuedelta = prod_sug.sequence_from_residue(substr_point)
      prod_sug.finish
      substrate_sug.finish
    end
    if reac != nil
      logger.info "Updating Reaction #{reac.id ? reac.id : 'New reaction'}"
      reac.kegg_id = reac_id
      current_pathways = (reac.pathway || '').split(',')
      current_pathways << opts[:infile].gsub(/.xml/,'')
      current_pathways.uniq!
      reac.pathway = current_pathways.join(',')
      reac.save unless opts[:test]
    end
  }
}
