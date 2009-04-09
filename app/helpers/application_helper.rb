# Methods added to this helper will be available to all templates in the application.

require 'SugarHelper'

module ApplicationHelper

  SVG_ELEMENT_NS = "http://www.w3.org/2000/svg"


  def print_sugar(sugar_string,ns=:ecdb)
    SugarHelper.ConvertToIupac(sugar_string,ns=:ecdb)
  end  

  def write_sugar(sugar,options={})
    return SugarHelper.RenderSugar(sugar,:full,options[:sugarscheme] || session[:sugarscheme],options)
  end

  def write_sugar_html(sugar)
    return SugarHelper.RenderSugarHtml(sugar)
  end

  def print_residue(res_string)
    SugarHelper.ConvertResidueName(:ecdb,res_string,:ic)
  end

  def generate_key_sugar()
      key_sug = SugarHelper.CreateMultiSugar('NeuAc(a2-6)[GalNAc(a1-3)]Gal(b1-3)[Fuc(a1-4)]GlcNAc(b1-3)[Fuc(a1-3)[Fuc(a1-2)[NeuAc(a2-3)][Gal(a1-3)]Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)]GlcNAc(b1-6)]Gal(b1-3)[Fuc(a1-6)]GlcNAc',:ic)

      SugarHelper.MakeRenderable(key_sug)        

      all_gals = key_sug.residue_composition.select { |r| r.name(:ic) == 'Gal' && r.parent && r.parent.name(:ic) == 'GlcNAc' }
      type_i = all_gals.select { |r| r.paired_residue_position == 3 }
      type_ii = all_gals.select { |r| r.paired_residue_position == 4 }
      all_glcnacs = key_sug.residue_composition.select { |r| r.name(:ic) == 'GlcNAc' && r.parent && r.parent.name(:ic) == 'Gal' }
      type_i_glcnac = all_glcnacs.select { |r| (r.paired_residue_position == 3) && r.parent.paired_residue_position == 3 }
      type_ii_glcnac = all_glcnacs.select { |r| (r.paired_residue_position == 3) && r.parent.paired_residue_position == 4 }
      branching = all_glcnacs.select { |r| r.paired_residue_position == 6 }

      labelled_stuff =
      [ key_sug.find_residue_by_linkage_path([3,6,4,3,4]), # Neuac a2-3 sialylation and Fuc(a1-2)
        key_sug.find_residue_by_linkage_path([3,3,3]), # Neuac a2-6 sialylation
        key_sug.find_residue_by_linkage_path([3,3]).linkage_at_position, # Type 1 chain
        key_sug.find_residue_by_linkage_path([3,6,4]).linkage_at_position, # Type 2 chain
        key_sug.find_residue_by_linkage_path([3,6]).linkage_at_position, # 6-Branching
        key_sug.find_residue_by_linkage_path([3,3]), # Fuc(a1-4)
        key_sug.find_residue_by_linkage_path([3,6]), # Fuc(a1-3)
        key_sug.find_residue_by_linkage_path([]) # Fuc(a1-6)
      ]

      labelled_stuff = labelled_stuff.zip(('a'..'z').to_a[0..(labelled_stuff.size-1)])


      key_sug.callbacks << lambda { |sug_root,renderer|
        renderer.chain_background_width = 20
        renderer.chain_background_padding = 65
        renderer.render_simplified_chains(key_sug,[type_i+type_i_glcnac],'sugar_chain sugar_chain_type_i','#FFEFD8')
        renderer.render_simplified_chains(key_sug,[type_ii+type_ii_glcnac],'sugar_chain sugar_chain_type_ii','#C9F6C6')
        renderer.render_simplified_chains(key_sug,[branching],'sugar_chain sugar_chain_branching','#C5D3EF')
        labelled_stuff.each { |thing,lab|
          next unless thing
          position = :center
          ratio = 0.2
          if thing.kind_of?(Monosaccharide)
            position = :bottom_right
            ratio = 0.5
          end
          thing.callbacks << renderer.callback_make_object_badge(key_sug.overlays[-1],thing,lab,ratio,position,'#222222')
        }
      }


      key_sug.residue_composition.each { |r|
        def r.hits
          1
        end
      }
      key_sug
  end

  def render_hash_as_bar_chart(labels,values,options={})
    return '' unless labels.size > 0

    total_height = options[:total_height]
    fills = options[:fills]
    neg_fills = options[:negative_fills] || options[:fills].reverse

    values.collect! {|v| v || 0 }
    
    total_minimum = 0
    has_negatives = false
    
    if (values.min < 0) || (total_height < 0)
      total_minimum = values.min
      has_negatives = true
      total_height = total_height.abs
    end
    
    bar_width = 30
    estimated_size = (labels.size * bar_width).to_f / total_height
    if has_negatives
      estimated_size *= 0.5
    end
    if (total_height.to_f / bar_width < 2) || estimated_size > 1.25
      bar_width = 15
    end
      
    x_for_label = {}
    label_vals = labels.zip(values).sort_by { |l,v| l }
    plot = Element.new('svg:svg')
  	plot.add_namespace('svg', SVG_ELEMENT_NS)
  	plot.add_attributes('preserveAspectRatio' => 'xMinYMin')
  	plot_canvas = Element.new('svg:g')
  	
    min_x = 10
    last_x = min_x - bar_width

    max_height = total_height


    label_y_pos = has_negatives ? -10 : (max_height + bar_width)

    if total_minimum < 0
      text_colour = '#000000'
    else
      text_colour = '#000000'
    end
    
    labels = []
    label_vals.each { |lab,value|
      logger.debug("Adding in label #{lab}")
      x_pos = x_for_label[lab] || last_x += bar_width
      unless options[:colour_for_label] && my_fill = options[:colour_for_label][lab]
        my_fill = value > 0 ? cycle(*(fills + [:name => 'positives'])) : cycle(*(neg_fills + [:name => 'negatives']))
      end
      box = Element.new('svg:rect')      
      box.add_attributes('x' => x_pos.round, 'y' => ((value > 0) ? (max_height - value) : max_height).round, 'height' => value.abs.to_i, 'width' => bar_width, 'fill' => my_fill, 'class' => "bar_#{lab}" )
      plot_canvas.add_element(box)
      unless x_for_label[lab]
        label = Element.new('svg:text')
        label.add_attributes('x' => x_pos.round, 'y' => label_y_pos.round, 'font-size' => bar_width.round, 'fill' => text_colour)
        label.text = lab
        labels << label
      end
      x_for_label[lab] = x_pos
    }
    labels.each { |label| plot_canvas.add_element(label) }
    
    label_min = 20 * (-1*(total_height.to_i) / 20)
    if values.min < label_min
      label_min -= 20
    end
    label_max = 20 * ((total_height.to_i) / 20)
    if values.max > label_max
      label_max += 20
    end

    label_min = 0 unless has_negatives
    
    (label_min..label_max).step(20) { |y|
      tick = Element.new('svg:line')
      tick_end = (y == 0) ? bar_width*labels.size + 15 : 5
      tick.add_attributes('x1' => 0, 'x2' => tick_end, 'y1' => ((total_height - y)).round, 'y2' => ((total_height - y)).round, 'stroke' => '#000000', 'stroke-weight' => '1' ) 
      plot_canvas.add_element(tick)
      if true || y == 0 || y > total_height || ((total_height - y) < 20)
        tick_label = Element.new('svg:text')
        tick_label.add_attributes('x' => '-30', 'y' => ((total_height - y) + (bar_width / 3)).round.to_s, 'font-size' => (bar_width / 2).round.to_s )
        tick_label.text = (y < 0 ? -1*y : y).to_s + '% '
        plot_canvas.add_element(tick_label)        
      end
    }
    plot_height = has_negatives ? 2*max_height+bar_width+50 : max_height+bar_width+70

    plot_min_x = -30
    
    if options[:y_axis_label]
      y_axis_label_y = has_negatives ? total_height : total_height / 2 
      title = Element.new('svg:text')
      title.add_attributes('x' => '-40', 'y' => "#{y_axis_label_y}", 'transform' => "rotate(-90,-40,#{y_axis_label_y})", 'font-size' => (bar_width / 2).round.to_s, 'text-anchor' => 'middle' )
      title.text = options[:y_axis_label]
      plot_canvas.add_element(title)
      plot_min_x = -40 -  (bar_width / 2).round
    end
    
    plot_width = ((bar_width * labels.size+10)-1*plot_min_x).to_i    
    
    plot.add_element(plot_canvas)
    plot_canvas.add_attributes('class' => 'graph_canvas')
    plot.add_attributes('width' => '100%', 'height' => '100%', 'viewBox' => "#{plot_min_x} #{has_negatives ? -40 : -20} #{plot_width} #{plot_height.to_i}" )
    return plot.to_s
  end

end
