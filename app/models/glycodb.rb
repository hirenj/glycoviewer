class Glycodb < ActiveRecord::Base
  
  def self.All_Tags()
    self.find(:all).collect { |gdb| (gdb.tags || '').split(',') }.flatten.sort.uniq
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
