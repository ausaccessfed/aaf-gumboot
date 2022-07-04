# frozen_string_literal: true

require 'yaml'
require 'active_support/core_ext/hash/deep_merge'
require 'fileutils'

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

    def ensure_database(dbase)
      adapter, database = dbase.values_at('adapter', 'database')
      raise('Only supports mysql2 adapter') unless adapter == 'mysql2'

      Rails.logger.info "Ensuring database `#{database}` exists"
      client.query("CREATE DATABASE IF NOT EXISTS `#{database}` " \
                   'CHARACTER SET utf8 COLLATE utf8_bin')
    end

    def ensure_database_user(dbase)
      adapter, database, username, password =
        dbase.values_at('adapter', 'database', 'username', 'password')

      raise('Only supports mysql2 adapter') unless adapter == 'mysql2'

      Rails.logger.info(
        "Ensuring access to `#{database}` for #{username} user is granted"
      )

      create_and_grant_user(client, database, username, password)
    end

    def create_and_grant_user(client, database, username, password)
      client.query("CREATE USER IF NOT EXISTS '#{client.escape(username)}'" \
                   "@'localhost' IDENTIFIED BY '#{client.escape(password)}';")
      client.query("GRANT ALL PRIVILEGES ON `#{database}`.* " \
                   "TO '#{client.escape(username)}'@'localhost'")
    end

    def maintain_activerecord_schema
      message 'Loading database schema'

      if ActiveRecord::Base.connection.execute('SHOW TABLES').count.zero?
        Rails.logger.info 'No tables exist yet, loading schema'
        system 'rake db:schema:load'
      end

      Rails.logger.info 'Running migrations'
      system 'rake db:migrate'
    end

    def load_seeds
      message 'Loading seeds'

      system 'rake db:seed'
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
      Rails.logger.info "\n== #{msg} =="
    end

    def safe_load(yaml)
      YAML.safe_load(yaml, permitted_classes: [Symbol])
    end

    def merge_config(src, dest)
      new_config = safe_load(File.read(src))
      old_config = File.exist?(dest) ? safe_load(File.read(dest)) : {}

      File.open(dest, 'w') do |f|
        f.write(YAML.dump(new_config.deep_merge(old_config)))
      end
    end
  end
end
