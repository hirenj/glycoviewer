class Glycodb < ActiveRecord::Base
  
  def self.All_Tags()
    self.find(:all).collect { |gdb| (gdb.tags || '').split(',') }.flatten.sort.uniq
  end
  
  def add_tag(new_tag)
    current_tags = (self.tags || '').split(',') || []
    self.tags = (current_tags.push(new_tag)).uniq.join(',')
  end
  
  def clear_tags
    self.tags = ''
  end
  
  def add_reference(ref_id)
    current_references = (self.references || '').split(',') || []
    self.references = (current_references.push(ref_id)).uniq.join(',')    
  end
  
  def self.easyfind(argHash)
      fieldnames = argHash[:fieldnames]
      keywords = argHash[:keywords]
      order = argHash[:order]
      incl = argHash[:include]
      unless keywords.empty?
          keywordArray = []
          theSqlArray = keywords.inject([]) do |agg, keyword| 
              aLineArray = fieldnames.inject([]) {|lineSectionsArray, aFieldname| 
                      keywordArray << "%#{keyword.downcase}%"
                      lineSectionsArray << 'LOWER('+aFieldname+')' + " LIKE ?" 
                  }
              aLine = aLineArray.join(" OR ")
              aLine = "(" + aLine + ")" 
              agg << aLine
          end
          theSql = theSqlArray.join(" AND ")
          logger.error(theSql)
          result = self.find(:all, :conditions => [theSql] + keywordArray, :order => order, :include => incl)
      else
          result = []
      end
      return result
  end
end
