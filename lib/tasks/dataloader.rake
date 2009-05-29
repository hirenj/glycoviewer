namespace :enzymedb do
  desc "Export basic data from the database"
  task :dumpdb, :outfile, :needs => :environment do |t,args|
    Importer.new(:logger => logger).write_db_to_file(args.outfile)
  end
end

namespace :enzymedb do
  desc "Import basic data into the database"
  task :loaddb, :infile, :needs => :environment do |t,args|
    Importer.new(:logger => logger).read_db_from_file(args.infile)
  end
end

namespace :enzymedb do
  desc "Wipe basic data from the database"
  task :cleandb, :needs => :environment do |t,args|
    Importer.new(:logger => logger).empty_database
  end
end

namespace :enzymedb do
  desc "Clean tags"
  task :cleantags, :needs => :environment do |t,args|
    Glycodb.find(:all).each { |g|
      g.clear_tags
      g.save()
    }    
  end
end

namespace :enzymedb do
  desc "Apply tag"
  task :applytag, :tagname, :sql, :needs => :environment do |t,args|
    Glycodb.find(:all, :conditions => [args.sql]).each { |g|
      g.add_tag(args.tagname)
      g.save()
    }    
  end
end

namesapce :enzymedb do
  desc "Apply tags for production data"
  task :production_tags, :needs => :environment do |t,args|
    Rake::Task['cleantags']
    Rake::Task['applytag']['healthy_human']["species = 'HOMO SAPIENS' and RECOMBINANT = 'NONE' and (disease = '' or disease is null)"]
  end
end

def logger
  @@logger ||= Logger.new("log/rake.log")
end
