require 'csv'

namespace :setup do
  desc 'Import Teachers from csv file'
  task import_teachers: :environment do
    csv_file_path = 'db/csv/teachers.csv'

    CSV.foreach(csv_file_path, headers: true) do |row|
      Teacher.create!(name: row['name'], email: row['email'])
      puts 'Added teacher: ' + row['name'] + ' ' + row['email']
    end
  end

  desc 'Import Terms from csv file'
  task import_terms: :environment do
    csv_file_path = 'db/csv/terms.csv'

    CSV.foreach(csv_file_path, headers: true) do |row|
      Term.create!(type: row['type'], year: row['year'])
      puts 'Added term: ' + row['year'] + ' ' + row['type']
    end
  end

  desc 'Import Courses from csv file'
  task import_courses: :environment do
    csv_file_path = 'db/csv/courses.csv'

    CSV.foreach(csv_file_path, headers: true) do |row|
      Course.create!(title: row['title'])
      puts 'Added course: ' + row['title']
    end
  end

  desc 'Import Tags from csv file'
  task import_tags: :environment do
    csv_file_path = 'db/csv/tags.csv'

    CSV.foreach(csv_file_path, headers: true) do |row|
      tag = Tag.create!(title: row['title'])
      tag.courses = Course.where(title: row['courses'].split('&'))
      puts 'Added tag: ' + row['title'] + 'for courses: ' + row['courses']
    end

    CSV.foreach(csv_file_path, headers: true) do |row|
      tag = Tag.find_by(title: row['title'])
      if row['related_tags']
        related_ids = Tag.where(title: row['related_tags'].split('&'))
                         .pluck(:id)
        neighbour_ids = tag.neighbours.pluck(:id)
        new_relations = related_ids - neighbour_ids
        tag.related_tags = Tag.where(id: new_relations)
        puts 'Added relation for ' + row['title'] + ':' + row['related_tags']
      end
    end
  end

  desc 'Import lectures from csv file'
  task import_lectures: :environment do
    csv_file_path = 'db/csv/lectures.csv'

    CSV.foreach(csv_file_path, headers: true) do |row|
      course = Course.find_by(title: row['course'])
      term_data = row['term'].split('&')
      term = Term.where(type: term_data[0], year: term_data[1].to_i).first
      teacher = Teacher.find_by(name: row['teacher'])
      lecture = Lecture.create!(course: course, term: term, teacher: teacher)
      if row['additional_tags']
        lecture.additional_tags = Tag.where(title: row['additional_tags'].split('&'))
      end
      if row['disabled_tags']
        lecture.disabled_tags = Tag.where(title: row['disabled_tags'].split('&'))
      end
      puts 'Added lecture: ' + row['course'] + ' ' + row['term'] + ' by: ' +
                               row['teacher'] + ' additional_tags: ' +
                               row['additional_tags'].to_s + ' disabled_tags:' +
                               row['disabled_tags'].to_s
    end
  end

  desc 'Resets db and imports all data'
  task import_all: [:environment, 'db:reset', 'setup:import_teachers',
                    'setup:import_terms', 'setup:import_courses',
                    'setup:import_tags', 'setup:import_lectures']
end
