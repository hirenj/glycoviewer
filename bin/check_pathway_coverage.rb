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

module HitCounter
  attr_accessor :hits
  def hits
    @hits ||= 0
  end  
end

class Monosaccharide
  include HitCounter
end

ADDITION_BLOCK = lambda { |residue,other_res,matched_yet|
  if residue.equals? other_res
    if ! matched_yet
      if residue.hits == 0 || other_res.hits == 0
        residue.hits = 0
      else
        residue.hits += other_res.hits
      end
    end
    true
  else
    false
  end
}

MATCH_BLOCK = lambda { |residue,other_res,matched_yet|
  residue.equals?(other_res) && ((! matched_yet && ((residue.hits += 1) > -1)) || true )
}

opts = {
	:verbose => 5,
	:outfile => nil,
	:test => false,
	:image_directory => 'svgs',
	:do_general_stats => false
}

@opts = opts

verbosity = 0

ARGV.options {
  |opt|

  opt.banner = "Usage:\n\truby check_pathway_coverage.rb [options] \n"

  opt.on("Options:\n")
  opt.on("-v", "--[no-]verbose", TrueClass, "Increase verbosity") { |verbose| opts[:verbose] = verbose ? (opts[:verbose] - 1) : (opts[:verbose] + 1) }
  opt.on("-o", "--outfile OUTFILE", String, "Filename to write results to") { |opts[:outfile]| }
  opt.on("-g", "--general-stats",TrueClass,"Do general stats") { |opts[:do_general_stats]| }
  opt.on("-i", "--image-directory DIRECTORY", String,  "Directory to write images to") { |opts[:image_directory]|}
  opt.on("-t", "--test",TrueClass,"Test run") { |opts[:test]| }
  opt.on("-h", "--help", "This text") { puts opt; exit 0 }
  opt.parse!

}

File.makedirs(opts[:image_directory])

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

def render_sugar_with_coverage(sugar, filename)
    SugarHelper.MakeRenderable(sugar)  
    targets = Element.new('svg:g')
    sugar.overlays << targets
    sugar.residue_composition.each { |residue|
      residue.callbacks.push( lambda { |element|
        xcenter = -1*(residue.center[:x]) 
        ycenter = -1*(residue.center[:y])
        label = Element.new('svg:text')
        label.add_attributes({'x' => xcenter, 'y' => ycenter })
        label.text = residue.hits
        targets.add_element(label)
      })
    }
    # File.open("svgs/#{pw.id}-#{seq}.png","w") {|file|
    #   file << SugarHelper.RenderSugarPng(epitope_union,:boston)
    # }
    unless @opts[:test]
      File.open(File.join(@opts[:image_directory],filename),"w") {|file|
        SugarHelper.RenderSugar(sugar,:full,:boston).write(file,4)
      }
    end
    sugar.overlays.delete(targets)
    
end


if opts[:outfile] != nil && ! opts[:test]
  OUT_STREAM = CsvWriter.new()  
  OUT_STREAM.device = CSV.open(opts[:outfile],'w',"\t")
else
  OUT_STREAM = TextWriter.new()
  OUT_STREAM.device = Logger.new(STDOUT)
end

@logger = Logger.new(STDERR)
ActiveRecord::Base.logger = @logger
ActiveRecord::Base.logger.level = opts[:verbose]
DebugLog.global_logger = @logger


get_structures_sql = <<__SQL__
SELECT core.structure.structure_id, glyco_ct FROM 
(SELECT structure_id FROM remote_one.structure_has_taxon WHERE taxon_id=9606) human_structures
INNER JOIN 
core.structure ON core.structure.structure_id=human_structures.structure_id
__SQL__

conn = PGconn.connect("zsweb3",5432,'','','glycomedb','postgres','postgres')
res = conn.exec(get_structures_sql).collect { |r| [r[1], :glycoct, r[0] ] }.collect { |row|
  row[0].gsub!(/UND.*$/m,'')
  row
}

# res = IO.read('data/glycomedb_structures.csv').split("\n\n").collect { |r| [r, :glycoct] }.collect { |row|
#  row[0].gsub!(/UND.*$/m,'')
#  row
# }

# res = IO.read('data/human_glycosuite_uniq.txt').split("\n").collect { |struct|
#   struct.gsub!( /\(\?/,'(u')
#   struct.gsub!( /\(-/,'(u1-')
#   struct.gsub!(/\+".*"$/,'')
#   struct
# }.collect { |r| [r, :ic] }

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
@logger.info("Beginning initial analysis")
struct_count = 1

