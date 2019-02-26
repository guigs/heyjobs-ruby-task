# frozen_string_literal: true

require 'active_record'

# Set up a database that resides in RAM
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Set up database tables and columns
ActiveRecord::Schema.define do
  create_table :campaigns, force: true do |t|
    t.bigint :job_id
    t.string :status
    t.string :external_reference
    t.text :ad_description
  end
end
