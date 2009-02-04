#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'script_common')

# This script checks the pathway coverage of structures

require 'lax_residue_names'

target_path = [6,4,6,4,6]
@all_terminals = []

@seen_residue = {}

def find_chains_for_glcnac(start)
  type1 = start.residue_at_position(3)
  type2 = start.residue_at_position(4)
  my_chains = []
  if type1 && type1.name(:ic) == 'Gal'
    @seen_residue[type1] = true
#    chain_type = (type2 && type2.name(:ic) == 'Fuc') ? '1F' : '1'
    chain_type = '1'
    new_chains = find_chains_for_gal(type1).collect {|arr| [chain_type] + arr }    
    if new_chains.size == 0
      new_chains = [[chain_type]]
    end
    my_chains += new_chains
  end
  if type2 && type2.name(:ic) == 'Gal'
    @seen_residue[type2] = true
#    chain_type = (type1 && type1.name(:ic) == 'Fuc') ? '2F' : '2'
    chain_type = '2'
    new_chains = find_chains_for_gal(type2).collect {|arr| [chain_type] + arr }
    if new_chains.size == 0
      new_chains = [[chain_type]]
    end
    my_chains += new_chains
  end
  
  return my_chains
end

def find_chains_for_gal(start)
  type3 = start.residue_at_position(3)
  type6 = start.residue_at_position(6)
  my_chains = []
  if type3 && type3.name(:ic) == 'GlcNAc'
    @seen_residue[type3] = true
    new_chains = find_chains_for_glcnac(type3).collect {|arr| ['3'] + arr }
    if new_chains.size == 0
      new_chains = [['3']]
    end
    my_chains += new_chains
  end
  if type6 && type6.name(:ic) == 'GlcNAc'
    @seen_residue[type6] = true
    new_chains = find_chains_for_glcnac(type6).collect {|arr| ['6'] + arr }
    if new_chains.size == 0
      new_chains = [['6']]
    end
    my_chains += new_chains
  end
  if my_chains.size == 0
    @all_terminals << start
  end 
  return my_chains
end

chains = []

chain_counts = Array.new()

sequences = []

# File.open("data/glycomedb-data","r") do |file|
#   seq = ''
#   id = 0
#   while (line = file.gets)
#     if (line == "--\n")
#       sequences << [seq,:glycoct]
#     else
#       if /(\d+)\|\|RES/.match(line)
#         seq = "RES\n"
#         id = $~[1]
#       else
#         seq += line
#       end
#     end
#   end
# end

sequences = IO.read('data/human_glycosuite_uniq.txt').split("\n").collect { |struct|
  struct.gsub!( /\(\?/,'(u')
  struct.gsub!( /\(-/,'(u1-')
  struct.gsub!( /\{?[j\,k]\}?/,'')
  struct.gsub!(/\{/,'')
  struct.gsub!(/\}/,'')
  struct.gsub!(/\+".*"$/,'')
  struct
}.collect { |r| [r, :ic] }

sequences.each do |seq|    
      sug = nil
      begin
        sug = SugarHelper.CreateSugar(seq[0],seq[1])
      rescue SugarException => e
        #puts id
        next
      end
      
      SugarHelper.SetWriterType(sug,:ic)
            
      my_chains = []
      
      @all_terminals = []
      
      # Find chains
      @seen_residue = {}

      sug.breadth_first_traversal { |res|
        if res.name(:ic) == 'GlcNAc' && ! @seen_residue[res]
          my_chains += find_chains_for_glcnac(res).collect { |arr| [sug.root.name(:ic)]+arr}
        end
        if res.name(:ic) == 'Gal' && ! @seen_residue[res]
          my_chains += find_chains_for_gal(res).collect { |arr| [sug.root.name(:ic)]+arr}
        end
      }

      seen_terms = {}
      @all_terminals.each { |term| seen_terms[sug.sequence_from_residue(term)] = 1 }
#      p seen_terms.keys

      my_chains = my_chains.sort_by { |c| c.size }

      p my_chains.collect { |c| c.join(',') }.uniq.sort
      chain_counts[my_chains.size] ||= Array.new()
      loop_array = chain_counts[my_chains.size]
      my_chains.each { |chain|        
        loop_array[(chain.size/2).floor] ||= Array.new()
        loop_array = loop_array[(chain.size/2).floor]
      }
      loop_array[0] ||= 0
      loop_array[0] += 1

      chains += my_chains

      # sug.input_namespace = nil
      # SugarHelper.SetWriterType(sug,:ic)
      # p [ id, sug.root.name(:ic) ] + sug.composition_of_residue('ic:Fuc').delete_if { |res| res.paired_residue_position != 2 }.collect { |r| r.siblings.collect { |sib| sib.name(:ic) }.join(',') }
      
      # if sug.root.name(:ic) == 'GalNAc' && res = sug.find_residue_by_linkage_path(target_path)
      #   if res.name(:ic) == 'GlcNAc'
      #     puts id
      #   end
      # end
      sug.finish
end

seen_chains = Hash.new() { |h,k| h[k] = 0 }

chains.collect { |arr| arr.join(',')}.each { |chain|
  seen_chains[chain] += 1
}
seen_chains.keys.sort_by { |k| seen_chains[k] }.reverse.each { |k|
  puts "#{k}  #{seen_chains[k]}"
}

def print_chain(chain=[])
  if chain == nil || chain.size == 0
    return []
  end
  if chain.size == 1
    return [" = #{chain[0]}"]
  end
  return (1..5).collect { |i|
    print_chain(chain[i]).collect { |res|
      "#{i},#{res}"
    }
  }.flatten
end


(0..6).each { |i|
  puts print_chain(chain_counts[i]).join("\n")
}


