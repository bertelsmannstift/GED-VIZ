# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130909131224) do

  create_table "countries", :force => true do |t|
    t.string "name"
    t.string "iso3"
  end

  add_index "countries", ["iso3"], :name => "index_countries_on_iso3", :unique => true

  create_table "data_types", :force => true do |t|
    t.string "key"
  end

  add_index "data_types", ["key"], :name => "index_data_types_on_key", :unique => true

  create_table "data_types_units", :force => true do |t|
    t.integer "data_type_id"
    t.integer "unit_id"
  end

  create_table "data_values", :force => true do |t|
    t.integer "data_type_id"
    t.integer "unit_id"
    t.integer "country_from_id"
    t.integer "country_to_id"
    t.integer "year"
    t.decimal "value",           :precision => 16, :scale => 4
  end

  add_index "data_values", ["data_type_id", "unit_id", "year"], :name => "index_data_values_on_data_type_id_and_unit_id_and_year"

  create_table "indicator_types", :force => true do |t|
    t.string  "key"
    t.string  "group"
    t.boolean "external"
    t.integer "position"
  end

  add_index "indicator_types", ["key"], :name => "index_indicator_types_on_key", :unique => true

  create_table "indicator_types_units", :force => true do |t|
    t.integer "indicator_type_id"
    t.integer "unit_id"
  end

  create_table "indicator_values", :force => true do |t|
    t.integer "indicator_type_id"
    t.integer "unit_id"
    t.integer "country_id"
    t.integer "year"
    t.decimal "value",             :precision => 16, :scale => 4
    t.integer "tendency"
    t.decimal "tendency_percent",  :precision => 8,  :scale => 4
  end

  add_index "indicator_values", ["indicator_type_id", "unit_id", "country_id", "year"], :name => "index_value_query"

  create_table "presentations", :force => true do |t|
    t.string "title"
    t.text   "keyframes"
  end

  create_table "units", :force => true do |t|
    t.string  "key"
    t.integer "representation"
    t.integer "position"
  end

  add_index "units", ["key"], :name => "index_units_on_key", :unique => true

end
