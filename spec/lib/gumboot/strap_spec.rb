# frozen_string_literal: true

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
      expect(client).to receive(:query).with(create_db_query('one_db')).once
      expect(client).to receive(:query).with(create_db_query('two_db')).once

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
      expect(client).to receive(:query).with(create_db_query('test_db')).once

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

  context '#load_seeds' do
    it 'loads the seeds' do
      expect(subject.kernel).to receive(:system).with('rake db:seed')
      subject.load_seeds
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

  context '#link_global_configuration' do
    it 'creates a symbolic link to the shared configuration' do
      base = "#{ENV['HOME']}/.aaf"

      allow(File).to receive(:exist?).with("#{base}/a").and_return(true)
      allow(File).to receive(:exist?).with("#{base}/b").and_return(true)
      allow(File).to receive(:exist?).with("#{base}/c").and_return(true)

      allow(File).to receive(:exist?).with('config/a').and_return(false)
      allow(File).to receive(:exist?).with('config/b').and_return(false)
      allow(File).to receive(:exist?).with('config/c').and_return(false)

      expect(FileUtils).to receive(:ln_s).with("#{base}/a", 'config/a')
      expect(FileUtils).to receive(:ln_s).with("#{base}/b", 'config/b')
      expect(FileUtils).to receive(:ln_s).with("#{base}/c", 'config/c')

      subject.link_global_configuration(%w(a b c))
    end

    it 'skips an existing file' do
      allow(File).to receive(:exist?).and_return(true)
      expect(FileUtils).not_to receive(:ln_s)

      subject.link_global_configuration(%w(a))
    end

    it 'raises an error for a missing file' do
      allow(File).to receive(:exist?).and_return(false)
      expect { subject.link_global_configuration(%w(a)) }
        .to raise_error(/Missing global config file/)
    end
  end

  context '#update_local_configuration' do
    let(:dist) { YAML.dump('a' => 1, 'b' => 2) }
    let(:target) { nil }

    let(:file) { 'a.yml' }
    let(:target_file) { "config/#{file}" }
    let(:dist_file) { "config/#{file}.dist" }
    let(:written) { [] }

    before do
      allow(File).to receive(:exist?).with(target_file).and_return(target)
      allow(File).to receive(:exist?).with(dist_file).and_return(dist)

      allow(File).to receive(:read).with(target_file).and_return(target)
      allow(File).to receive(:read).with(dist_file).and_return(dist)

      file = double(File)
      allow(File).to receive(:open).with(target_file, 'w').and_yield(file)
      allow(file).to receive(:write) { |str| written << str }
    end

    def run
      subject.update_local_configuration([file])
    end

    def updated_config
      expect(written).not_to be_empty
      YAML.safe_load(written.join, [Symbol])
    end

    context 'when the target does not exist' do
      it 'creates the target' do
        run
        expect(updated_config).to eq('a' => 1, 'b' => 2)
      end
    end

    context 'when the target is missing an option' do
      let(:target) { YAML.dump('a' => 2) }

      it 'merges the new configuration option' do
        run
        expect(updated_config).to eq('a' => 2, 'b' => 2)
      end
    end

    context 'when the target has an extra option' do
      let(:target) { YAML.dump('a' => 2, 'b' => 2, 'c' => 3) }

      it 'retains the extra option' do
        run
        expect(updated_config).to eq('a' => 2, 'b' => 2, 'c' => 3)
      end
    end

    context 'when a deeply nested option is added' do
      let(:dist) { YAML.dump('a' => 1, 'b' => { 'd' => 3, 'e' => 4 }) }
      let(:target) { YAML.dump('a' => 14, 'b' => { 'd' => 30 }) }

      it 'merges the new configuration option' do
        run
        expect(updated_config).to eq('a' => 14, 'b' => { 'd' => 30, 'e' => 4 })
      end
    end

    context 'when a deeply nested option is removed' do
      let(:dist) { YAML.dump('a' => 1, 'b' => { 'd' => 3 }) }
      let(:target) { YAML.dump('a' => 14, 'b' => { 'd' => 30, 'e' => 4 }) }

      it 'retains the option' do
        run
        expect(updated_config).to eq('a' => 14, 'b' => { 'd' => 30, 'e' => 4 })
      end
    end

    context 'when the filename is not "*.yml"' do
      let(:file) { 'a.txt' }

      it 'raises an error' do
        expect { run }.to raise_error(/Not a \.yml file/)
      end
    end

    context 'when the dist file is missing' do
      let(:dist) { nil }

      it 'raises an error' do
        expect { run }.to raise_error(/Missing dist config file/)
      end
    end

    context 'when the files contain symbol keys' do
      let(:dist) { YAML.dump(a: 2) }
      let(:target) { YAML.dump(a: 3) }

      it 'merges the new configuration option' do
        run
        expect(updated_config).to eq(a: 3)
      end
    end
  end

  describe '#install_dist_template' do
    let(:filename) { Faker::Lorem.words(2).join('.') }
    let(:src) { "config/#{filename}.dist" }
    let(:dest) { "config/#{filename}" }

    def run
      subject.install_dist_template([filename])
    end

    before do
      allow(File).to receive(:exist?).with(src).and_return(true)
    end

    context 'when the target file exists' do
      before do
        allow(File).to receive(:exist?).with(dest).and_return(true)
      end

      it 'does not copy the file' do
        expect(FileUtils).not_to receive(:copy)
        run
      end
    end

    context 'when the target file does not exist' do
      before do
        allow(File).to receive(:exist?).with(dest).and_return(false)
      end

      it 'copies the file' do
        expect(FileUtils).to receive(:copy).with(src, dest)
        run
      end
    end
  end

  def create_db_query(db)
    "CREATE DATABASE IF NOT EXISTS `#{db}` CHARACTER SET utf8 COLLATE utf8_bin"
  end
end
