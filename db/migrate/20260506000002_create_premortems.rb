class CreatePremortems < ActiveRecord::Migration[8.1]
  def change
    create_table :premortems, id: :uuid do |t|
      t.references :initiative, null: false, foreign_key: true, type: :uuid
      t.date   :imagined_failure_date
      t.text   :reflection
      t.text   :avoided_truth
      t.text   :gemini_raw
      t.timestamps null: false
    end

    add_index :premortems, [:initiative_id, :created_at]
  end
end
