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

def logger
  @@logger ||= Logger.new("log/rake.log")
end
