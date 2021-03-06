require 'SugarHelper'
require 'SugarUtil'

class EnzymeCoverageController < ApplicationController
  layout 'standard'
  
  module ResolvedLinkage
    attr_accessor :associated_reactions
  end
  
  module ValidityTest
    @valid = true
    def invalidate
      @valid = false
    end
    
    def validate
      @valid = true
    end
    
    def is_valid?
      @valid
    end
  end
  
  module EndStructureAsSugar
    def endstructure_as_sugar
      if @endstructure_as_sugar != nil
        return @endstructure_as_sugar
      end
      @endstructure_as_sugar = as_sugar(endstructure)
    end
    def finish
      if @endstructure_as_sugar != nil
        @endstructure_as_sugar.finish()
        @endstructure_as_sugar = nil
      end
    end
  end
  
  module PathwayLinkage
    attr_accessor :alternative_pathways
    attr_accessor :catalysing_genes
  end
  
  attr_accessor :sugar
  
  after_filter :garbage_collect

  def index
    if params[:seq] == nil
      params[:seq] = 'Nil'
      params[:ns] = 'ic'
    end
    self.sugar = params[:seq]
    @seq = self.sugar.sequence
    @ns = params[:ns]
  end

  def pathways
    self.sugar = params[:seq]
    self.sugar.root.anomer = 'u'
    
    execute_pathways_and_markup()
    
    add_sugar_callbacks()
    
    render :action => 'pathway_coverage', :content_type => Mime::XHTML
    sugar.finish()
  end

  def execute_pathways_and_markup
    best_result_size = nil
    best_results = nil
    
    self.sugar.residue_composition.each { |r|
      r.extend(ValidityTest)
    }
    all_results = execute_pathways
    all_results.each { |results|

      self.sugar.residue_composition.each { |r|
        r.validate
      }

      validate_residues_for_results(results)

      result_size = self.sugar.residue_composition.reject { |r| r.is_valid? }.size
      if best_result_size == nil || result_size < best_result_size        
        best_result_size = result_size
        best_results = results
      end
    }

    self.sugar.residue_composition.each { |r|
      r.validate
    }

    self.sugar.linkages.each {|link|
      link.extend(ValidityTest)
      link.validate
    }

    validate_residues_for_results(best_results)
    
    if params && params[:mesh_tissue] != nil && params[:mesh_tissue] != ''
      gene_results = execute_genecoverage(params[:mesh_tissue])
      logger.info("Total number of bad linkages #{gene_results.size}")
      markup_linkages(gene_results)
    end
  end

  def add_sugar_callbacks
    logger.info("Total of #{@chains.size} chains")
    self.sugar.callbacks << lambda { |sug_root,renderer|
      renderer.chain_background_width = 20
      renderer.chain_background_padding = 65
      renderer.render_valid_decorations(sugar,@valid_residues)
      renderer.render_invalid_decorations(sugar,@invalid_residues)
      renderer.render_chains(sugar,@chains,'sugar_chain')
    }

  end

  def markup_linkages(linkages)
    sug = self.sugar

    shadow_filter = Element.new('svg:filter')
    shadow_filter.add_attributes({'id' => 'drop-shadow'})
    el = Element.new('svg:feGaussianBlur')
    el.add_attributes({ 'in' => 'SourceAlpha', 'result' => 'blur-out', 'stdDeviation' => '10' })
    shadow_filter.add_element(el)
    el = Element.new('svg:feOffset')
    el.add_attributes({ 'in' => 'blur-out', 'result' => 'the-shadow', 'dx' => '8', 'dy' => '8' })
    shadow_filter.add_element(el)
    el = Element.new('svg:feBlend')
    el.add_attributes({ 'in' => 'SourceGraphic', 'in2' => 'the-shadow', 'mode' => 'normal' })
    shadow_filter.add_element(el)
    new_defs = Element.new('svg:defs')
    new_defs.add_element(shadow_filter)
    sugar.overlays << new_defs
    
    gene_overlay = Element.new('svg:g')
    gene_overlay.add_attributes({'class' => 'gene_overlay'})
    sugar.overlays.insert(0,gene_overlay)
    linkages.each { |link|
      genes = link.genes
      link.callbacks.push( lambda { |link_element|

        bad_linkage = Element.new('svg:g')
        bad_linkage.add_attributes({'id' => "link-#{link_element.object_id}" })
        
        x1 = -1*(link.center[:x] - 20)
        y1 = -1*(link.center[:y] - 20)
        x2 = -1*(link.center[:x] + 20)
        y2 = -1*(link.center[:y] + 20)
        x3 = -1*(link.center[:x] - 20)
        y3 = -1*(link.center[:y] + 20)
        x4 = -1*(link.center[:x] + 20)
        y4 = -1*(link.center[:y] - 20)
        cross = Element.new('svg:line')
        cross.add_attributes({'class' => 'bad_link', 'x1' => x1.to_s, 'x2' => x2.to_s, 'y1' => y1.to_s, 'y2' => y2.to_s, 'stroke'=>'#ff0000','stroke-width'=>'5.0'})
        cross_inv = Element.new('svg:line')
        cross_inv.add_attributes({'class' => 'bad_link', 'x1' => x3.to_s, 'x2' => x4.to_s, 'y1' => y3.to_s, 'y2' => y4.to_s, 'stroke'=>'#ff0000','stroke-width'=>'5.0'})

        x1 = -1*(link.center[:x] + 110)
        y1 = -1*(link.center[:y] - 10)

        max_height = genes.size * 30 + 25
        
        back_el = Element.new('svg:rect')
        back_el.add_attributes({'x' => x1.to_s, 'y' => y1.to_s, 'rx' => '10', 'ry' => '10', 'width' => '220', 'height' => "#{max_height}", 'stroke' => '#ff0000', 'stroke-width' => '5px', 'fill' => '#ffffff', 'fill-opacity' => '1', 'stroke-opacity' => '0.5' })
        back_circle = Element.new('svg:svg')
        
        cross_mark_height = genes.size == 0 ? 90 : 58
        
        back_circle.add_attributes('viewBox' =>"0 0 90 #{cross_mark_height}", 'height' => "#{cross_mark_height}", 'width' => '90', 'x' => "#{-1*(link.center[:x]+45)}", 'y' => "#{-1*(link.center[:y]+45)}")

        back_circle_shape = Element.new('svg:circle')
        back_circle_shape.add_attributes({'cx' => '45', 'cy' => '45', 'r' => '40', 'stroke' => '#ff0000', 'stroke-width' => '5px', 'fill' => '#ffffff', 'fill-opacity' => '1', 'stroke-opacity' => '0.5' })
        back_circle.add_element(back_circle_shape)
        text = Element.new('svg:text')
        text.add_attributes({ 'x' => x1.to_s, 'y' => "#{y1+10}", 'width' => '210', 'font-size' => '30', 'height' => "#{max_height}" })
        genes.each { |gene|
          li = Element.new('svg:tspan')
          li.add_attributes({'x' => "#{x1+20}", 'dy' => '30' })
          li.text = gene.genename
          text.add_element(li)
        }
        bad_linkage.add_element(back_el) if genes.size > 0
        bad_linkage.add_element(back_circle)        
        bad_linkage.add_element(text) if genes.size > 0
        bad_linkage.add_element(cross)
        bad_linkage.add_element(cross_inv)
        gene_overlay.add_element(bad_linkage)
        
        drop_shadow = Element.new('svg:g')
        drop_shadow.add_attribute('filter','url(#drop-shadow)')
        shadow = Element.new('svg:use')
        shadow.add_attribute('xlink:href' , "#link-#{link_element.object_id}")
        drop_shadow.add_element(shadow)
        gene_overlay.add_element(drop_shadow)
      })
    }
  end

  def validate_residues_for_results(results)
    sug = self.sugar
    @chains = []
    @valid_residues = []
    @invalid_residues = []
    results[:deltas].reject { |delta| results[:deltas].include?(delta.parent) }.each { |delta|
      chains = sug.get_chains_from_residue(delta).reject { |chain| chain[0] && chain[0].name(:ic) == 'GlcNAc' && chain[0].parent && chain[0].parent.name(:ic) == 'Man' && chain[0].paired_residue_position == 3 } # Array of arrays of residues (i.e. array of paths)
      all_residues = sug.residue_composition(delta)
      decoration_residues = all_residues - chains.flatten.uniq
      valid_residues = decoration_residues.reject { |res|
        ( decoration_residues.include?(res.parent) && ! is_valid_decoration?(res.parent) ) || ! is_valid_decoration?(res) 
      }
      invalid_residues = decoration_residues - valid_residues
      invalid_residues.each { |r|
        r.invalidate
      }
      @valid_residues += valid_residues
      @chains += chains
      @invalid_residues += invalid_residues
    }
  end

  def is_valid_decoration?(res)

    if res.name(:ic) == 'Fuc' # And parent is in chain

      if ! res.parent # Root Fucose
        return true
      end

      if res.parent.name(:ic) == 'GlcNAc'
        if res.paired_residue_position == 3 || res.paired_residue_position == 4
          return true
        end
        if res.paired_residue_position == 6 && res.parent == @root
          return true          
        end
      end
      
      if res.parent.name(:ic) == 'Gal'
        if res.paired_residue_position == 2
          return true
        end     
      end
      
      return false
      
    end
    
    if res.name(:ic) == 'NeuAc'

      if res.parent.name(:ic) == 'Gal' && res.is_a?(Sugar::MultiResidue)
        if res.paired_residue_position == 3 || res.paired_residue_position == 6
          return true
        end        
      end

      if res.parent.name(:ic) == 'Gal' && ( res.siblings.size == 0 || ( res.siblings.size == 1 && (res.siblings[0].name(:ic) == 'GlcNAc' || res.siblings[0].name(:ic) == 'GalNAc'))) # and parent is in chain
        if res.paired_residue_position == 3 || res.paired_residue_position == 6
          return true
        end        
      end
      
      if res.parent.name(:ic) == 'NeuAc'
        if res.paired_residue_position == 8
          return true
        end        
      end
      
      if res.parent.name(:ic) == 'GlcNAc'
        if res.paired_residue_position == 6
          return true
        end
      end
      
      if res.parent.name(:ic) == 'GalNAc' && (sugar.root.name(:ic) == 'GalNAc' || sugar.root.name(:ic) == 'Glc')
        if res.paired_residue_position == 3 || res.paired_residue_position == 6
          return true
        end
      end

      # Sialylation on LacDiNAcs
      if res.parent.name(:ic) == 'GalNAc' && res.parent.parent && res.parent.parent.name(:ic) == 'GlcNAc'
        if res.paired_residue_position == 6
          return true
        end         
      end
      
      return false
      
    end
    
    if res.name(:ic) == 'GalNAc'
      if res.anomer == 'a' && res.paired_residue_position == 3 && (res.parent.name(:ic) == 'Gal' || (res.parent.name(:ic) == 'GalNAc' && res.parent.parent == nil )) #and in chain
        return true
      end
      
      if res.anomer == 'b' && res.paired_residue_position == 4 && (res.parent.name(:ic) == 'Gal' || res.parent.name(:ic) == 'GlcNAc') # and in chain
        return true
      end
    end

    if res.name(:ic) == 'Gal'
      if res.anomer == 'a' && res.paired_residue_position == 3 && (res.parent.name(:ic) == 'Gal' || (res.parent.name(:ic) == 'GalNAc' && res.parent == @root )) # and in chain
        return true
      end
    end

    if res.name(:ic) == 'GlcNAc'
      if res.paired_residue_position == 4 && res.anomer == 'b' && res.parent.name(:ic) == 'Man' && res.parent.parent && res.parent.parent.name(:ic) == 'GlcNAc'
        return true
      end
    end

    if res.name(:ic) == 'HSO3'
      return true
    end

    return false
  end

  def execute_pathways
    reacs = Reaction.find(:all, :conditions => ["pathway is not null and pathway != ''"])
    max_pathway_reacs = []
    max_deltas = []
    min_delta = nil

    reacs.each { |r|
      r.extend(EndStructureAsSugar)
      
      # Core fucosylation is optional, so don't analyse it by pruning it from all the
      # search structures.
      
      r.endstructure_as_sugar.leaves.delete_if { |res| res.name(:ic) != 'Fuc' }.each { |res|
        if res.parent == r.endstructure_as_sugar.root
#          res.parent.remove_child(res)
        end
      }

      if r.endstructure_as_sugar.residue_composition.size > sugar.residue_composition.size         
        r.finish
        next
      end
      deltas = sugar.subtract(r.endstructure_as_sugar)
      deltas.each { |delta|
        delta.linkage_at_position.extend(PathwayLinkage)
      }
      if (sugar.residue_composition.size - deltas.size) >= r.endstructure_as_sugar.residue_composition.size && (min_delta == nil || deltas.size <= min_delta )
        if min_delta != deltas.size
          max_pathway_reacs = []
        end
        min_delta = deltas.size
        max_pathway_reacs << r
        max_deltas = deltas
      end
      r.finish
    }
    max_pathway_reacs = max_pathway_reacs.collect { |max_pathway_reac|
      logger.debug "Best pathway #{min_delta}"
      logger.debug { max_pathway_reac.endstructure_as_sugar.sequence }
      deltas = sugar.subtract(max_pathway_reac.endstructure_as_sugar)
      deltas.each { |delta|
        delta.linkage_at_position.extend(PathwayLinkage)
      }
      cached_disac_seqs = {}
      deltas.each { |delta|
        disac_seq = nil
        if cached_disac_seqs.has_key?(delta)
          disac_seq = cached_disac_seqs[delta]
        else
          disac = SugarUtil.SugarFromDisaccharide(sugar,delta)
          disac.get_path_to_root[0].anomer = 'u'
          disac_seq = disac.sequence
          cached_disac_seqs[delta] = disac_seq
        end
        found_reactions = Reaction.find_all_by_residuedelta(disac_seq)
        used_pathways = found_reactions.collect { |reac| reac.pathway }.compact.uniq
        used_genes = found_reactions.collect { |reac| reac.genes }.flatten.uniq
        if used_pathways.size > 0
          delta.linkage_at_position.alternative_pathways = used_pathways
          delta.linkage_at_position.catalysing_genes = used_genes
          delta.linkage_at_position.callbacks.push( lambda { |element|
            enz_list = "#{used_pathways.join(',')}pw,"
            element.add_attribute('pathways', enz_list)
          })
          delta.linkage_at_position.labels << 'alt-pathway'
        end
      }
      (sugar.residue_composition - max_deltas).each { |res|
        logger.debug("Setting label for used pathway")
        res.labels << 'pathway'
        res.labels << "pathway:#{max_pathway_reac.pathway}"
        if res.parent
          res.linkage_at_position.labels << 'pathway'
          res.linkage_at_position.labels << "pathway:#{max_pathway_reac.pathway}"
        end
      }
      max_pathway_reac.finish
      { :deltas => deltas, :maximal_pathway_name => max_pathway_reac.pathway, :maximal_pathway_reaction => max_pathway_reac }
    }
    if max_pathway_reacs.size == 0
      return [{ :deltas => sugar.residue_composition, :maximal_pathway_name => 'none', :maximal_pathway_reaction => nil }]
    end
    return max_pathway_reacs
  end

  def execute_genes
    seen_disacs = {}
    @disacs_cache ||= {}
    SugarUtil.FindDisaccharides(sugar).each { |disac, links|
      disac.get_path_to_root[0].anomer = 'u'
      disac_seq = disac.sequence
      if (@disacs_cache[disac_seq] != nil)
        seen_disacs[disac_seq] = @disacs_cache[disac_seq]
        next
      end
      seen_disacs[disac_seq] = Reaction.find_all_by_residuedelta(disac_seq).collect { |reac|
        reac.genes
      }.flatten.uniq
      @disacs_cache[disac_seq] = seen_disacs[disac_seq]
      my_disac = @disacs_cache[disac_seq]
      bin_id = 2**(@disacs_cache.size - 1)
      def my_disac.binary_id 
        sum = 0
        self.collect  { |g| sum += 2**(g.id - 1) }
        sum
      end
    }
    return seen_disacs.values
  end

  def gene_list
    self.sugar=(params[:seq])
    @genes = execute_genes();
    respond_to do |wants|
      wants.html { render }
      wants.txt { render :layout => false }
    end    
  end

    
  def execute_genecoverage(tissue_name)
    @genes = Enzymeinfo.find(:all, :conditions => ['mesh_tissue = :mesh_tissue', { :mesh_tissue => tissue_name }]).collect { |e| e.geneinfo }.uniq
    @genes = @genes + ['ALG1','ALG2','ALG3','ALG12','ALG13','ALG14'].collect { |name| Geneinfo.find(:first, :conditions => { :genename => name } ) }
    return execute_against_genelist()
  end

  def execute_reactioncoverage(reactions)
    @genes = reactions.collect { |r| r.genes }.flatten.uniq
    return execute_against_genelist()    
  end

  def execute_against_genelist()
    bad_linkages = []
    @disacs_cache ||= {}
    disac_seq_cache = {}
    SugarUtil.FindDisaccharides(sugar).each { |disac, links|
      disac_seq = nil
      if disac_seq_cache.has_key?(disac.object_id)
        disac_seq = disac_seq_cache[disac.object_id]
      else
        disac.get_path_to_root[0].anomer = 'u'
        disac_seq = disac.sequence
        disac_seq_cache[disac.object_id] = disac_seq
      end
      linkage_genes = Reaction.find_all_by_residuedelta(disac_seq).collect { |reac|
        reac.genes
      }.flatten.uniq
      links.each { |linkage|
        def linkage.genes=(new_genes)
          @linkage_genes = new_genes
        end
        def linkage.genes
          @linkage_genes
        end
        linkage.genes=linkage_genes
      }
      if (linkage_genes - @genes).size == linkage_genes.size
        bad_linkages += links
        bad_linkages.each { |link|
          link.is_a?(ValidityTest) && link.invalidate
        }

      end
    }
    return bad_linkages
  end

  def sugar=(sug)
    if ! sug.is_a?(Sugar)
      @sugar = SugarHelper.CreateRenderableSugar(sug, params[:ns] ? params[:ns].to_sym : nil)
    else
      @sugar = sug
    end    
  end

  private
  
  def garbage_collect
    if sugar != nil
      sugar.finish
    end
  end
  
end
