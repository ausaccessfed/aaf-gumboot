RSpec.shared_examples 'Database Schema' do
  context 'AAF shared implementation' do
    RSpec::Matchers.define :have_collation do |expected|
      match { |actual| actual[:Collation] == expected }

      failure_message do |actual|
        format('expected table `%<Name>s` to use collation `%<expected>s`, ' \
               'but was `%<Collation>s`', actual.merge(expected: expected))
      end
    end

    before { expect(connection).to be_a(Mysql2::Client) }

    it 'has the correct encoding set for the connection' do
      expect(connection.query_options).to include(encoding: 'utf8')
    end

    it 'has the correct collation set for the connection' do
      expect(connection.query_options).to include(collation: 'utf8_bin')
    end

    it 'has the correct collation' do
      result = connection.query('SHOW TABLE STATUS',
                                as: :hash, symbolize_keys: true)
      result.each do |table|
        next if table[:Name] == 'schema_migrations'
        expect(table).to have_collation('utf8_bin')
      end
    end
  end
end
