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
    best_result_size = nil
    best_results = nil
    self.sugar = params[:seq]
    self.sugar.root.anomer = 'u'
    
    self.sugar.residue_composition.each { |r|
      r.extend(ValidityTest)
    }
    all_results = execute_pathways
    all_results.each { |results|

      self.sugar.residue_composition.each { |r|
        r.validate
      }
#    markup_extensions(results)
      markup_chains(results,false)
      result_size = self.sugar.residue_composition.reject { |r| r.is_valid? }.size
      if best_result_size == nil || result_size < best_result_size        
        best_result_size = result_size
        best_results = results
      end
    }
    
    markup_chains(best_results)

    if params[:mesh_tissue] != nil
      gene_results = execute_genecoverage
      logger.info("Total number of bad linkages #{gene_results.size}")
      bad_links = Element.new('svg:g')
      self.sugar.overlays << bad_links
      gene_results.each { |link|
        link.callbacks.push( lambda { |link_element|
          x1 = -1*(link.centre[:x] - 20)
          y1 = -1*(link.centre[:y] - 20)
          x2 = -1*(link.centre[:x] + 20)
          y2 = -1*(link.centre[:y] + 20)
          x3 = -1*(link.centre[:x] - 20)
          y3 = -1*(link.centre[:y] + 20)
          x4 = -1*(link.centre[:x] + 20)
          y4 = -1*(link.centre[:y] - 20)
          cross = Element.new('svg:line')
          cross.add_attributes({'class' => 'bad_link', 'x1' => x1, 'x2' => x2, 'y1' => y1, 'y2' => y2, 'stroke'=>'#ff0000','stroke-width'=>'5.0'})
          cross_inv = Element.new('svg:line')
          cross_inv.add_attributes({'class' => 'bad_link', 'x1' => x3, 'x2' => x4, 'y1' => y3, 'y2' => y4, 'stroke'=>'#ff0000','stroke-width'=>'5.0'})
          bad_links.add_element(cross)
          bad_links.add_element(cross_inv)
        })
      }
      markup_linkages(gene_results)
    end
    
    render :action => 'pathway_coverage', :content_type => Mime::XHTML
    sugar.finish()
  end

  def markup_linkages(linkages)
    sug = self.sugar
    gene_overlay = Element.new('svg:g')
    sugar.overlays << gene_overlay
    linkages.each { |link|
      genes = link.genes
      link.callbacks.push( lambda { |link_element|
        x1 = -1*(link.centre[:x] + 100)
        y1 = -1*(link.centre[:y] - 10)
        
        back_el = Element.new('svg:rect')
        back_el.add_attributes({'x' => x1, 'y' => y1, 'rx' => 10, 'ry' => 10, 'width' => 220, 'height' => 75, 'stroke' => '#ff0000', 'stroke-width' => '5px', 'fill' => '#ffffff', 'fill-opacity' => 0.8, 'stroke-opacity' => 0.5 })
        fobj = Element.new('svg:foreignObject')
        fobj.add_attributes({ 'x' => x1, 'y' => y1, 'width' => 210, 'height' => 75 })
        body = Element.new('xhtml:body')
        body.add_attributes({'xmlns:xhtml' => 'http://www.w3.org/1999/xhtml'})
        fobj.add_element(body)
        div = Element.new('xhtml:div')
        div.add_attributes({'style' => 'font-size: 50px; padding: 10px; height: 75px;'})
        ul = Element.new('xhtml:ul')
        genes.each { |gene|
          li = Element.new('xhtml:li')
          li.add_attributes({'style' => 'font-size: 25px; margin-top: 5px;'})
          li.text = gene.genename
          ul.add_element(li)
        }
        div.add_element(ul)
        body.add_element(div)
        gene_overlay.add_element(back_el)
        gene_overlay.add_element(fobj)
      })
    }
  end

  def markup_chains(results,markup_sugar=true)
    sug = self.sugar
    results[:deltas].reject { |delta| results[:deltas].include?(delta.parent) }.each { |delta|
      chains = sug.get_chains_from_residue(delta) # Array of arrays of residues (i.e. array of paths)
      all_residues = sug.residue_composition(delta)
      decoration_residues = all_residues - chains.flatten.uniq
      invalid_residues = markup_decorations(decoration_residues,markup_sugar)
      invalid_residues.each { |r|
        r.invalidate
      }
      chains.each { |chain|
        markup_single_chain(chain,markup_sugar)
      }
    }
  end

  def markup_single_chain(chain,markup_sugar)
    sug = self.sugar
    single_chain = Element.new('svg:g')
    if markup_sugar
      sug.underlays << single_chain
    end
    chain.reverse.each { |residue|
      residue.callbacks.push( lambda { |element|
        xcenter = -1*(residue.centre[:x]) 
        ycenter = -1*(residue.centre[:y])
        back = Element.new('svg:circle')
        back.add_attributes({'cx' => xcenter, 'cy' => ycenter, 'r' => 65, 'fill'=>'#ddffdd','stroke' => '#ddffdd', 'stroke-width' => '1.0' })
        single_chain.add_element(back)
      }) if markup_sugar      
      link = residue.linkage_at_position || next
      link.callbacks.push( lambda { |link_element|
        x1 = -1*link.first_residue.centre[:x]
        y1 = -1*link.first_residue.centre[:y]
        x2 = -1*link.second_residue.centre[:x]
        y2 = -1*link.second_residue.centre[:y]
        link_width = (x2-x1).abs
        link_height = (y2-y1).abs
        link_length = Math.hypot(link_width,link_height)
        deltax = -1 * (55 * link_height / link_length).to_i
        deltay = (55 * link_width / link_length).to_i
        points = ""
        if y2 < y1
          points = "#{x1-deltax},#{y1+deltay} #{x2-deltax},#{y2+deltay} #{x2+deltax},#{y2-deltay} #{x1+deltax},#{y1-deltay}"
        else
          points = "#{x1+deltax},#{y1+deltay} #{x2+deltax},#{y2+deltay} #{x2-deltax},#{y2-deltay} #{x1-deltax},#{y1-deltay}"              
        end

        back = Element.new('svg:polygon')
        back.add_attributes({'points' => points, 'stroke'=>'#ddffdd','fill'=>'#ddffdd','stroke-width'=>'1.0'})
        single_chain.add_element(back)
      }) if markup_sugar
      if ! chain.include?(residue.parent)
        logger.debug("I have reached the end of a chain")
        res_parent = residue.parent
        res_parent.callbacks.push( lambda { |element|
          xcenter = -1*(res_parent.centre[:x]) 
          ycenter = -1*(res_parent.centre[:y])
          back = Element.new('svg:circle')
          back.add_attributes({'cx' => xcenter, 'cy' => ycenter, 'r' => 65, 'fill'=>'#ddffdd','stroke' => '#ddffdd', 'stroke-width' => '1.0' })
          single_chain.add_element(back)
        }) if markup_sugar
      end      
    }
  end

  def is_valid_decoration?(res)

    if res.name(:ic) == 'Fuc' # And parent is in chain

      if res.parent.name(:ic) == 'GlcNAc'
        if res.paired_residue_position == 3 || res.paired_residue_position == 4
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

      if res.parent.name(:ic) == 'Gal' && ( res.siblings.size == 0 || ( res.siblings.size == 1 && (res.siblings[0].name(:ic) == 'GlcNAc' || res.siblings[0].name(:ic) == 'GalNAc'))) # and parent is in chain
        logger.debug("A dead neuac #{res.paired_residue_position}")
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
      if res.anomer == 'a' && res.paired_residue_position == 3 && res.parent.name(:ic) == 'Gal' # and in chain
        return true
      end
      if res.anomer == 'b' && res.paired_residue_position == 4 && (res.parent.name(:ic) == 'Gal' || res.parent.name(:ic) == 'GlcNAc') # and in chain
        return true
      end
    end

    if res.name(:ic) == 'Gal'
      if res.anomer == 'a' && res.paired_residue_position == 3 && res.parent.name(:ic) == 'Gal' # and in chain
        return true
      end
    end

    if res.name(:ic) == 'GlcNAc'
      if res.paired_residue_position == 4 && res.anomer == 'b' && res.parent.name(:ic) == 'Man' && res.parent.parent && res.parent.parent.name(:ic) == 'GlcNAc'
        return true
      end
    end

    return false
  end

  def markup_decorations(decorated_residues,markup_sugar)
    sug = self.sugar
    delta_occurence = Element.new('svg:g')
    sug.underlays << delta_occurence if markup_sugar

    valid_residues = decorated_residues.reject { |res|
      ( decorated_residues.include?(res.parent) && ! is_valid_decoration?(res.parent) ) || ! is_valid_decoration?(res) 
    }
    invalid_residues = decorated_residues - valid_residues
    valid_residues.each { |residue|
      residue.callbacks.push( lambda { |element|
        xcenter = -1*(residue.centre[:x]) 
        ycenter = -1*(residue.centre[:y])
        back = Element.new('svg:circle')
        back.add_attributes({'cx' => xcenter, 'cy' => ycenter, 'r' => 70, 'fill'=>'#ccccff','stroke' => '#ccccff', 'stroke-width' => '1.0' })
        delta_occurence.add_element(back)
      }) if markup_sugar
      link = residue.linkage_at_position || next
      link.callbacks.push( lambda { |link_element|
        x1 = -1*link.first_residue.centre[:x]
        y1 = -1*link.first_residue.centre[:y]
        x2 = -1*link.second_residue.centre[:x]
        y2 = -1*link.second_residue.centre[:y]
        link_width = (x2-x1).abs
        link_height = (y2-y1).abs
        link_length = Math.hypot(link_width,link_height)
        deltax = -1 * (60 * link_height / link_length).to_i
        deltay = (60 * link_width / link_length).to_i
        points = ""
        if y2 < y1
          points = "#{x1-deltax},#{y1+deltay} #{x2-deltax},#{y2+deltay} #{x2+deltax},#{y2-deltay} #{x1+deltax},#{y1-deltay}"
        else
          points = "#{x1+deltax},#{y1+deltay} #{x2+deltax},#{y2+deltay} #{x2-deltax},#{y2-deltay} #{x1-deltax},#{y1-deltay}"              
        end

        back = Element.new('svg:polygon')
        back.add_attributes({'points' => points, 'stroke'=>'#ccccff','fill'=>'#ccccff','stroke-width'=>'1.0'})
        delta_occurence.add_element(back)
      }) if markup_sugar
    }
    markup_invalid_residues(invalid_residues,markup_sugar)
    return invalid_residues
  end

  def markup_invalid_residues(invalid_residues,markup_sugar)
    sug = self.sugar
    delta_occurence = Element.new('svg:g')
    sug.underlays << delta_occurence if markup_sugar
    
    #reject { |r| invalid_residues.include? r.parent }
    invalid_residues.each { |residue|
      all_links = SugarUtil.FindDisaccharides(sugar,residue)
      all_links[SugarUtil.SugarFromDisaccharide(sug,residue)] << residue.linkage_at_position
      all_links.each { |disac, links|
        next unless markup_sugar
        disac.get_path_to_root[0].anomer = 'u'
        
        a_disaccharide = Disaccharide.find_by_residuedelta(disac.sequence)

        if ! a_disaccharide
          a_disaccharide = Disaccharide.new()
          a_disaccharide.residuedelta = disac.sequence
        end
        if a_disaccharide.has_enzyme?
          logger.debug("It has an enzyme")
          links.each { |l| l.labels << 'enzyme' }
          next
        end
        if a_disaccharide.is_evidenced?
          logger.debug("It has evidence")
          links.each { |l| l.labels << 'evidenced' }
          next
        end
        if a_disaccharide.evidence_count > 6
          logger.debug("It has supported evidence")
          links.each { |l| l.labels << 'supported' }
          next
        end

        links.each { |l| l.labels = ['link','noenzyme'] }

      }
      residue.callbacks.push( lambda { |element|
        xcenter = -1*(residue.centre[:x]) 
        ycenter = -1*(residue.centre[:y])
        back = Element.new('svg:circle')
        back.add_attributes({'cx' => xcenter, 'cy' => ycenter, 'r' => 75, 'fill'=>'#ffdddd','stroke' => '#ffdddd', 'stroke-width' => '1.0' })
        delta_occurence.add_element(back)
      }) if markup_sugar
    }
  end

  def execute_pathways
    reacs = Reaction.find(:all, :conditions => ["pathway is not null and pathway != ''"])
    max_pathway_reacs = []
    max_deltas = []
    min_delta = nil

    # Core fucosylation is totally optional, so don't analyse it by removing it 
    # from all the search structures.

    sugar.leaves.delete_if { |r| r.name(:ic) != 'Fuc' }.each { |r|
      if r.parent == sugar.root
        r.parent.remove_child(r)
      end
    }

    reacs.each { |r|
      r.extend(EndStructureAsSugar)
      
      # Core fucosylation is optional, so don't analyse it by pruning it from all the
      # search structures.
      
      r.endstructure_as_sugar.leaves.delete_if { |res| res.name(:ic) != 'Fuc' }.each { |res|
        if res.parent == r.endstructure_as_sugar.root
          res.parent.remove_child(res)
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
      logger.debug max_pathway_reac.endstructure_as_sugar.sequence
      deltas = sugar.subtract(max_pathway_reac.endstructure_as_sugar)
      deltas.each { |delta|
        delta.linkage_at_position.extend(PathwayLinkage)
      }      
      deltas.each { |delta|
        disac = SugarUtil.SugarFromDisaccharide(sugar,delta)
        disac.get_path_to_root[0].anomer = 'u'
        found_reactions = Reaction.find_all_by_residuedelta(disac.sequence)
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

  def execute_genecoverage
    @genes = Enzymeinfo.find(:all, :conditions => ['mesh_tissue = :mesh_tissue', { :mesh_tissue => params[:mesh_tissue]}]).collect { |e| e.geneinfo }.uniq
    bad_linkages = []
    @disacs_cache ||= {}
    SugarUtil.FindDisaccharides(sugar).each { |disac, links|
      disac.get_path_to_root[0].anomer = 'u'
      disac_seq = disac.sequence
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
      end
    }
    return bad_linkages
  end

  # def enzyme_list
  #   self.sugar=(params[:seq])
  #   SugarUtil.FindDisaccharides(sugar).each { |disac, links|
  #     links.each { |link|
  #       link.labels = ['link','noenzyme']
  #     }
  #     disac.get_path_to_root[0].anomer = 'u'
  #     
  #     Reaction.find_all_by_residuedelta(disac.sequence).each { |reac|
  #       links.each { |link|
  #         link.callbacks.push( lambda { |element|
  #           enz_list = element.attribute('enzymes') || ''
  #           enz_list = "#{enz_list}#{reac.id}rn,"
  #           element.add_attribute('enzymes', enz_list)
  #         })
  #         link.labels = ['link']
  #       }
  #     }
  #   }
  #   sugar.name = 'user'
  #   render :action => 'enzyme_list'
  # end
  # 
  # def resolve_linkages
  #   self.sugar=params[:seq]
  #   @genereaction_mapping = Hash.new { |hash,key| hash[key] = Array.new() }
  # 
  #   SugarUtil.FindDisaccharides(sugar).each { |disac, links|
  #     links.each { |link|
  #       link.labels = ['link','noenzyme']
  #     }
  #     disac.get_path_to_root[0].anomer = 'u'
  #     
  #     links.each { |link|
  #     
  #       linkage_residues = sugar.get_path_to_root(link.parent_residue)
  # 
  #       # How much of the main path from the substrate transfer point
  #       # to the reducing end of the sequence does each reaction have in 
  #       # common with the path from the parent of this linkage to the root?
  #       logger.debug("Linkage residue on the sugar is:")
  #       linkage_residues.each { |linkres|
  #         logger.debug(linkres.name)
  #       }
  #       
  #       link.extend(ResolvedLinkage)
  #       link.associated_reactions = {}
  #       
  #       genescores = {}
  #       
  #       disac.target_namespace = :ecdb
  #       
  #       Reaction.find_all_by_residuedelta(disac.sequence).each { |reac|
  # 
  #         endstruct = SugarHelper.CreateSugar(reac.endstructure)
  #         startstruct = SugarHelper.CreateSugar(reac.substrate)
  #         deltares = endstruct.subtract(startstruct)
  #         next unless deltares.size > 0
  #         reac_residues = endstruct.get_path_to_root(deltares[0].parent)
  #         score = 0
  #         reac_residues.zip(linkage_residues).each { |r_res,l_res|
  #           break unless l_res && r_res
  #           
  #           if r_res.name(:id) == l_res.name(:id)
  #             if l_res.anomer 
  #               if  l_res.anomer == r_res.anomer && 
  #                   l_res.paired_residue_position == r_res.paired_residue_position
  #                 score += 1
  #               end
  #             else
  #               score += 1
  #             end
  #           end
  #         }
  #         
  #         link.associated_reactions[reac] = score
  #         reac.genes.each { |gene|
  #           tempscore = genescores[gene] || 0 
  #           genescores[gene] = score > tempscore ? score : tempscore 
  #           @genereaction_mapping[gene.id] << reac.id
  #         }
  #         endstruct.finish
  #         startstruct.finish
  #       }
  #       if link.associated_reactions.keys.size > 0
  #         link.labels = ['link']
  #         link.callbacks.push( lambda { |element|
  #           enz_list = element.attribute('enzymes') || ''
  #           link.associated_reactions.keys.sort_by { |r| link.associated_reactions[r] }.reverse.reject {|r| link.associated_reactions[r] < 0 }.each { |reac|              
  #             enz_list += "#{link.associated_reactions[reac]}]#{reac.id}rn,"
  #           }
  #           element.add_attribute('enzymes', enz_list)
  #         })
  #         link.callbacks.push( lambda { |element|
  #           gene_list = element.attribute('genes') || ''
  #           gene_list += genescores.keys.sort_by { |g| genescores[g] }.reverse.collect { |g| "#{g.id}gn" }.join(',')
  #           element.add_attribute('genes',gene_list)
  #         })
  #       end
  #     }
  #     
  #   }
  #   render :action => 'enzyme_list'
  # end

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
