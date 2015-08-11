require 'spec_helper'

require 'mysql2'
require 'gumboot/strap'

RSpec.describe Gumboot::Strap do
  let(:client) { spy(Mysql2::Client) }
  let(:kernel) { double(Kernel) }

  let(:db_configs) do
    {
      'one' => {
        'adapter' => 'mysql2',
        'database' => 'one_db',
        'username' => 'one_user',
        'password' => 'one_password'
      },
      'two' => {
        'adapter' => 'mysql2',
        'database' => 'two_db',
        'username' => 'two_user',
        'password' => 'two_password'
      }
    }
  end

  before do
    opts = {
      default_file: "#{ENV['HOME']}/.my.cnf",
      default_group: 'client',
      host: '127.0.0.1'
    }

    allow(Mysql2::Client).to receive(:new).with(opts).and_return(client)
    allow(client).to receive(:escape) { |x| x }
  end

  let(:klass) do
    Class.new do
      include Gumboot::Strap
      attr_reader :kernel

      def initialize(kernel)
        @kernel = kernel
      end

      def puts(*); end

      def system(*args)
        kernel.system(*args)
      end
    end
  end

  subject { klass.new(kernel) }

  context '#ensure_activerecord_databases' do
    before do
      allow(ActiveRecord::Base).to receive(:configurations)
        .and_return(db_configs)
    end

    it 'creates the databases' do
      expect(client).to receive(:query)
        .with('CREATE DATABASE IF NOT EXISTS `one_db`').once
      expect(client).to receive(:query)
        .with('CREATE DATABASE IF NOT EXISTS `two_db`').once

      allow(client).to receive(:query).with(match(/^GRANT ALL.*/))

      subject.ensure_activerecord_databases(db_configs.keys)
    end

    it 'sets permissions for database users' do
      expect(client).to receive(:query)
        .with("GRANT ALL PRIVILEGES ON `one_db`.* TO 'one_user'@'localhost' " \
              "IDENTIFIED BY 'one_password'").once
      expect(client).to receive(:query)
        .with("GRANT ALL PRIVILEGES ON `two_db`.* TO 'two_user'@'localhost' " \
              "IDENTIFIED BY 'two_password'").once

      allow(client).to receive(:query).with(match(/^CREATE DATABASE.*/))

      subject.ensure_activerecord_databases(db_configs.keys)
    end
  end

  context '#ensure_database' do
    let(:opts) { { 'adapter' => 'mysql2', 'database' => 'test_db' } }

    it 'creates the database' do
      expect(client).to receive(:query)
        .with('CREATE DATABASE IF NOT EXISTS `test_db`').once

      subject.ensure_database(opts)
    end

    it 'fails when adapter is not mysql2' do
      expect { subject.ensure_database(opts.merge('adapter' => 'xyz')) }
        .to raise_error(/Only supports mysql2 adapter/)
    end
  end

  context '#ensure_database_user' do
    let(:opts) do
      { 'adapter' => 'mysql2', 'database' => 'test_db',
        'username' => 'test_user', 'password' => 'test_password' }
    end

    it 'sets permission for the database user' do
      expect(client).to receive(:query)
        .with('GRANT ALL PRIVILEGES ON `test_db`.* TO ' \
              "'test_user'@'localhost' IDENTIFIED BY 'test_password'").once

      subject.ensure_database_user(opts)
    end

    it 'fails when adapter is not mysql2' do
      expect { subject.ensure_database_user(opts.merge('adapter' => 'xyz')) }
        .to raise_error(/Only supports mysql2 adapter/)
    end
  end

  context '#maintain_activerecord_schema' do
    let(:tables) { [] }

    before do
      expect(ActiveRecord::Base).to receive_message_chain(:connection, :execute)
        .with('SHOW TABLES').and_return(tables)
    end

    context 'when a database already exists' do
      let(:tables) { %w(schema_migrations) }

      it 'runs the migrations' do
        expect(subject.kernel).to receive(:system).with('rake db:migrate')
        subject.maintain_activerecord_schema
      end
    end

    it 'loads the schema before running migrations' do
      expect(subject.kernel).to receive(:system).with('rake db:schema:load')
      expect(subject.kernel).to receive(:system).with('rake db:migrate')
      subject.maintain_activerecord_schema
    end
  end

  context '#clean_logs' do
    it 'removes the log files' do
      expect(subject.kernel).to receive(:system).with('rm -f log/*')
      subject.clean_logs
    end
  end

  context '#clean_tempfiles' do
    it 'removes the temp files' do
      expect(subject.kernel).to receive(:system).with('rm -rf tmp/cache')
      subject.clean_tempfiles
    end
  end
end
