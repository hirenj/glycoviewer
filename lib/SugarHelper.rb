require 'Sugar'
require 'Sugar/IO/CondensedIupac'
require 'Sugar/IO/GlycoCT'
require 'Sugar/IO/Glyde'
require 'SugarException'
require 'Render/Renderable'
require 'Render/CondensedLayout'
require 'Render/CondensedScalableLayout'
require 'Render/GridLayout'
require 'Render/SvgRenderer'
require 'Render/CollapsedStubs'
require 'Render/PngRenderer'

require 'Render/HtmlTextRenderer'
require 'MultiSugar'

require 'CachingSugar'

Monosaccharide.Load_Definitions("#{RAILS_ROOT}/SugarCoreRuby/data/dictionary.xml")
NamespacedMonosaccharide.Default_Namespace = NamespacedMonosaccharide::NAMESPACES[:ecdb]

NamespacedMonosaccharide.Supported_Residues.each { |resname|
  Monosaccharide.Factory(NamespacedMonosaccharide, resname)
}

class Sugar
  include ::Sugar::IO::GlycoCT::Builder
  include ::Sugar::IO::GlycoCT::Writer
end

class StephanMonosaccharide < NamespacedMonosaccharide
  def self.Default_Namespace
    NamespacedMonosaccharide::NAMESPACES[:stephan]
  end
end

