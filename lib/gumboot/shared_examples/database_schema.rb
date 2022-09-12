# frozen_string_literal: true

RSpec.shared_examples 'Database Schema' do
  context 'AAF shared implementation' do
    RSpec::Matchers.define :have_collations do |expected, name|
      match { |actual| expected.include?(actual[:Collation]) }

      failure_message do |actual|
        "expected #{name} to use collation #{expected.join(' or ')}, but was " \
          "#{actual[:Collation]}"
      end
    end

    before { expect(connection).to be_a(Mysql2::Client) }

    def query(sql)
      connection.query(sql, as: :hash, symbolize_keys: true)
    end

    it 'has the correct encoding set for the connection' do
      expect(connection.query_options).to include(encoding: 'utf8')
    end

    it 'has the correct collation set for the connection' do
      expect(connection.query_options).to include(collation: 'utf8_bin')
    end

    it 'has the correct collation' do
      exemptions = defined?(collation_exemptions) ? collation_exemptions : []

      db_collation = query('SHOW VARIABLES LIKE "collation_database"')
                     .first[:Value]
      expect(%w[utf8_bin utf8mb3_bin utf8mb4_bin]).to include(db_collation)

      query('SHOW TABLE STATUS').each do |table|
        table_name = table[:Name]
        next if table_name == 'schema_migrations'

        expect(table).to(
          have_collations(%w[utf8_bin utf8mb3_bin utf8mb4_bin], "`#{table_name}`")
        )

        query("SHOW FULL COLUMNS FROM `#{table_name}`").each do |column|
          next unless column[:Collation]
          next if exemptions.any? do |except_table, except_columns|
                    except_table == table_name.to_sym &&
                    except_columns.any? do |except_column|
                      except_column == column[:Field].to_sym
                    end
                  end

          expect(column)
            .to have_collations(%w[utf8_bin utf8_unicode_ci utf8mb3_bin utf8mb4_bin utf8mb4_unicode_ci],
                                " `#{table_name}`.`#{column[:Field]}`")
        end
      end
    end
  end
end
