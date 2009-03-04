# For each tissue tag with expression data, list the number of uncovered linkages, the number of structures per tissue group, and the same data for healthy vs diseased


# This script generates a whole bunch of n-glycans in a Claytons database that can be used
# to generate a virtual database

require File.dirname(__FILE__) + '/script_common'

require 'SugarHelper'

require 'app/controllers/application.rb'
require 'app/controllers/enzyme_coverage_controller.rb'
require 'app/controllers/enzymeinfos_controller.rb'
require 'app/controllers/glycodbs_controller.rb'

require 'lax_residue_names'

require 'optparse'

opts = {
	:verbose => 5,
}

@opts = opts

verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby check_pathway_coverage.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.parse!

}

@logger = Logger.new(STDERR)
ActiveRecord::Base.logger = @logger
ActiveRecord::Base.logger.level = opts[:verbose]
DebugLog.global_logger = @logger


all_tissues = Enzymeinfo.All_Tissues
all_tags = Glycodb.All_Tags.collect { |tag|
    tag_copy = tag.clone
    tag = tag.gsub!(/anat\:/,'') ? tag.humanize : nil
    all_tissues.include?(tag) ? tag_copy : nil
}.compact
all_tags.each { |tag|
  glycodbs_controller = GlycodbsController.new()
  sugars = glycodbs_controller.execute_coverage_for_tag(tag+',diseased')
  sugars.each { |sug|
    SugarHelper.SetWriterType(sug,:ic)
    my_linkages = sug.linkages.reject { |link| link.is_valid? }.collect { |link| 
      link.extend(Sugar::IO::CondensedIupac::LinkageWriter)
      link.child_residue.name(:ic)+sug.write_linkage(link)+link.parent_residue.name(:ic)
    }.flatten.sort.uniq
    puts "diseased_#{tag},"+sug.structure_count.to_s+','+sug.root.name(:ic)+",#{my_linkages.size},"+my_linkages.join(',')
  }
  sugars = glycodbs_controller.execute_coverage_for_tag(tag+',healthy')

  sugars.each { |sug|
    SugarHelper.SetWriterType(sug,:ic)
    my_linkages = sug.linkages.reject { |link| link.is_valid? }.collect { |link| 
      link.extend(Sugar::IO::CondensedIupac::LinkageWriter)
      link.child_residue.name(:ic)+sug.write_linkage(link)+link.parent_residue.name(:ic)
    }.flatten.sort.uniq
    puts "healthy_#{tag},"+sug.structure_count.to_s+','+sug.root.name(:ic)+",#{my_linkages.size},"+my_linkages.join(',')        
  }
}