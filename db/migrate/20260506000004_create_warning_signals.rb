class CreateWarningSignals < ActiveRecord::Migration[8.1]
  def change
    create_table :warning_signals, id: :uuid do |t|
      t.references :failure_mode, null: false, foreign_key: true, type: :uuid
      t.text :signal,             null: false
      t.text :measurement_method, null: false
      t.timestamps null: false
    end
  end
end
