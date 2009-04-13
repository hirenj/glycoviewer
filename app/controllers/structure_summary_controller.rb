module HitCounter
  attr_accessor :hits
  
  def hits
    get_counter(:id).size
  end 
  def seen_structures
    get_counter(:id)
  end
  
  def counter_keys
    initialise_counter unless @counters
    return @counters.keys
  end

  def reset_counters
    @counters = nil
    initialise_counter
  end

  def initialise_counter(id_key=:id)
    @counters = @counters || Hash.new() { |h,k| h[k] = Array.new() }
  end
  
  def increment_counter(value,id_key=:id)
    @counters[id_key] << value
  end
  
  def get_counter(id_key=:id)
    initialise_counter unless @counters
    @counters[id_key]
  end
  
  def merge_counter(other_residue,id_key=:id)
    @counters[id_key].concat(other_residue.get_counter(id_key))
    @counters[id_key].uniq!
  end
  
  MATCH_BLOCK = lambda { |residue,other_res,matched_yet|
    if residue.equals?(other_res)
      if ! matched_yet && residue.is_a?(HitCounter)
        residue.counter_keys.each { |key|
          residue.merge_counter(other_res,key)
        }
      end
      true
    else
      false
    end
  }
  
end

module SummaryStatisticCollectors
  class ResultCollector
    def key
      @identifier
    end
    
    def results(sugar)
      @results[sugar.object_id]
    end
    
    def examine(sug,sugar)
      @examiner.call(sug,sugar)
    end
    
    def append_statistic_cleanup_method(&block)
      @statistic_cleanup_methods << block
    end
    
    def clean_statistics(sugar)
      @statistic_cleanup_methods.each { |meth|
        meth.call(sugar)
      }
    end
    
    def reset
      @results = Hash.new() {|h,k| h[k] = Array.new() }
    end
    
    def initialize(identifier=nil,&block)
      @identifier = identifier
      @examiner = block
      @statistic_cleanup_methods = []
      @results = Hash.new() {|h,k| h[k] = Array.new() }
    end
  end

  # Branch point comparison
  # For each branch point for the new sugar collect
  #    get the unambiguous path to root for the branch point
  #    find the analgous residue in the target sugar
  # end
  # Update the counter hash for each branch point
  # counts[a_branch_point][co-occuring_branch_point] += 1
  # counts[a_branch_point][self] += 1
  #
  # Profit!
  
  def branch_collector

    rc = ResultCollector.new(:branch_points) { |sug,sugar|
      branch_points = sug.branch_points
      [ branch_points.collect { |r| sugar.find_residue_by_unambiguous_path(sug.get_unambiguous_path_to_root(r).reverse) } ]
    }
    
    rc.append_statistic_cleanup_method { |sugar|
      sugar_residues = sugar.residue_composition
      branch_points_totals = sugar.collected_statistics[:branch_points]

      branch_totals_by_point = {}
      branch_points_totals.each { |branching_rec|
        branching_rec.each { |point|
          branch_totals_by_point[point] ||= {}
          branching_rec.each { |other_point|
            branch_totals_by_point[point][other_point] ||= 0
            branch_totals_by_point[point][other_point] += 1            
          }
        }
      }

      sugar.collected_statistics[:branch_totals_by_point] = branch_totals_by_point

      branch_totals_by_point.keys.each { |bp|
        unless sugar_residues.include? bp
            branch_totals_by_point.delete(bp)
        end
      }

      all_ids = branch_totals_by_point.keys.collect { |bp|
        bp.seen_structures
      }.flatten.sort

      zero_count = sugar.root.hits
      sizes = {}
      all_id_sizes = all_ids.group_by { |i| i }.collect { |arr| arr[1].size }.group_by { |i| i }.each { |b_num,scount|
        sizes[b_num] = scount.size
        zero_count -= scount.size
      }
      sizes[0] = zero_count

      sugar.collected_statistics[:branch_points_count] = sizes        
    }
    
    rc
  end

  def fuc_cap_average_collector
    ResultCollector.new(:fuc_capping) { |sug,sugar|
      all_leaves = sug.leaves
      fuc_leaves = all_leaves.select { |r| r.name(:ic) == 'Fuc' && r.parent && r.parent.name(:ic) == 'Gal' }
      gal_leaves = all_leaves.select { |r|
        ['Gal','GalNAc'].include?(r.name(:ic)) && r.anomer != 'a'          
      }

      if fuc_leaves.size > 0
        [ fuc_leaves.size.to_f / (gal_leaves.size + fuc_leaves.size) ]
      else
        nil
      end
    }
  end

  def neuac_cap_average_collector
    ResultCollector.new(:neuac_capping) { |sug,sugar|
      all_leaves = sug.leaves
      neuac_leaves = all_leaves.select { |r| r.name(:ic) == 'NeuAc' }
      gal_leaves = all_leaves.select { |r|
        ['Gal','GalNAc'].include?(r.name(:ic)) && r.anomer != 'a'          
      }

      if neuac_leaves.size > 0
        [ neuac_leaves.size.to_f / (gal_leaves.size + neuac_leaves.size) ]
      else
        nil
      end
    }
  end
  
  def fuc_collector
    rc = ResultCollector.new(:terminal_fucoses) { |sug,sugar|
      all_leaves = sug.leaves
      fuc_leaves = all_leaves.select { |r| r.name(:ic) == 'Fuc' && r != sug.root }

      fuc_leaves.select { |fuc| fuc.siblings.reject { |r| r.anomer == 'a' && ['Gal','GalNAc'].include?(r.name(:ic))}.size == 0 }.collect { |fuc|
        sugar.find_residue_by_unambiguous_path(sug.get_unambiguous_path_to_root(fuc).reverse)
      }
    }
    rc.append_statistic_cleanup_method { |sugar|
      sugar_residues = sugar.residue_composition

      terminal_fucoses = sugar.collected_statistics[:terminal_fucoses]

      terminal_fucoses.each { |r|
        unless sugar_residues.include? r
            terminal_fucoses.delete(r)
        end        
      }
    }
    rc
  end

  def neuac_collector
    rc = ResultCollector.new(:terminal_neuacs) { |sug,sugar|
      all_leaves = sug.leaves
      neuac_leaves = all_leaves.select { |r| r.name(:ic) == 'NeuAc' && r.parent != nil }

      neuac_leaves.select { |neuac| neuac.siblings.reject { |r| ['GalNAc'].include?(r.name(:ic)) }.size == 0 }.collect { |neuac|
        sugar.find_residue_by_unambiguous_path(sug.get_unambiguous_path_to_root(neuac).reverse)
      }
    }
    rc.append_statistic_cleanup_method { |sugar|
      sugar_residues = sugar.residue_composition
      terminal_sialics = sugar.collected_statistics[:terminal_neuacs]
      terminal_sialics.each { |r|
        unless sugar_residues.include? r
            terminal_sialics.delete(r)
        end        
      }
    }
    rc
  end

