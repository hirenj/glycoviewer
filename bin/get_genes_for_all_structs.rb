#!/usr/bin/env ruby

# This script retrieves the genes (as a list of gene names) required to synthesise each structure passed in

require File.join(File.dirname(__FILE__), 'script_common')

require 'postgres'
require 'app/controllers/application.rb'
require 'app/controllers/enzyme_coverage_controller.rb'

require 'optparse'
require 'csv'
require 'ftools'
require File.join(File.dirname(__FILE__),'check_pathway_coverage_support')

require 'lax_residue_names'

# require 'ruby-prof'

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

  opt.banner = "Usage:\n\truby get_genes_for_all_structs.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-o", "--outfile OUTFILE", String, "Filename to write results to") { |opts[:outfile]| }
  opt.on("-i", "--infile INFILE", String, "Filename to read structures from") { |opts[:infile]| }
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
res = IO.read(opts[:infile]).split("\n")
total_sequences = res.size

if opts[:test]
  res = [ 'GlcNAc(b1-2)Man(a1-3)[Glc(b1-4)GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc',
          'Xyl(b1-4)GlcNAc(b1-2)Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc',
          'Glc(b1-4)GlcNAc(b1-2)Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc',
          'Man(a1-2)Man(a1-2)Man',
          'Man(a1-2)[Glc(a1-3)]Man(a1-2)Man',
          'Fuc(a1-2)Man(a1-2)Fuc',
          'Cow(u1-u)GlcNAc',
          'GlcNAc(b1-4)GlcNAc'
  ]
end
coverage_finder = EnzymeCoverageController.new()
@logger.info("Beginning gene coverage analysis\n\n")
struct_count = 1

unparsed = 0

# RubyProf.start

res.each { |seq|
  @logger.info("\e[1F\e[KCompleted #{struct_count}/#{res.size}")
  sug = nil
  begin
    sug = SugarHelper.CreateRenderableSugar(seq,:ic)   
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
  
  gene_arrays = coverage_finder.execute_genes
  gene_arrays.each { |gene_array|
    hex_rep = sprintf('%048x',gene_array.binary_id)
    hex_strings = []
    while hex_rep.size > 0
      hex_strings << "#{hex_rep.slice!(0,16)}".hex.to_s(10)
    end
    OUT_STREAM << ([struct_count,"\"#{seq}\"",gene_arrays.size]+hex_strings).join('#')
  }
  sug.finish()
  struct_count += 1  
}
# profiling_result = RubyProf.stop
# 
# printer = RubyProf::GraphPrinter.new(profiling_result)
# printer.print(STDERR,0)
