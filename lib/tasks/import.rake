require 'csv'

namespace :csv do

  desc "Import CSV Data"
  task :import_tags => :environment do

    csv_file_path = 'db/tags.csv'

    CSV.foreach(csv_file_path) do |row|
      Tag.create!({ :title => row[0] })
      puts "Added tag: "+row[0]
    end

    CSV.foreach(csv_file_path) do |row|
      tag = Tag.find_by(title: row[0])
      if row[1]
        related_tags = Tag.where(title: row[1].split(";"))
        tag.related_tags = related_tags
        puts "Added relation for " + row[0] + ":" + row[1]
      end
    end
  end
end
