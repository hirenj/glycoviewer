require File.dirname(__FILE__) + '/script_common'

require 'postgres'

gem 'builder', '~> 2.0'
gem 'xml-mapping'

require "rexml/document"
include REXML

require 'app/models/reaction.rb'

NamespacedMonosaccharide.Default_Namespace = NamespacedMonosaccharide::NAMESPACES[:glyde]

require 'optparse'

opts = {
	:verbose => 5,
	:test => false
}
verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby get_disacchrides_for_pathway.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.on("-p", "--pathway PATHWAY", String, "Pathway to get disaccharides for") { |opts[:pathway]|}
  opt.on("-t", "--test",String, "Test only") { opts[:test] = true }
  opt.parse!

}

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = opts[:verbose]

logger = ActiveRecord::Base.logger

@reactions = Reaction.find_by_sql(['select * from reactions where pathway like %',"%#{opts[:pathway]}%"])

@reactions.each { |reac|
  
}