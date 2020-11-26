Hanami::Model.migration do
  change do
    create_table :collection_attempts do
      primary_key :id

      column :success, TrueClass, null: false
      column :reason, String, null: false
      column :note, String, null: false

      foreign_key :covid_stat_id, :covid_stats, on_delete: :cascade, null: true

      column :attempted_at, DateTime, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end
end
