class CreateFailureModes < ActiveRecord::Migration[8.1]
  def change
    create_table :failure_modes, id: :uuid do |t|
      t.references :premortem, null: false, foreign_key: true, type: :uuid
      t.text    :statement,   null: false
      t.string  :severity,    null: false
      t.text    :assumption,  null: false
      t.integer :rank,        null: false
      t.timestamps null: false
    end

    add_index :failure_modes, [:premortem_id, :rank]
  end
end