class SugarHelper
  include DebugLog

  class IcSugar < Sugar
  	include Sugar::IO::GlycoCT::Builder
  	include Sugar::IO::CondensedIupac::Writer
  end
  IcSugar.Target_Namespace = NamespacedMonosaccharide::NAMESPACES[:ic]
  
	def SugarHelper.Print(sequence)
		begin
			sugar = SugarHelper.CreateSugar(sequence, :ecdb)
			return sugar.sequence
		rescue SugarException => exception
			sugar.debug exception
			return "Could not convert"
		end
	end
	
	def SugarHelper.ConvertToIupac(sequence,ns=:ecdb)
	  return unless sequence.length > 0
		begin
			sugar = SugarHelper.CreateSugar(sequence,ns)
			sugar.extend(Sugar::IO::CondensedIupac::Writer)
			sugar.target_namespace = :ic
			outseq = sugar.sequence
			sugar.finish
			return outseq
		rescue SugarException => exception
			sugar.debug exception
			return "Could not convert"
		end
  end
	
	def SugarHelper.CalculateDiff(sequence1, sequence2)
	  begin
	    sugar = SugarHelper.CreateSugar(sequence1)
	    sugar2 = SugarHelper.CreateSugar(sequence2)
      diffs = sugar.subtract(sugar2).reverse
      diffs.each { |res| 
        if (diffs.include?(res))
          diffs = diffs - ( res.residue_composition - [res] )
        end
      }
	    debug diffs.collect() { |res|
	      res.name + "(a1-#{res.paired_residue_position})" + res.parent.name
	    }.join("\n")
	  rescue Exception => exception
	    debug sugar.sequence
	    debug exception
    end
  end
  def SugarHelper.FindBaseSugars()
    Reaction.find(:all).reject { |reaction|
      reaction.substrate =~ /(Cer)$/
    }
  end

  def SugarHelper.ConvertResidueName(in_ns, in_name, out_ns=:ecdb)
    res = Monosaccharide.Factory(NamespacedMonosaccharide, "#{in_ns.to_s}:#{in_name}")
    out_name = res.name(out_ns)
    res.finish
    return out_name
  end

  def SugarHelper.CreateSugarFromDisaccharide(disaccharide)
    parent = Monosaccharide.Factory(StephanMonosaccharide, disaccharide.child )
    child = Monosaccharide.Factory(StephanMonosaccharide, disaccharide.parent )
    parent.anomer = disaccharide.anomer
    link = Linkage.new()
    links = /(\d+)\+(\d+)/.match(disaccharide.substitutions)
    link.set_first_residue(parent,links[2].to_i)
    link.set_second_residue(child,links[1].to_i)
    sug = Sugar.new()
    sug.linkages = [ { :link => link , :residue => parent }]
    SugarHelper.SetWriterType(sug,:ecdb)
    sug.target_namespace = :ecdb
    return sug
  end

  def SugarHelper.SetWriterType(sugar,ns=:ecdb)
    case ns
      when :glyde
        sugar.extend(Sugar::IO::Glyde::Writer)
      when :ecdb
        sugar.extend(Sugar::IO::GlycoCT::Writer)
      when :dkfz
        sugar.extend(Sugar::IO::CondensedIupac::Writer)
        sugar.target_namespace = ns
      when :ic
        sugar.extend(Sugar::IO::CondensedIupac::Writer)
        sugar.target_namespace = ns
    end
    return sugar
  end

  def SugarHelper.CreateSugar(sequence, ns=:ecdb)
    sugar = Sugar.new()
    set_sequence(sugar,sequence,ns)
  end

  def SugarHelper.CreateMultiSugar(sequence, ns=:ecdb)
    sugar = Sugar.new()
    set_sequence(sugar,sequence,ns,true)
  end
  
  def SugarHelper.set_sequence(sugar, sequence, ns, use_multi=false)
    case ns
      when :glycoct
        sugar.extend(Sugar::IO::GlycoCT::Builder)
        sugar.input_namespace = :glyde
      when :glyde
        sugar.extend(Sugar::IO::Glyde::Builder)
        sugar.input_namespace = ns
      when :ecdb
        sugar.extend(Sugar::IO::GlycoCT::Builder)
      when :dkfz
        sugar.extend(Sugar::IO::CondensedIupac::Builder)
        sugar.input_namespace = ns
      when :ic
        sugar.extend(Sugar::IO::CondensedIupac::Builder)
        sugar.input_namespace = ns
    end
    sugar.extend(Sugar::IO::GlycoCT::Writer)
    if use_multi
      sugar.extend(Sugar::MultiSugar)
    end
    sugar.sequence = sequence if (sequence != '')
    sugar.target_namespace = :ecdb
    return sugar    
  end
  
  def SugarHelper.MakeRenderable(sugar)
    sugar.extend(Renderable::Sugar)
  end
  
  def SugarHelper.CreateRenderableSugar(sequence, ns=:ecdb)
    sugar = sequence
    if sugar.is_a? String
      sugar = Sugar.new()
      SugarHelper.set_sequence(sugar,sequence, ns)
    end
    sugar.extend(Renderable::Sugar)
    sugar
  end

  def SugarHelper.CreateIupacRenderableSugar(sequence)
    sugar = Sugar.new()
    SugarHelper.set_sequence(sugar,sequence, :ic)
    sugar.extend(Renderable::Sugar)
    sugar
  end

  def SugarHelper.RenderSugarHtml(sugar)
    renderer = HtmlTextRenderer.new()
    renderer.sugar = sugar
    renderer.scheme = :ic
    return renderer.render(sugar)
  end
  
  def SugarHelper.RenderSugarPng(sugar, renderscheme='text:ic',options={})
    renderer = PngRenderer.new()
    if options[:width]
      renderer.width = options[:width]
    end
    if options[:height]
      renderer.height = options[:height]
    end
    
    if renderscheme == :boston
      renderer.scheme = 'boston'
      CondensedLayout.new().layout(sugar)
    elsif renderscheme == :oxford
      renderer.scheme = 'oxford'
      GridLayout.new().layout(sugar)    
    else
      renderer.scheme = 'text:ic'
      CondensedLayout.new().layout(sugar)    
    end
    renderer.sugar = sugar
    renderer.initialise_prototypes()
    return renderer.render(sugar)    
  end
  
  def SugarHelper.RenderSugar(sugar, mode=:full, renderscheme='text:ic',options={})
    renderer = SvgRenderer.new()
    
    if mode != :full
      renderer.dont_use_prototypes
    end
    
    if options[:width]
      renderer.width = options[:width]
    end
    if options[:height]
      renderer.height = options[:height]
    end
    
    if options[:padding]
      renderer.padding = options[:padding]
    end
    
    if options[:font_size]
      renderer.font_size = options[:font_size]
    end
    
    if renderscheme == :boston
      renderer.scheme = 'boston'
      CondensedLayout.new().layout(sugar) if sugar
    elsif renderscheme == :oxford
      renderer.scheme = 'oxford'
      GridLayout.new().layout(sugar) if sugar
    elsif renderscheme == :composite
      renderer.extend(CollapsedStubs)
      renderer.scheme = 'boston'
      renderer.sugar = sugar
      renderer.initialise_prototypes() if sugar
      layout_engine = CondensedScalableLayout.new()
      layout_engine.node_spacing = { :x => 150, :y => 150 }
      layout_engine.layout(sugar) if sugar
      
    else
      renderer.scheme = 'text:ic'
      CondensedLayout.new().layout(sugar) if sugar   
    end
    if (renderscheme != :composite)
      renderer.sugar = sugar
      renderer.initialise_prototypes() if sugar
    end
    return renderer.render(sugar)    
  end
    
end
