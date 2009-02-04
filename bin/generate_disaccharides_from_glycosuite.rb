#!/usr/bin/env ruby

# This script checks the pathway coverage of structures
require 'ftools'
require File.join(File.dirname(__FILE__), 'script_common')

require 'optparse'
require 'csv'
require 'postgres'
require 'SugarUtil'
require 'lax_residue_names'

opts = {
	:verbose => 5,
	:test => false,
}

@opts = opts

verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby generate_disaccahrides_from_glycosuite.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-t", "--test",TrueClass,"Test run") { |opts[:test]| }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.parse!

}

structures = IO.read('data/main_glycodb_tax9606_ovary').split("\n").collect { |struct|
  struct.gsub!( /\(\?/,'(u')
  struct.gsub!( /\(-/,'(u1-')
  struct.gsub!(/\+".*"$/,'')
  struct.split(' ')
}.collect { |r| [r[1], :ic, r[0],1000] }


class StructureHash < Hash
  attr_accessor :structure_map
  def []=(key,value)
    key_to_use = key
    if key.is_a? Sugar
      seq = key.sequence
      key = @structure_map[seq] || key
      @structure_map[seq] = key
      key_to_use = seq
    end
    super(key_to_use,value)
  end

  def [](key)
    if key.is_a? Sugar
      if has_key?(key.sequence)
        return super(key.sequence)
      end
    end
    super(key)
  end

  def lookup_sugar(key)
    if key.is_a? Sugar
      key = key.sequence
    end
    return @structure_map[key]
  end
  def initialize
    @structure_map = Hash.new()
    super
  end
end

@logger = Logger.new(STDERR)

total_disaccharides = StructureHash.new() { |h,k| h[k] = [] }

struct_count = 0

structures.each { |row|
  @logger.info("Completed #{struct_count}/#{structures.size}")
  sug = nil
  begin
    sug = SugarHelper.CreateRenderableSugar(row[0],row[1])
    links = SugarUtil.FindDisaccharides(sug)
    locally_seen = []
    links.keys.each { |link|
#      SugarHelper.SetWriterType(link,:ic)      
      link.root.anomer = 'u'
      link_seq = link.sequence
      unless locally_seen.include?(link_seq)
        total_disaccharides[link] << { :glycomedb => row[2], :glycosciences => row[3] }
        locally_seen << link_seq
      end
    }
    struct_count += 1
  rescue Exception => e
    p e
    struct_count += 1
    next
  end
}

Sugar::IO::GlycoCT::Builder::HIDDEN_RESIDUES.keys.each { |res_name|
  p "#{res_name} - #{Sugar::IO::GlycoCT::Builder::HIDDEN_RESIDUES[res_name]}"
}

ActiveRecord::Base::connection.schema_search_path = "tax9606tissueovary"


total_disaccharides.each { |k,v|
#  p v.size
  v.each { |struct_id|
    sug = total_disaccharides.lookup_sugar(k)
    disac = Disaccharide.new
    disac.parent = sug.root.name(:stephan)
    disac.child = sug.leaves[0].name(:stephan)
    disac.anomer = sug.leaves[0].anomer
    pos = sug.leaves[0].paired_residue_position()
    pos_2 = sug.root.paired_residue_position(pos)
    disac.substitutions = "(#{pos}+#{pos_2})"
    disac.residuedelta = k
    disac.structure_id_glycomedb = struct_id[:glycomedb]
    disac.glycosciences = struct_id[:glycosciences]
    disac.save
  }
  # if v.size > 3
  #   p "#{k} - #{v.join(',')}"
  # end
}
