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
      fail('Only supports mysql2 adapter') unless adapter == 'mysql2'

      puts "Ensuring database `#{database}` exists"
      client.query("CREATE DATABASE IF NOT EXISTS `#{database}`")
    end

    def ensure_database_user(db)
      adapter, database, username, password =
        db.values_at(*%w(adapter database username password))

      fail('Only supports mysql2 adapter') unless adapter == 'mysql2'

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

    private

    def message(msg)
      puts "\n== #{msg} =="
    end
  end
end
