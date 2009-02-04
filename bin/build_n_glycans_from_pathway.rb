# This script generates a whole bunch of n-glycans in a Claytons database that can be used
# to generate a virtual database

require File.dirname(__FILE__) + '/script_common'

require 'SugarHelper'

DebugLog.log_level(5)

class Monosaccharide
  
    attr_accessor :chain_size
  
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

    def has_oantigen?
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

module Oantigen
  def has_oantigen?
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
# Sequence#Attachment point#Chain Type{Branches}
# Man(a1-3)[Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc#446#I{2}II{2}

# Multiple attachment points?

def build_chain(sugar,size, residues, linkages)

  start_res = sugar.monosaccharide_factory(residues[-1])
  next_res = nil
  size.times { |i|
    next_res = (next_res || start_res).add_child(sugar.monosaccharide_factory(residues[i % residues.size]), sugar.linkage_factory(linkages[i % linkages.size]))
  }
  start_res.chain_size = size
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


def fucosylate(sugar,start_residue,linkage)
  results = [start_residue]
  alt_fucose_position = (linkage == 3) ? 4 : 3

  to_fuc = start_residue.residue_composition.select { |residue|
    
    
    all_descendants = residue.residue_composition.collect { |res| res.name(:ic) }
    all_descendants.shift
    
    residue.name(:ic) == 'GlcNAc' && # Only fucosylate on GlcNAcs
    residue.residue_at_position(linkage) == nil && # Only fucosylate at empty positions
    (residue.residue_at_position(alt_fucose_position) == nil || residue.residue_at_position(alt_fucose_position).name(:ic) != 'Fuc') && # Don't doubly fucosylate
    (! all_descendants.include?('GlcNAc')) # Only allow terminal or penultimate Fucosylation events Stroop et al say there is a structure with a non-terminal 3-fucosylation
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

def decorate_sialic(sugar,chain)
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

  resultclass = ThreeSialylated

  to_sialylate.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('NeuAc'),sugar.linkage_factory('a2-3'))
  } 

  resultclass = SixSialylated

  to_sialylate.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('NeuAc'),sugar.linkage_factory('a2-6'))
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

  resultclass = Oantigen

  to_abo.combinatorial_execute(setup_block,cleanup_block) { |element|
    added << element.add_child(sugar.monosaccharide_factory('Fuc'),sugar.linkage_factory('a1-2'))
  } 

  
  results  
end


chains = []
sequences = 
[
['GlcNAc(b1-2)Man(a1-3)[Man(a1-3)[Man(a1-6)]Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc',[[4,4,3,2]]],
['GlcNAc(b1-2)Man(a1-3)[Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc',[[4,4,3,2]]],
['Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc',[[4,4,6,2]]],
['GlcNAc(b1-2)Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc',[[4,4,3,2],[4,4,6,2]]],
['GlcNAc(b1-2)Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc',[[4,4,3,2],[4,4,6,2]]],
['GlcNAc(b1-2)Man(a1-3)[GlcNAc(b1-2)Man(a1-6)][GlcNAc(b1-4)]Man(b1-4)GlcNAc(b1-4)GlcNAc',[[4,4,3,2],[4,4,6,2]]],
['GlcNAc(b1-2)[GlcNAc(b1-4)]Man(a1-3)[GlcNAc(b1-2)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc',[[4,4,3,2],[4,4,3,4],[4,4,6,2]]],
['GlcNAc(b1-2)[GlcNAc(b1-4)]Man(a1-3)[GlcNAc(b1-2)[GlcNAc(b1-6)]Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc',[[4,4,3,2],[4,4,3,4],[4,4,6,2],[4,4,6,6]]],
['GlcNAc(b1-2)[GlcNAc(b1-4)]Man(a1-3)[GlcNAc(b1-2)[GlcNAc(b1-6)][GlcNAc(b1-4)]Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc',[[4,4,3,2],[4,4,3,4],[4,4,6,2],[4,4,6,6],[4,4,6,4]]]
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
4.times { |size|
  chains << build_chain(sugar,size,['Gal','GlcNAc'],['b1-4','b1-3'])
}

chains.compact!

# FUT3 activity on a1-4, less on a1-3
# FUT4 pretty much anywhere on a1-3
# FUT5 on 3/4 pref. 3 with a1-2 fucosylation
# FUT6 only on 3 anywhere on chain
# FUT7 only on terminal XXX(xx-x)Gal(b1-4)GlcNAc
# FUT9 only 3 on unfucosylated chains

chains = chains.collect { |chain|
  fucosylate(sugar,chain,3)
}.flatten

chains = chains.flatten.collect { |chain|
  fucosylate(sugar,chain,4)
}.flatten

chains = chains.flatten.collect { |chain|
  decorate_sialic(sugar,chain)
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


p chains.size
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

OUT_STREAM = File.new('seq_results_n_linked.txt','w')
sugar_count = 0

sugar_number = 0
sugars.each { |sug,attachment_points|
  sugar_number += 1
  a_list = c_a_antigens.select { |c| attachment_points.size < 4 || c == nil || c.chain_size < 3 }
  b_list = c_b_antigens.select { |c| attachment_points.size < 4 || c == nil || c.chain_size < 3 }
  total_attachment_points = (a_list.self_product(attachment_points.size)+b_list.self_product(attachment_points.size))
  completed_attachment_points = 0
  total_attachment_points.each {|leaf_chains|
    completed_attachment_points += 1
    added = []
    (0 .. (attachment_points.size-1)).to_a.each { |leaf_id|
      if leaf_chains[leaf_id] != nil
        chain = leaf_chains[leaf_id]
        if chain.name(:ic) == 'GlcNAc'
          chain.children.each { |kid|
            kid_res = kid[:residue]
            added << attachment_points[leaf_id].add_child(kid_res.deep_clone,sugar.linkage_factory(kid_res.anomer+"1-#{kid_res.paired_residue_position}"))
          }
        end
      end
    }
    if added.size > 0
      OUT_STREAM << sug.sequence+"\n"
      sugar_count += 1
      puts "\e[1F\e[KCompleted of #{completed_attachment_points}/#{total_attachment_points.size} for Sugar #{sugar_number}/#{sugars.size} Total completed: #{sugar_count}"
    end
    added.each { |new_mono|
      new_mono.parent.remove_child(new_mono)
      new_mono.finish()
    }
  }
  sug.finish()
}