end

class StructureSummaryController < ApplicationController
  include SummaryStatisticCollectors

  attr_accessor :statistic_collectors

  def gather_stats(sugar)
    results = Hash.new() { |h,k| h[k] = Array.new() }
    (statistic_collectors || []).each { |collector|
      results[collector.key] = collector.results(sugar)
    }
    results
  end

  def reset_stats
    (statistic_collectors || []).each { |collector|
      collector.reset
    }
  end
  
  module SummaryStats

    def reference_count
      self.residue_composition.collect { |r|
        r.get_counter(:ref)
      }.flatten.uniq.size
    end
  
    attr_accessor :collected_statistics
      
  end
  
  def perform_pruning(sugar)
  end

  def execute_summary_for_sugars(individual_sugars,prune_structure=true)
    return unless individual_sugars
    
    sugar_sets = individual_sugars.sort_by{ |s| s.root.name }.group_by { |s| s.root.name }.collect { |name,sugs| sugs }

    return sugar_sets.collect { |sugar_set|

      sugar = sugar_set.shift

      if sugar == nil
        next
      end

      sugar = sugar.extend(SummaryStats)

      ([sugar]+sugar_set).each { |sug|
        if sug != sugar
          sug.extend(CachingSugar)
          sugar.union!(sug,&HitCounter::MATCH_BLOCK)
          sugar.residue_composition.each { |r|
              r.get_counter(:genes)
          }
        end

        (statistic_collectors || []).each { |collector|
          collector.results(sugar).concat(collector.examine(sug,sugar))
        }

      }

      coverage_finder = EnzymeCoverageController.new()
      coverage_finder.sugar = sugar
      sugar.root.anomer = 'u'

      SugarHelper.MakeRenderable(sugar)
      sugar.extend(CachingSugar)

      coverage_finder.execute_pathways_and_markup

      perform_pruning(sugar) if prune_structure


      sugar.collected_statistics = gather_stats(sugar)

      (statistic_collectors || []).each { |collector|
        collector.clean_statistics(sugar)
        
        collector.reset
      }
      sugar
    }.compact
  end

  def markup_sugarset(sugarset)
    sugarset.each { |sugar|
      markup_chains(sugar)
    }
  end

  def markup_chains(sugar)
    all_gals = sugar.residue_composition.select { |r| r.name(:ic) == 'Gal' && r.parent && r.parent.name(:ic) == 'GlcNAc' }
    type_i = all_gals.select { |r| r.paired_residue_position == 3 }
    type_ii = all_gals.select { |r| r.paired_residue_position == 4 }
    all_glcnacs = sugar.residue_composition.select { |r| r.name(:ic) == 'GlcNAc' && r.parent && r.parent.name(:ic) == 'Gal' }
    type_i_glcnac = all_glcnacs.select { |r| (r.paired_residue_position == 3) && r.parent.paired_residue_position == 3 && (! r.parent.parent || r.parent.parent != sugar.root) }
    type_ii_glcnac = all_glcnacs.select { |r| (r.paired_residue_position == 3) && r.parent.paired_residue_position == 4 }
    branching = all_glcnacs.select { |r| r.paired_residue_position == 6 }

    sugar.callbacks << lambda { |sug_root,renderer|
      renderer.chain_background_width = 20
      renderer.chain_background_padding = 65
      renderer.render_simplified_chains(sugar,[type_i+type_i_glcnac],'sugar_chain sugar_chain_type_i','#FFEFD8')
      renderer.render_simplified_chains(sugar,[type_ii+type_ii_glcnac],'sugar_chain sugar_chain_type_ii','#C9F6C6')
      renderer.render_simplified_chains(sugar,[branching],'sugar_chain sugar_chain_branching','#cc99ff')
    }
  end

  def markup_reference_counts(sugar)
    sugar.residue_composition.select { |r|
      sugar.residue_height(r) <= 1 && r.name(:ic) == 'Gal' && r.anomer == 'b'
    }.each { |r|
      r.callbacks << lambda { |element|
        render_text_residue_label(sugar,r,r.get_counter(:ref).uniq.size,:bottom_left)
      }
    }
  end
      
  def markup_branch_points(sugar)
    branch_totals_by_point = sugar.collected_statistics[:branch_totals_by_point] || return

    labels = ('A'..'Z').to_a.reverse
    branch_totals_by_point.keys.each { |bp|
      sort_key = sugar.depth(bp).to_s+'|'+sugar.get_unambiguous_path_to_root(bp).collect {|path| path[:residue].paired_residue_position.to_s+path[:residue].name(:ic) }.join(',')
      def bp.sort_key=(key)
        @sort_key = key
      end
      def bp.sort_key
        @sort_key
      end
      bp.sort_key = sort_key
    }
    branch_totals_by_point.keys.sort_by { |bp|
      bp.sort_key
    }.each { |bp|
      branch_label_text = labels.shift
      def bp.branch_label
        @branch_label
      end
      def bp.branch_label=(new_label)
       @branch_label = new_label
      end
      bp.branch_label = branch_label_text
      sugar.callbacks << lambda { |sug_root,renderer|
        if sugar.residue_composition.include?(bp)
          renderer.render_text_residue_label(sugar,bp,bp.branch_label,:top_right)
          renderer.render_text_residue_label(sugar,bp,bp.hits,:bottom_right)
        end
      }
      bp.callbacks << lambda { |element|
        render_text_residue_label(sugar,bp,bp.get_counter(:ref).uniq.size,:bottom_left)
      }
    }      
  end
end
