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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_03_18_142105) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "user"
    t.string "seller_id"
    t.string "feed_id"
    t.datetime "feed_upload"
    t.string "process"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "amazon_products", force: :cascade do |t|
    t.string "asin"
    t.text "title"
    t.string "image1"
    t.string "image2"
    t.string "image3"
    t.string "image4"
    t.string "image5"
    t.string "image6"
    t.string "image7"
    t.string "image8"
    t.text "description"
    t.text "detail"
    t.string "brand"
    t.string "part_number"
    t.string "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asin"], name: "for_upsert_amazon_products", unique: true
  end

  create_table "list_templates", force: :cascade do |t|
    t.string "user"
    t.string "list_type"
    t.string "header"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lists", force: :cascade do |t|
    t.string "user"
    t.string "asin"
    t.string "seller_id"
    t.integer "seller_price"
    t.integer "list_price"
    t.string "condition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "ng_flg", default: false
    t.boolean "list_flg", default: false
    t.index ["user", "asin"], name: "for_upsert_lists", unique: true
  end

  create_table "prices", force: :cascade do |t|
    t.string "user"
    t.integer "original_price"
    t.integer "convert_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.string "user"
    t.string "ng_type"
    t.text "keyword"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "admin_flg", default: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
