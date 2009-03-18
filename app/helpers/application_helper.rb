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

  def render_hash_as_bar_chart(labels,values,total_height,fills,neg_fills=[])
    return '' unless labels.size > 0

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
    label_vals = labels.zip(values).sort_by { |l,v| l || '' }
    plot = Element.new('svg:svg')
  	plot.add_namespace('svg', SVG_ELEMENT_NS)
  	plot.add_attributes('preserveAspectRatio' => 'xMidYMax')
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
      x_pos = x_for_label[lab] || last_x += bar_width
      my_fill = value > 0 ? cycle(*(fills + [:name => 'positives'])) : cycle(*(neg_fills + [:name => 'negatives']))
      box = Element.new('svg:rect')      
      box.add_attributes('x' => x_pos, 'y' => (value > 0) ? (max_height - value) : max_height, 'height' => value.abs, 'width' => bar_width, 'fill' => my_fill, 'class' => "bar_#{lab}" )
      plot.add_element(box)
      unless x_for_label[lab]
        label = Element.new('svg:text')
        label.add_attributes('x' => x_pos, 'y' => label_y_pos, 'font-size' => bar_width, 'fill' => text_colour)
        label.text = lab
        labels << label
      end
      x_for_label[lab] = x_pos
    }
    labels.each { |label| plot.add_element(label) }
    
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
      tick.add_attributes('x1' => 0, 'x2' => 5, 'y1' => (total_height - y)-1, 'y2' => (total_height - y)-1, 'stroke' => '#000000', 'stroke-weight' => '1' ) 
      plot.add_element(tick)
      if true || y == 0 || y > total_height || ((total_height - y) < 20)
        tick_label = Element.new('svg:text')
        tick_label.add_attributes('x' => -30, 'y' => (total_height - y) + (bar_width / 3), 'font-size' => bar_width / 2 )
        tick_label.text = (y < 0 ? -1*y : y).to_s + '% '
        plot.add_element(tick_label)        
      end
    }
    plot_height = has_negatives ? 2*max_height+bar_width+40 : max_height+bar_width+60
    plot.add_attributes('width' => '100%', 'height' => '100%', 'viewBox' => "-30 #{has_negatives ? -30 : -20} #{(bar_width * labels.size+10)+30} #{plot_height}" )
    return plot.to_s
  end

end
