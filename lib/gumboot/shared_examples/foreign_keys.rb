def conn
  ActiveRecord::Base.connection
end

RSpec.shared_examples 'Foreign Keys' do |from_table, to_table, fk|
  context 'Permissions Foreign Keys', if: conn.supports_foreign_keys? do
    it 'should have a foreign key' do
      expect(table_has_fk(from_table, fk)).to be_truthy
    end
    it 'should have a foreign key that points to the correct table' do
      expect(fk_exists_between(from_table, to_table)).to be_truthy
    end
  end

  def table_has_fk(table, foreign_key)
    conn.foreign_keys(table).find do |fk|
      fk.options[:column] == foreign_key
    end
  end

  def fk_exists_between(from_table, to_table)
    conn.foreign_keys(from_table).find do |fk|
      fk[:to_table] == to_table
    end
  end
end
