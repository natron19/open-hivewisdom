class CreatePreventiveActions < ActiveRecord::Migration[8.1]
  def change
    create_table :preventive_actions, id: :uuid do |t|
      t.references :premortem, null: false, foreign_key: true, type: :uuid
      t.text    :description,             null: false
      t.integer :effectiveness_to_effort, null: false
      t.integer :rank,                    null: false
      t.boolean :started,                 null: false, default: false
      t.timestamps null: false
    end

    add_index :preventive_actions, [:premortem_id, :rank]
  end
end
