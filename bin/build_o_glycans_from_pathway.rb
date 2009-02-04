# This script generates a whole bunch of o-glycans in a Claytons database that can be used
# to generate a virtual database

require File.dirname(__FILE__) + '/script_common'

require 'SugarHelper'

DebugLog.log_level(5)

class Monosaccharide
    def is_3_sialylated?
      false
    end

    def is_6_sialylated?
      false
    end

    def has_aantigen?
      false
    end

    def has_bantigen?
      false
    end

    def has_sdaantigen?
      false
    end

end


module ThreeSialylated
  def is_3_sialylated?
    true
  end
end

module SixSialylated
  def is_6_sialylated?
    true
  end
end

module Aantigen
  def has_aantigen?
    true
  end
end

module Bantigen
  def has_bantigen?
    true
  end
end

module SdaAntigen
  def has_sdaantigen?
    true
  end
end



# Extensions can be defined as
# Extension point + max allowed chain / allowed decorations / max branching

# An extension point is the pathway structure + linkage path to defined extension.

# Allowed extensions

# Multiple attachment points?

def build_chain(sugar,size, residues, linkages)

  start_res = sugar.monosaccharide_factory(residues[-1])
  next_res = nil
  size.times { |i|
    next_res = (next_res || start_res).add_child(sugar.monosaccharide_factory(residues[i % residues.size]), sugar.linkage_factory(linkages[i % linkages.size]))
  }
  
  if next_res != nil
    start_res
  else
    nil
  end
end

class Array

  attr_accessor :combinatorial_class
 
  def combinatorial_execute(setup=nil, cleanup=nil)
    (2**self.size).times { |i|
      setup.call() if setup != nil
      self.size.times { |j|
        if (i & 2**j) > 0
          yield(self[j])
        end
      }
      cleanup.call() if cleanup != nil
    }
  end

end

# Gal(b1-3)GlcNAc(b1-6)
# Gal(b1-4)GlcNAc(b1-6)
# GlcNAc(b1-6)
#

def terminal_type_i_chain(sugar,start_residue)
  results = [start_residue]
  added = []
  to_add = start_residue.residue_composition.select { |residue|
    residue.name(:ic) == 'GlcNAc' &&
    residue.children.size == 0 &&
    residue.paired_residue_position == 3 &&
    residue.parent &&
    residue.parent.paired_residue_position == 4 &&    
    sugar.get_path_to_root(residue.parent).size == 2
  }
  setup_block = lambda {
    added = []
  }
  
  cleanup_block = lambda {
    results << start_residue.deep_clone if added.size > 0
    added.each { |new_mono|
      new_mono.parent.remove_child(new_mono)
      new_mono.finish()
    }    
  }
  to_add.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('Gal'),sugar.linkage_factory('b1-3'))
  }
  results  
end

def iantigenate(sugar,start_residue,link_pos=nil)
  results = [start_residue]
  added = []
  to_add = start_residue.residue_composition.select { |residue|
    residue.name(:ic) == 'Gal' &&
    residue.residue_at_position(6) == nil &&
    residue.parent.name(:ic) == 'GlcNAc' &&
    residue.parent.paired_residue_position != 6
  }
  setup_block = lambda {
    added = []
  }
  
  cleanup_block = lambda {
    results << start_residue.deep_clone if added.size > 0
    added.each { |new_mono|
      new_mono.parent.remove_child(new_mono)
      new_mono.finish()
    }    
  }
  to_add.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('GlcNAc'),sugar.linkage_factory('b1-6'))
    if link_pos != nil
      added[-1].add_child(sugar.monosaccharide_factory('Gal'),sugar.linkage_factory("b1-#{link_pos}"))
    end
  }
  results
end

def fucosylate(sugar,start_residue,linkage)
  results = [start_residue]
  alt_fucose_position = (linkage == 3) ? 4 : 3

  to_fuc = start_residue.residue_composition.select { |residue|
    
    all_descendants = residue.residue_composition.collect { |res| res.name(:ic) }
    all_descendants.shift
    
    residue.name(:ic) == 'GlcNAc' &&
    residue.residue_at_position(linkage) == nil &&
    (residue.residue_at_position(alt_fucose_position) == nil || residue.residue_at_position(alt_fucose_position).name(:ic) != 'Fuc') &&
    (linkage == 3 || ! all_descendants.include?('GlcNAc'))
  }
  added = nil
  
  setup_block = lambda {
    added = []
  }
  
  cleanup_block = lambda {
    results << start_residue.deep_clone if added.size > 0
    added.each { |new_mono|
      new_mono.parent.remove_child(new_mono)
      new_mono.finish()
    }    
  }
  
  
  to_fuc.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('Fuc'),sugar.linkage_factory("a1-#{linkage}"))
  }

  results
end  

