require 'yaml'
require 'active_support/core_ext/hash/deep_merge'

module Gumboot
  module Strap
    def client
      file = File.expand_path('~/.my.cnf')
      @client ||= Mysql2::Client.new(default_file: file,
                                     default_group: 'client',
                                     host: '127.0.0.1')
    end

    def ensure_activerecord_databases(environments)
      environments.each do |env|
        message "Preparing #{env} database"

        db = ActiveRecord::Base.configurations[env]

        ensure_database(db)
        ensure_database_user(db)
      end
    end

    def ensure_database(db)
      adapter, database = db.values_at(*%w(adapter database))
      raise('Only supports mysql2 adapter') unless adapter == 'mysql2'

      puts "Ensuring database `#{database}` exists"
      client.query("CREATE DATABASE IF NOT EXISTS `#{database}`")
    end

    def ensure_database_user(db)
      adapter, database, username, password =
        db.values_at(*%w(adapter database username password))

      raise('Only supports mysql2 adapter') unless adapter == 'mysql2'

      puts "Ensuring access to `#{database}` for #{username} user is granted"
      client.query("GRANT ALL PRIVILEGES ON `#{database}`.* " \
                   "TO '#{client.escape(username)}'@'localhost' " \
                   "IDENTIFIED BY '#{client.escape(password)}'")
    end

    def maintain_activerecord_schema
      message 'Loading database schema'

      if ActiveRecord::Base.connection.execute('SHOW TABLES').count.zero?
        puts 'No tables exist yet, loading schema'
        system 'rake db:schema:load'
      end

      puts 'Running migrations'
      system 'rake db:migrate'
    end

    def clean_logs
      message 'Removing old tempfiles'
      system 'rm -f log/*'
    end

    def clean_tempfiles
      message 'Removing old tempfiles'
      system 'rm -rf tmp/cache'
    end

    def link_global_configuration(files)
      files.each do |file|
        src = File.expand_path("~/.aaf/#{file}")
        raise("Missing global config file: #{src}") unless File.exist?(src)

        dest =  "config/#{file}"
        next if File.exist?(dest)
        FileUtils.ln_s(src, dest)
      end
    end

    def update_local_configuration(files)
      files.each do |file|
        src = "config/#{file}.dist"
        raise("Not a .yml file: #{file}") unless file.end_with?('.yml')
        raise("Missing dist config file: #{src}") unless File.exist?(src)

        merge_config(src, "config/#{file}")
      end
    end

    def install_dist_template(files)
      files.each do |file|
        src = "config/#{file}.dist"
        dest = "config/#{file}"

        raise("Missing dist config file: #{src}") unless File.exist?(src)

        next if File.exist?(dest)
        FileUtils.copy(src, dest)
      end
    end

    private

    def message(msg)
      puts "\n== #{msg} =="
    end

    def merge_config(src, dest)
      new_config = YAML.load(File.read(src))
      old_config = File.exist?(dest) ? YAML.load(File.read(dest)) : {}

      File.open(dest, 'w') do |f|
        f.write(YAML.dump(new_config.deep_merge(old_config)))
      end
    end
  end
end