unmatched_structures = []
full_pathway_count = Hash.new() { |h,k| h[k] = 0 }
partial_pathway_count = Hash.new() { |h,k| h[k] = 0 }
pathway_extension_stats = Hash.new() { |h,k| h[k] = Array.new() }
unparsed = 0

res.each { |r|
  @logger.info("Completed #{struct_count}/#{res.size}")
  sug = nil
  begin
    sug = SugarHelper.CreateRenderableSugar(r[0],r[1])   
  rescue Exception => e
    unparsed += 1
    struct_count += 1
    next
  end
  SugarHelper.SetWriterType(sug,:ic)
  sug.root.anomer = 'u'
  coverage_finder.sugar = sug
  results = coverage_finder.execute_pathways[0]

  maximal_pathways = results[:maximal_pathway_name].split(',').collect { |pw| PathwayResult.Factory(pw) }
  if results[:deltas].size == 0 || results[:maximal_pathway_name] == 'none'
    maximal_pathways.each { |pw|
      pw.resolved_structures += 1
    }
  end
  
  if results[:maximal_pathway_name] == 'none'
    unmatched_structures << r
  end
  delta_pathway_map = Hash.new(0)

  if opts[:do_general_stats]
    if results[:deltas].size == 0
      full_pathway_count[results[:maximal_pathway_name]] += 1
    else
      partial_pathway_count[results[:maximal_pathway_name]] += 1      
    end
    struct_count += 1
    next
  end

  delta_branches = []
  delta_sizes = []

  results[:deltas].each { |delta|
    if delta.linkage_at_position
      delta.linkage_at_position.extend(Sugar::IO::CondensedIupac::LinkageWriter)      

      (delta.linkage_at_position.alternative_pathways || []).collect { |p| p.split(',')}.flatten.each { |pw|
        delta_pathway_map[pw] += 1
      }

      maximal_pathways.each { |pw|
        (delta.linkage_at_position.catalysing_genes || []).each { |geneinfo|
          pw.gene_counts[geneinfo.genename] += 1
        }
      }


      if ! results[:deltas].include?(delta.parent)
        epitope_sug = sug.get_sugar_from_residue(delta).extend( Sugar::MultiSugar ).get_unique_sugar
        SugarHelper.SetWriterType(epitope_sug,:ic)
        epitope_seq = epitope_sug.sequence+"("+delta.linkage_at_position.to_sequence+")"+delta.parent.name(:ic)
        
        delta_sizes << epitope_sug.size
        delta_branches << epitope_sug.leaves.size
        
        maximal_pathways.each { |pw|
          reac_sug = results[:maximal_pathway_reaction].endstructure_as_sugar
          SugarHelper.SetWriterType(reac_sug,:ic)
          linkage_path = sug.get_attachment_point_path_to_root(delta)
          linkage_path.delete_at(0)
          Epitope.Factory(pw,epitope_seq).add_substrate Substrate.Factory(linkage_path,reac_sug.sequence)
        }
      end
    end
  }
  
  maximal_pathways.each { |pw|
    if delta_sizes.size > 0
      pw.epitope_size_statistics << delta_sizes
    end
    if delta_branches.size > 0
      pw.epitope_branch_statistics << delta_branches
    end
  }
  
  if results[:maximal_pathway_reaction]
    results[:maximal_pathway_reaction].finish
  end
  if results[:deltas].size > 0
    delta_pathway_map.each { |pw_id,val|
      maximal_pathways.each { |pw|      
        pw.delta_pathway_coverage[pw_id] << (1.0 * val / results[:deltas].size)
      }
    }
  end
  sug.finish()
  
  struct_count += 1  
}


if opts[:do_general_stats]
  OUT_STREAM << "#{res.size} total structures"
  OUT_STREAM << "#{unparsed} Unparsed"
  OUT_STREAM << "Fully matched"
  full_pathway_count.each { |path_name,count|
    OUT_STREAM << "#{path_name},#{count}"
  }
  OUT_STREAM << "Partially matched"  
  partial_pathway_count.each { |path_name,count|
    OUT_STREAM << "#{path_name},#{count}"
  }

  OUT_STREAM << "Masked residues"
  Sugar::IO::GlycoCT::Builder::HIDDEN_RESIDUES.keys.each { |res_name|
    OUT_STREAM << res_name
  }
  exit
end


unmatched_by_root_name = Hash.new() { |h,k| h[k] = Array.new() }

unmatched_structures.each { |r|
  sug = SugarHelper.CreateRenderableSugar(r[0],r[1]).extend( Sugar::MultiSugar ).get_unique_sugar
  SugarHelper.SetWriterType(sug,:ic)
  unmatched_by_root_name[sug.root.name(:id)] << sug.sequence
  sug.finish()
}

