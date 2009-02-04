#!/usr/bin/env ruby

# This script checks the pathway coverage of structures

require File.join(File.dirname(__FILE__), 'script_common')

module ChameleonResidue
  attr_accessor :real_name

  def alternate_name(namespace)
    return name(namespace)
  end
  def name(namespace)
    if namespace.is_a? Symbol
      namespace = NamespacedMonosaccharide::NAMESPACES[namespace]
    end
    if namespace == NamespacedMonosaccharide::NAMESPACES[:ic]
      return real_name
    else
      return 'nil'
    end
  end
end

module ChameleonResidues
  alias_method :pre_chameleon_factory, :monosaccharide_factory

  HIDDEN_RESIDUES = {    
  }

  def monosaccharide_factory(name)
    begin
      my_res = pre_chameleon_factory(name)
    rescue Exception => e
      my_res = pre_chameleon_factory('Nil')
      my_res.extend(ChameleonResidue)
      my_res.real_name = name
      HIDDEN_RESIDUES[name] = true
    end    
  end
end

module Sugar::IO::CondensedIupac::Builder 
  
  ALIASED_NAMES = {
    'xgal-hex-1:5'            => 'dgal-hex-1:5',
    'xgal-hex-1:5|2n-acetyl'  => 'dgal-hex-1:5|2n-acetyl',
    'dgal-hex-x:x'            => 'dgal-hex-1:5',
    'dgal-hex-x:x|2n-acetyl'  => 'dgal-hex-1:5|2n-acetyl',
    'dglc-hex-x:x'            => 'dglc-hex-1:5',
    'dglc-hex-x:x|6:a'        => 'dglc-hex-1:5|6:a',
    'dglc-hex-x:x|2n-acetyl'  => 'dglc-hex-1:5|2n-acetyl',
    'dman-hex-x:x'            => 'dman-hex-1:5',
    'lido-hex-x:x|6:a'        => 'lido-hex-1:5|6:a',
    'dgro-dgal-non-x:x|1:a|2:keto|3:d|5n-acetyl'  => 'dgro-dgal-non-2:6|1:a|2:keto|3:d|5n-acetyl'
  }
  
#  Sugar::IO::GlycoCT::Builder::ALIASED_NAMES['dgro-dgal-non-2:6|1:a|2:keto|3:d|5n-acetyl|9acetyl'] = 'dgro-dgal-non-2:6|1:a|2:keto|3:d|5n-acetyl'
  
  
  alias_method :builder_factory, :monosaccharide_factory
  def monosaccharide_factory(name)
    name.gsub!(/\|\d(n-)?sulfate/,'')
    name.gsub!(/\|\dphosphate/,'')
    name.gsub!(/\|\dmethyl/,'')
    name.gsub!(/^o-/,'')
    name.gsub!(/\|1:aldi/,'')
    name.gsub!(/0\:0/,'x:x')
    return builder_factory(ALIASED_NAMES[name] || name)
  end

end

Sugar::IO::CondensedIupac::Builder.extend(ChameleonResidues)

sug = SugarHelper.CreateSugar('Cow(b1-3)GlcNAc',:ic)
SugarHelper.SetWriterType(sug,:ic)
p sug.leaves[0].name(:ic)
p sug.sequence