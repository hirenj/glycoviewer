#!/usr/bin/env ruby

# This script writes a set of bit masks for a list of knockouts for genes

require File.join(File.dirname(__FILE__), 'script_common')

require 'optparse'
require 'app/controllers/application.rb'

opts = {
	:verbose => 5,
	:outfile => nil,
	:knockout => false,
	:genes => [],
	:test => false,
	:do_general_stats => false
}

@opts = opts

verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby get_sql_for_knockout.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-k", "--knockout", TrueClass, "Make this a knockout list") { |opts[:knockout]| }
  opt.on("-i", "--gene GENENAME", String, "Gene name to add to list") { |genename| opts[:genes] += genename.split(/,/) }
  opt.on("-t", "--tissue TISSUENAME", String, "Tissue name to use") { |tissue| opts[:tissue] = tissue }
  opt.on("-t", "--test",TrueClass,"Test run") { |opts[:test]| }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.parse!

}
genes = []
p "Tissue is #{opts[:tissue]}"
if opts[:tissue] != nil
  genes = Enzymeinfo.find(:all, :conditions => ['mesh_tissue = :mesh_tissue', { :mesh_tissue => opts[:tissue]}]).collect {|e| e.geneinfo }.uniq
else
  genes = Geneinfo.find(:all).select { |g| opts[:genes].include?(g.genename) == ! opts[:knockout] }
end
sum = 0
genes.each  { |g| sum += 2**(g.id - 1) }

p genes.size
p "Sum is #{sum}"
hex_rep = sprintf('%048x',sum)
p "0x#{hex_rep}"
hex_strings = []
while hex_rep.size > 0
  hex_strings << "#{hex_rep.slice!(0,16)}".hex.to_s(10)
end

puts hex_strings