def decorate_sialic(sugar,chain,linkage)
  results = [chain]
  leaves = chain.residue_composition.delete_if { |residue| residue.children.size > 0 }
  to_sialylate = leaves.delete_if { |residue| residue.name(:ic) != 'Gal' }
  
  added = nil
  
  setup_block = lambda {
    added = []
  }
  
  resultclass = nil
  
  cleanup_block = lambda {
    if added.size > 0
      results << chain.deep_clone
      results[-1].extend(resultclass)
    end
    added.each { |new_mono|
      new_mono.parent.remove_child(new_mono)
      new_mono.finish()
    }    
  }

  resultclass = linkage == 3 ? ThreeSialylated : SixSialylated

  to_sialylate.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('NeuAc'),sugar.linkage_factory("a2-#{linkage}"))
  } 
  
  results
  # add terminal epitopes SDa, AB antigen, Lacdinac
end

def decorate_sda_epitopes(sugar,chain)
  results = [chain]
  leaves = chain.residue_composition.delete_if { |residue| residue.children.size > 0 }
  to_sda = leaves.delete_if { |residue| residue.name(:ic) != 'NeuAc' || residue.parent.name(:ic) != 'Gal' || residue.paired_residue_position != 3 }
  
  added = nil
  
  setup_block = lambda {
    added = []
  }
  
  cleanup_block = lambda {
    if added.size > 0
      results << chain.deep_clone
      results[-1].extend(SdaAntigen)
    end
    added.each { |new_mono|
      new_mono.parent.remove_child(new_mono)
      new_mono.finish()
    }    
  }

  to_sda.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.parent.add_child(sugar.monosaccharide_factory('GalNAc'),sugar.linkage_factory('b1-4'))
  } 
  
  results  
end

def decorate_abo_epitopes(sugar,chain)
  results = [chain]
  leaves = chain.residue_composition.delete_if { |residue| residue.children.size > 0 }
  to_abo = leaves.delete_if { |residue| residue.name(:ic) != 'Gal' }
  
  added = nil
  
  setup_block = lambda {
    # Tag the chain with the class of the addition applied to it, easier for sorting out the stuff after
    added = []
  }
  
  resultclass = nil

  cleanup_block = lambda {
    if added.size > 0
      results << chain.deep_clone
      results[-1].extend(resultclass)
    end
    added.each { |new_mono|
      new_mono.parent.remove_child(new_mono)
      new_mono.finish()
    }
  }

  resultclass = Aantigen

  to_abo.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('GalNAc'),sugar.linkage_factory('a1-3'))
    added << element.add_child(sugar.monosaccharide_factory('Fuc'),sugar.linkage_factory('a1-2'))
  } 

  resultclass = Bantigen

  to_abo.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('Gal'),sugar.linkage_factory('a1-3'))
    added << element.add_child(sugar.monosaccharide_factory('Fuc'),sugar.linkage_factory('a1-2'))
  } 
  
  results  
end


# What to do with first addition Gal(b1-3)GalNAc, need to skip all chains that don't start
# with Gal(b1-3)GlcNAc.....

chains = []
sequences = 
[
  ['Gal(b1-3)GalNAc',[[3]]],
  ['GlcNAc(b1-3)Gal(b1-3)GalNAc',[[3,3]]],
  ['GlcNAc(b1-6)Gal(b1-3)GalNAc',[[3,6]]],
  ['GlcNAc(b1-3)GalNAc',[[3]]],
  ['GlcNAc(b1-6)GalNAc',[[6]]],
  ['Gal(b1-3)[GlcNAc(b1-6)]GalNAc',[[3],[6]]],
  ['GlcNAc(b1-3)Gal(b1-3)[GlcNAc(b1-6)]GalNAc',[[3,3],[6]]],
  ['GlcNAc(b1-6)Gal(b1-3)[GlcNAc(b1-6)]GalNAc',[[3,6],[6]]],
  ['GlcNAc(b1-3)[GlcNAc(b1-6)]GalNAc',[[3],[6]]]
]

sugars = sequences.collect { |sequence,positions|
  sug = SugarHelper.CreateSugar(sequence,:ic)
  SugarHelper.SetWriterType(sug,:ic)
  positions = positions.collect { |path| sug.find_residue_by_linkage_path(path)}
  [sug,positions]
}

sugar = SugarHelper.CreateSugar('Man(a1-3)[Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc',:ic)

2.times { |size|
  chains << build_chain(sugar,size,['Gal','GlcNAc'],['b1-3','b1-3'])
}
3.times { |size|
  chains << build_chain(sugar,size,['Gal','GlcNAc'],['b1-4','b1-3'])
}

p chains.size

chains.compact!

chains = chains.flatten.collect { |chain|
  iantigenate(sugar,chain)
}.flatten

chains = chains.flatten.collect { |chain|
  iantigenate(sugar,chain,3)
}.flatten

