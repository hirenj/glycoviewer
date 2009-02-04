class PathwayResult
  attr_accessor :gene_counts
  attr_accessor :epitopes
  attr_accessor :delta_pathway_coverage
  attr_accessor :id
  attr_accessor :resolved_structures
  attr_accessor :epitope_branch_statistics
  attr_accessor :epitope_size_statistics
  
  @@REGISTRY = Hash.new() { |h,k| h[k] = PathwayResult.new(k) }
  
  def PathwayResult.Factory(pathway_id)
    @@REGISTRY[pathway_id]
  end
  
  def PathwayResult.Pathways
    return @@REGISTRY.values
  end
  
  def PathwayResult.AllResolved
    return @@REGISTRY.values.inject(0) { |sum,pw| sum + pw.resolved_structures }
  end
  
  def epitopes_for_each_substrate
    epitopes.values.collect { |ep| ep.substrates }.flatten.uniq.each { |sub| yield(sub, sub.epitopes.delete_if {|e| e.pathway != self }) }
  end
  
  def epitopes_by_number_of_substrates
    epitopes.values.sort_by { |ep| ep.substrates.size }.reverse
  end
  
  def initialize(id)
    @id = id
    @gene_counts = Hash.new(0)
    @epitopes = Hash.new() {|h,k| h[k] = Epitope.new(k) }
    @delta_pathway_coverage = Hash.new() { |h,k| h[k] = Array.new() }
    @resolved_structures = 0
    @epitope_size_statistics = []
    @epitope_branch_statistics = []
  end  
end

class Epitope
  attr_accessor :substrates
  attr_accessor :sequence
  attr_accessor :pathway
    
  def Epitope.Factory(pathway_result,sequence)
    epitope = pathway_result.epitopes[sequence]
    epitope.pathway = pathway_result
    epitope
  end
  def initialize(seq)
    @sequence = seq
    @substrates = Array.new()
  end
  
  def add_substrate(substrate) 
    self.substrates << substrate
    substrate.epitopes << self
  end
end

class Substrate
  attr_accessor :pathway
  attr_accessor :pathway_array
  attr_accessor :sequence
  attr_accessor :epitopes

  @@REGISTRY = Hash.new()
  
  def Substrate.Factory(pathway,sequence)
    path_string = pathway.join('')
    if @@REGISTRY["#{path_string}#{sequence}"]
      return @@REGISTRY["#{path_string}#{sequence}"]
    end
    @@REGISTRY["#{path_string}#{sequence}"] = Substrate.new(path_string,pathway,sequence)
  end
  
  def initialize(path,path_array,seq)
    @pathway = path
    @pathway_array = path_array
    @sequence = seq
    @epitopes = Array.new()
  end
  
end