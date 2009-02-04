#!/usr/bin/env ruby

# This script checks the pathway coverage of structures

require File.join(File.dirname(__FILE__), 'script_common')

require 'postgres'
require 'app/controllers/application.rb'
require 'app/controllers/enzyme_coverage_controller.rb'

require 'optparse'
require 'csv'
require 'ftools'
require File.join(File.dirname(__FILE__),'check_pathway_coverage_support')

require 'lax_residue_names'

opts = {
	:verbose => 5,
	:outfile => nil,
	:test => false,
	:do_general_stats => false
}

@opts = opts

verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby run_coverage_on_all_structs.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-o", "--outfile OUTFILE", String, "Filename to write results to") { |opts[:outfile]| }
  opt.on("-t", "--test",TrueClass,"Test run") { |opts[:test]| }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.parse!

}

class CsvWriter
  attr_accessor :device
  def <<(message)
    if message.is_a? String
      message = [ message ]
    end
    device << message
  end
end

class TextWriter
  attr_accessor :device
  def <<(message)
    if message.is_a? Array
      message = message.join("\t")
    end
    device << message+"\n"
  end
end

if opts[:outfile] != nil && ! opts[:test]
  OUT_STREAM = CsvWriter.new()  
  OUT_STREAM.device = CSV.open(opts[:outfile],'w',"\t")
else
  OUT_STREAM = TextWriter.new()
  OUT_STREAM.device = Logger.new(STDOUT)
end

@logger = Logger.new(STDERR)
ActionController::Base.logger = @logger
ActiveRecord::Base.logger = @logger
ActiveRecord::Base.logger.level = opts[:verbose]
DebugLog.global_logger = @logger

get_structures_sql = <<__SQL__
SELECT core.structure.structure_id, glyco_ct FROM 
(SELECT structure_id FROM remote_one.structure_has_taxon WHERE taxon_id=9606) human_structures
INNER JOIN 
core.structure ON core.structure.structure_id=human_structures.structure_id
__SQL__

# conn = PGconn.connect("zsweb3",5432,'','','glycomedb','postgres','postgres')
# res = conn.exec(get_structures_sql).collect { |r| [r[1], :glycoct, r[0] ] }.collect { |row|
#   row[0].gsub!(/UND.*$/m,'')
#   row
# }
# 
# res = IO.read('data/glycomedb_structures.csv').split("\n\n").collect { |r| [r, :glycoct] }.collect { |row|
#  row[0].gsub!(/UND.*$/m,'')
#  row
# }

id = 0
res = IO.read('seq_results_n_linked.txt').split("\n")
total_sequences = res.size
res = res.collect { |struct|
  @logger.info("\e[1F\e[KCleaning #{id}/#{total_sequences}")
  id += 1
  struct.gsub!( /\(\?/,'(u')
  struct.gsub!( /\(-/,'(u1-')
  struct.gsub!(/\+".*"$/,'')
  struct
}.collect { |r| [r, :ic, 1000] }

if opts[:test]
  res = [ ['GlcNAc(b1-2)Man(a1-3)[Glc(b1-4)GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc', :ic ],
          ['Xyl(b1-4)GlcNAc(b1-2)Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc', :ic ],
          ['Glc(b1-4)GlcNAc(b1-2)Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc', :ic ],
          ['Man(a1-2)Man(a1-2)Man',:ic],
          ['Man(a1-2)[Glc(a1-3)]Man(a1-2)Man',:ic],
          ['Fuc(a1-2)Man(a1-2)Fuc',:ic],
          ['Cow(u1-u)GlcNAc',:ic],
          ['GlcNAc(b1-4)GlcNAc',:ic]
  ]
end
coverage_finder = EnzymeCoverageController.new()
@logger.info("Beginning initial analysis\n\n")
struct_count = 1

unparsed = 0

res.each { |r|
  @logger.info("\e[1F\e[KCompleted #{struct_count}/#{res.size}")
  sug = nil
  begin
    sug = SugarHelper.CreateRenderableSugar(r[0],r[1])   
  rescue Exception => e
    unparsed += 1
    struct_count += 1
    next
  end

  SugarHelper.SetWriterType(sug,:ic)
  if sug.residue_composition.size == 1
    sug.finish()
    next
  end
  sug.root.anomer = 'u'
  coverage_finder.sugar = sug
  
  sug.residue_composition.each { |residue|
      residue.extend(EnzymeCoverageController::ValidityTest)
  }
  
  
  all_results = coverage_finder.execute_pathways
  best_results = nil
  best_result_size = nil
  all_results.each { |results|
    if results[:deltas].size == sug.residue_composition.size
      sug.finish()
      next
    end

    sug.residue_composition.each { |residue|
      residue.validate
    }
    
    coverage_finder.markup_chains(results,false)
    
    result_size = sug.residue_composition.reject { |residue| residue.is_valid? }.size
    
    if best_result_size == nil || result_size < best_result_size        
      best_result_size = result_size
      best_results = results
    end
    
    coverage_finder.markup_chains(results)
  }  

  if best_results != nil && best_result_size > 0
    OUT_STREAM << [ r[2], sug.sequence , best_result_size ]
  end
  sug.finish()
  struct_count += 1  
}