OUT_STREAM << "Collated unmatched structures"

unmatched_by_root_name.each { |root,sequences|
  sugars = sequences.collect { |seq| SugarHelper.CreateRenderableSugar(seq,:ic).extend( Sugar::MultiSugar ) }.each { |sug|
    SugarHelper.SetWriterType(sug,:ic)    
  }

  sugar = sugars.shift

  sugars.each { |sug|
    sugar.union!(sug, &MATCH_BLOCK)
  }
  sugar.residue_composition.each { |r|
    r.hits += 1
  }
  def sugar.write_residue(residue)
    return "{#{residue.hits}}#{residue.name(:ic)}"
  end

  OUT_STREAM << "#{root} #{sugar.sequence}"
}

OUT_STREAM << "Summary"
OUT_STREAM << "Total structures: #{res.size}"
OUT_STREAM << "Pathway partial matches"

PathwayResult.Pathways.each {|pw|
  OUT_STREAM << "#{pw.id}"
  OUT_STREAM << ["Resolved","#{pw.resolved_structures}"]
  pw.epitopes_by_number_of_substrates.each { |epitope|
    OUT_STREAM << ["Epitope Sequence","Total number of substrates"]
    OUT_STREAM << ["#{epitope.sequence}","#{epitope.substrates.size}"]
    OUT_STREAM << ["Linkage Path","Substrate","Count"]
    epitope.substrates.uniq.each { |substrate|      
      OUT_STREAM << ["#{substrate.pathway}","#{substrate.sequence}","#{epitope.substrates.select {|i| i == substrate }.size}"]
    }
  }
  
  
  epitope_sizes = pw.epitope_size_statistics
  epitope_branches = pw.epitope_branch_statistics
  number_extensions = epitope_sizes.collect { |attachment_array| attachment_array.size }.uniq
  number_extensions.each { |num_extensions|
    my_extensions = epitope_sizes.reject { |a_array| a_array.size != num_extensions }
    my_branches = epitope_branches.reject { |a_array| a_array.size != num_extensions }
    
    max_size = my_extensions.collect { |a_array| a_array.max }.compact.max
    min_size = my_extensions.collect { |a_array| a_array.min }.compact.min

    max_branch = my_branches.collect { |a_array| a_array.max }.compact.max
    min_branch = my_branches.collect { |a_array| a_array.min }.compact.min

    
    most_freq_size = my_extensions.flatten.sort.group_by { |i| i }.values.sort_by { |a| a.size }.reverse.collect{ |a| "#{a.size}:#{a[0]}"}.join(',')
    most_freq_branch = my_branches.flatten.sort.group_by { |i| i }.values.sort_by { |a| a.size }.reverse.collect{ |a| "#{a.size}:#{a[0]}"}.join(',')

    OUT_STREAM << ["ep_stats","#{pw.id}","#{num_extensions}","#{min_size}","#{max_size}","#{most_freq_size}","#{min_branch}","#{max_branch}","#{most_freq_branch}"]
  }
  
  
  OUT_STREAM << "Delta Matches (coverage of an extension by reactions from one particular pathway)"
  OUT_STREAM << ["Pathway","Coverage"]
  pw.delta_pathway_coverage.keys.each { |pw_id|
    sum = pw.delta_pathway_coverage[pw_id].inject(0) { |sum,val| sum + val }
    if sum > 0
      OUT_STREAM << ["#{pw_id}","#{sum / pw.delta_pathway_coverage[pw_id].size }","#{pw.delta_pathway_coverage[pw_id].size}"]
    else 
      OUT_STREAM << ["#{pw_id}","0"]
    end
  }
  OUT_STREAM << "Gene Matches (number of times a gene matches an extension to a pathway)"
  OUT_STREAM << ["Gene ID","Count"]
  pw.gene_counts.keys.sort_by {|k| pw.gene_counts[k] }.reverse.each { |gene|
    OUT_STREAM << ["#{gene}","#{pw.gene_counts[gene]}"]
  }
  OUT_STREAM << "Epitope composite structures based upon pathway from attachment point to root"  
  path_sugar_cache = Hash.new()
  pw.epitopes_for_each_substrate { |substrate,epitopes|
    substrate_sug = SugarHelper.CreateSugar(substrate.sequence,:ic)
    path_sug = substrate_sug.get_sugar_to_root(substrate_sug.find_residue_by_linkage_path(substrate.pathway_array.reverse)).extend(Sugar::MultiSugar)
    SugarHelper.SetWriterType(path_sug,:ic)
    substrate_res = path_sug.leaves[0]
    epitope_union = nil
    epitopes.each { |epitope|
      if epitope_union
        epitope_union.union!(SugarHelper.CreateMultiSugar(epitope.sequence, :ic),&MATCH_BLOCK) 
      else
        epitope_union = SugarHelper.CreateMultiSugar(epitope.sequence,:ic)
        SugarHelper.SetWriterType(epitope_union,:ic)
      end
    }
    if epitope_union != nil
      SugarHelper.SetWriterType(epitope_union,:ic)
      path_sug_key = path_sug.sequence

      epitope_union.residue_composition.each { |residue|
        residue.hits += 1
      }

      epitope_union.root.children.each { |child|
        substrate_res.add_child(child[:residue],child[:link].deep_clone)
      }
#      if epitope_union.root.children.size > 0
#        substrate_res.hits += epitope_union.root.hits    
#      end
      path_sug_cached = path_sugar_cache[path_sug_key]
      if path_sug_cached        
        path_sug_cached.union!(path_sug,&ADDITION_BLOCK)
      else
        path_sug_cached = path_sug
      end
      path_sugar_cache[path_sug_key] = path_sug_cached
    end
  }
  path_sug_keys = path_sugar_cache.keys
  path_composite = path_sugar_cache[path_sug_keys.shift]
  path_sug_keys.each { |path_sug_key|
    path_sug = path_sugar_cache[path_sug_key]
    render_sugar_with_coverage(path_sug,"#{pw.id}-pw-#{path_sug_key}.svg")  
    path_composite.union!(path_sug,&ADDITION_BLOCK)
  }
  
  if path_composite    
    render_sugar_with_coverage(path_composite,"#{pw.id}-tol-full-combined_substrates.svg")    
    def path_composite.write_residue(residue)
      return "{#{residue.hits}}#{residue.name(:ic)}"
    end
    OUT_STREAM << ["Composite Structure #{pw.id}",path_composite.sequence]
    (3..10).each { |tol|
      path_composite.leaves.each { |residue|
        if residue.hits < tol && residue.hits > 0 && residue.parent
          residue.parent.remove_child(residue)        
        end
      }
      render_sugar_with_coverage(path_composite,"#{pw.id}-tol-#{tol}-combined-substrates.svg")
    }
  end
  
  OUT_STREAM << "Epitopes by Substrate"
  substrate_sugar_cache = Hash.new()  
  OUT_STREAM << ["Substrate Linkage path", "Sequence"]
  pw.epitopes_for_each_substrate { |substrate,epitopes|
    OUT_STREAM << ["#{substrate.pathway}","#{substrate.sequence}"]
    substrate_sug = substrate_sugar_cache[substrate.sequence] || SugarHelper.CreateSugar(substrate.sequence,:ic).extend(Sugar::MultiSugar)
    substrate_sugar_cache[substrate.sequence] = substrate_sug
    substrate_res = substrate_sug.find_residue_by_linkage_path(substrate.pathway_array.reverse)
    epitope_union = nil
    epitopes.each { |epitope|
      if epitope_union
        epitope_union.union!(SugarHelper.CreateMultiSugar(epitope.sequence, :ic),&ADDITION_BLOCK)
      else
        epitope_union = SugarHelper.CreateMultiSugar(epitope.sequence,:ic)
      end
    }
    if epitope_union != nil
  
      epitope_union.residue_composition.each { |residue|
        residue.hits += 1
      }
  
      epitope_union.residue_composition.each { |residue|
       if residue.hits < 5 && residue.parent
         residue.parent.remove_child(residue)
       end
      }
  
      SugarHelper.SetWriterType(epitope_union,:ic)
  
      render_sugar_with_coverage(epitope_union,"#{pw.id}-#{substrate.pathway}-#{substrate.sequence}.svg")
  
      epitope_union.root.children.each { |child|
        substrate_res.add_child(child[:residue],child[:link].deep_clone)
      }
  
#      if epitope_union.root.children.size > 0
#        substrate_res.hits += epitope_union.root.hits    
#      end
  
    end
  }
  OUT_STREAM << "Substrate/Epitope composites"
  substrate_sugar_cache.each { |seq,epitope_union|
    SugarHelper.SetWriterType(epitope_union,:ic)

    render_sugar_with_coverage(epitope_union,"#{pw.id}-#{seq}.svg")

    def epitope_union.write_residue(residue)
      return "{#{residue.hits}}#{residue.name(:ic)}"
    end
    OUT_STREAM << "#{epitope_union.sequence}"
  }  
}

OUT_STREAM << "Masked residues"
Sugar::IO::GlycoCT::Builder::HIDDEN_RESIDUES.keys.each { |res_name|
  OUT_STREAM << res_name
}