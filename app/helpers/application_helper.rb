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

  def render_hash_as_bar_chart(labels,values,total_height,fills)
    return '' unless labels.size > 0
    bar_width = 30
    if (total_height.to_f / bar_width < 2)
      bar_width = 15
    end
      
    values.collect! {|v| v || 0 }
    label_vals = labels.zip(values)
    plot = Element.new('svg:svg')
  	plot.add_namespace('svg', SVG_ELEMENT_NS)
  	plot.add_attributes('preserveAspectRatio' => 'xMidYMax')
    curr_x = 10
    max_height = total_height
    label_vals.each { |lab,value|
      my_fill = fills.shift
      box = Element.new('svg:rect')
      box.add_attributes('x' => curr_x, 'y' => max_height - value, 'height' => value, 'width' => bar_width, 'fill' => my_fill, 'class' => "bar_#{lab}" )
      plot.add_element(box)
      label = Element.new('svg:text')
      label.add_attributes('x' => curr_x, 'y' => max_height + bar_width, 'font-size' => bar_width)
      label.text = lab
      plot.add_element(label)
      curr_x += bar_width
    }
    (0..(total_height+20)).step(20) { |y|
      tick = Element.new('svg:line')
      tick.add_attributes('x1' => 0, 'x2' => 5, 'y1' => (total_height - y)-1, 'y2' => (total_height - y)-1, 'stroke' => '#000000', 'stroke-weight' => '1' ) 
      plot.add_element(tick)
      if y > total_height || ((total_height - y) < 20)
        tick_label = Element.new('svg:text')
        tick_label.add_attributes('x' => 0, 'y' => (total_height - y) + (bar_width / 3), 'font-size' => bar_width / 3 )
        tick_label.text = y
        plot.add_element(tick_label)        
      end
    }
    plot.add_attributes('width' => '100%', 'height' => '100%', 'viewBox' => "0 -20 #{bar_width * labels.size+10} #{max_height+bar_width+30}" )
    return plot.to_s
  end

end
