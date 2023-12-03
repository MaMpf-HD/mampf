# from https://gist.github.com/joelvh/f50b8462611573cf9015e17d491a8a92
# Original source: https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90
# Merged with: https://gist.github.com/kofronpi/37130f5ed670465b1fe2d170f754f8c6
#
# Usage:
#
# # dump the development db
# rake db:dump
#
# # dump the db in a specific format
# rake db:dump format=sql
#
# # dump a table (e.g. users table)
# rake db:dump:table table=users
#
# # dump a table in a specific format
# rake db:dump:table table=users format=sql
#
# # list dumps
# rake db:dumps
#
# # dump the production db
# RAILS_ENV=production rake db:dump
#
# # restore db based on a backup file pattern (e.g. timestamp)
# rake db:restore pattern=20170101
#
# # note: config/database.yml is used for database configuration,
# #       but you will be prompted for the database user's password
#
# Original source: https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90
# Merged with: https://gist.github.com/kofronpi/37130f5ed670465b1fe2d170f754f8c6
namespace :db do
  desc "Dumps the database to backups"
  task dump: :environment do
    dump_fmt   = ensure_format(ENV.fetch("format", nil))
    dump_sfx   = suffix_for_format(dump_fmt)
    backup_dir = backup_directory(Rails.env, create: true)
    full_path  = nil
    cmd        = nil

    with_config do |_app, host, db, user|
      full_path = "#{backup_dir}/#{Time.zone.now.strftime("%Y%m%d%H%M%S")}_#{db}.#{dump_sfx}"
      # rubocop:disable Layout/LineLength
      cmd       = "pg_dump -F #{dump_fmt} -v -O -w -U '#{user}' -h '#{host}' -d '#{db}' -f '#{full_path}'"
      # rubocop:enable Layout/LineLength
    end

    puts cmd
    system cmd
    puts ""
    puts "Dumped to file: #{full_path}"
    puts ""
  end

  namespace :dump do
    desc "Dumps a specific table to backups"
    task table: :environment do
      table_name = ENV.fetch("table", nil)

      if table_name.present?
        dump_fmt   = ensure_format(ENV.fetch("format", nil))
        dump_sfx   = suffix_for_format(dump_fmt)
        backup_dir = backup_directory(Rails.env, create: true)
        full_path  = nil
        cmd        = nil

        with_config do |_app, host, db, user|
          # rubocop:disable Layout/LineLength
          full_path = "#{backup_dir}/#{Time.zone.now.strftime("%Y%m%d%H%M%S")}_#{db}.#{table_name.parameterize.underscore}.#{dump_sfx}"
          cmd       = "pg_dump -F #{dump_fmt} -v -O -w -U '#{user}' -h '#{host}' -d '#{db}' -t '#{table_name}' -f '#{full_path}'"
          # rubocop:enable Layout/LineLength
        end

        puts cmd
        system cmd
        puts ""
        puts "Dumped to file: #{full_path}"
        puts ""
      else
        puts "Please specify a table name"
      end
    end
  end

  desc "Show the existing database backups"
  task dumps: :environment do
    backup_dir = backup_directory
    puts backup_dir
    system "/bin/ls -ltR #{backup_dir}"
  end

  desc "Restores the database from a backup using PATTERN"
  task restore: :environment do
    pattern = ENV.fetch("pattern", nil)

    if pattern.present?
      file = nil
      cmd  = nil

      with_config do |_app, host, db, user|
        backup_dir = backup_directory
        files      = Dir.glob("#{backup_dir}/**/*#{pattern}*")

        case files.size
        when 0
          puts "No backups found for the pattern '#{pattern}'"
        when 1
          file = files.first
          fmt  = format_for_file file

          case fmt
          when nil
            puts "No recognized dump file suffix: #{file}"
          when "p"
            cmd = "psql -U '#{user}' -h '#{host}' -d '#{db}' -f '#{file}'"
          else
            cmd = "pg_restore -F #{fmt} -v -c -C -U '#{user}' -h '#{host}' -d '#{db}' -f '#{file}'"
          end
        else
          puts "Too many files match the pattern '#{pattern}':"
          puts " #{files.join("\n ")}"
          puts ""
          puts "Try a more specific pattern"
          puts ""
        end
      end
      unless cmd.nil?
        Rake::Task["db:drop"].invoke
        Rake::Task["db:create"].invoke
        puts cmd
        system cmd
        Rake::Task["sunspot:reindex"].invoke
        puts ""
        puts "Restored from file: #{file}"
        puts ""
      end
    else
      puts "Please specify a file pattern for the backup to restore (e.g. timestamp)"
    end
  end

  private

    def ensure_format(format)
      format_lookup = {
        "dump" => "c",
        "sql" => "p",
        "tar" => "t",
        "dir" => "d"
      }

      return format if format_lookup.value?(format)

      format_lookup.key?(format) ? format_lookup[format] : "p"
    end

    def suffix_for_format(suffix)
      suffix_lookup = {
        "c" => "dump",
        "p" => "sql",
        "t" => "tar",
        "d" => "dir"
      }

      suffix_lookup[suffix]
    end

    def format_for_file(file)
      case file
      when /\.dump$/ then "c"
      when /\.sql$/  then "p"
      when /\.dir$/  then "d"
      when /\.tar$/  then "t"
      end
    end

    def backup_directory(_suffix = nil, create: false)
      backup_dir = Rails.root.join.to_s

      if create && !Dir.exist?(backup_dir)
        puts "Creating #{backup_dir} .."
        FileUtils.mkdir_p(backup_dir)
      end

      backup_dir
    end

    def with_config
      yield Rails.application.class.module_parent_name.underscore,
            ActiveRecord::Base.connection_db_config.host,
            ActiveRecord::Base.connection_db_config.database,
            ActiveRecord::Base.connection_db_config.configuration_hash[:username]
    end
end