chains = chains.flatten.collect { |chain|
  iantigenate(sugar,chain,4)
}.flatten

chains = chains.flatten.collect { |chain|
  terminal_type_i_chain(sugar,chain)
}.flatten

chains = chains.flatten.collect { |chain|
  fucosylate(sugar,chain,3)
}.flatten

chains = chains.flatten.collect { |chain|
  fucosylate(sugar,chain,4)
}.flatten

chains = chains.flatten.collect { |chain|
  decorate_sialic(sugar,chain,3)
}.flatten

chains = chains.flatten.collect { |chain|
  decorate_sialic(sugar,chain,6)
}.flatten

chains = chains.flatten.collect { |chain|
  decorate_sda_epitopes(sugar,chain)
}.flatten

chains = chains.flatten.collect { |chain|
  decorate_abo_epitopes(sugar,chain)
}.flatten


# Split chains into SDa, A, B and NeuAc decoration groups. We should only be able to select 
# chains from the same groups. SDa is a subset of the NeuAc a2-3 group

chains = chains.flatten.compact

c_a_antigens = chains.select { |c| c.has_aantigen? }
c_b_antigens = chains.select { |c| c.has_bantigen? }
c_no_antigen = (chains - c_a_antigens) - c_b_antigens

c_a_antigens += c_no_antigen + [nil]
c_b_antigens += c_no_antigen + [nil]

# Select sequences from each of these groups, and apply them combinatorially to all the attachment points for a
# particular point along the pathway. Binary selection says whether that particular point is occupied by an 
# extension or not.


p "Total chains #{chains.size}"
p c_a_antigens.size
p c_b_antigens.size

sug_results = []

def combinations array, n
  result = []
  if n > 0
    (0 .. array.length - n).each do |i|
      combs = [[]] if (combs = combinations(array[i + 1 .. -1], n - 1)).empty?
      combs.collect {|comb| [array[i]] + comb}.each {|x| result << x}
    end
  end
  result
end

class Array
  
  def product(*others)
    arrays = [ self.map {|i| [i] } ].concat(others)
    arrays.inject do |result, item|
      (result * item).map do |t| 
        t[0].dup << t[1] 
      end
    end
  end
  
  def multiplication_operator_with_product(other)
    unless other.kind_of? Array 
      multiplication_operator_without_product(other)
    else 
      self.inject([]) do |ret, i|
        ret.concat( other.map {|j| [i, j]} )
      end
    end
  end
  
  def self_product(times)
    self.product(*([self] * (times - 1)))
  end
  
  alias_method :multiplication_operator_without_product, :*
  alias_method :*, :multiplication_operator_with_product

end

OUT_STREAM = File.new('seq_results.txt','w')
sugar_count = 0

sugars.each { |sug,attachment_points|
  c_a_antigens.self_product(attachment_points.size)+c_b_antigens.self_product(attachment_points.size).each { |leaf_chains|
    added = []
    (0 .. (attachment_points.size-1)).to_a.each { |leaf_id|
      if leaf_chains[leaf_id] != nil
        chain = leaf_chains[leaf_id]
        if attachment_points[leaf_id].name(:ic) == 'GlcNAc'
          chain.children.each { |kid|
            kid_res = kid[:residue]
            added << attachment_points[leaf_id].add_child(kid_res.deep_clone,sugar.linkage_factory(kid_res.anomer+"#{kid_res.parent_position}-#{kid_res.paired_residue_position}"))
          }
        end
        
        if attachment_points[leaf_id].name(:ic) == 'Gal'
          if chain.children.size == 1
            to_add = chain.residue_at_position(4) #Only add type II chains, type I chains are a subset.
            non_glcnacs = to_add != nil ? to_add.children.select { |kid| kid[:residue].name(:ic) != 'GlcNAc' } : []
            if non_glcnacs.size > 0 && non_glcnacs.size == to_add.children.size
              non_glcnacs.each { |kid|
                kid_res = kid[:residue]
                added << attachment_points[leaf_id].add_child(kid_res.deep_clone,sugar.linkage_factory(kid_res.anomer+"#{kid_res.parent_position}-#{kid_res.paired_residue_position}"))
              }
            else
              added.each { |new_mono|
                new_mono.parent.remove_child(new_mono)
                new_mono.finish()
              }
              added = []
              break
            end
          else
            added.each { |new_mono|
              new_mono.parent.remove_child(new_mono)
              new_mono.finish()
            }            
            added = []
            break
          end
        end  
      end
    }
    if added.size > 0
      OUT_STREAM << sug.sequence+"\n"
      sugar_count += 1
      p sugar_count
    end
    added.each { |new_mono|
      new_mono.parent.remove_child(new_mono)
      new_mono.finish()
    }
  }
  sug.finish()
}