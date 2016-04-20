ActiveRecord::Schema.define(version: 0) do
  create_table :roles do |t|
    t.string :name, null: false
    t.timestamps null: false
  end

  create_table :permissions do |t|
    t.string :value, null: false
    t.belongs_to :role, null: false
    t.timestamps null: false
    t.index [:role_id, :value], unique: true
  end

  create_table :api_subjects do |t|
    t.string :x509_cn, null: false
    t.string :contact_name, null: false
    t.string :contact_mail, null: false
    t.string :description, null: false
    t.boolean :enabled, null: false
    t.timestamps null: false
  end

  create_table :api_subject_roles do |t|
    t.belongs_to :api_subject, null: false
    t.belongs_to :role, null: false
    t.timestamps null: false
  end

  create_table :subjects do |t|
    t.string :name, null: false
    t.string :mail, null: false
    t.string :targeted_id, null: false
    t.string :shared_token, null: false
    t.boolean :enabled, null: false
    t.boolean :complete, null: false
    t.timestamps null: false
  end

  create_table :subject_roles do |t|
    t.belongs_to :subject, null: false
    t.belongs_to :role, null: false
    t.timestamps null: false
  end

  add_foreign_key 'api_subject_roles', 'api_subjects'
  add_foreign_key 'api_subject_roles', 'roles'
  add_foreign_key 'permissions', 'roles'
  add_foreign_key 'subject_roles', 'roles'
  add_foreign_key 'subject_roles', 'subjects'
end
