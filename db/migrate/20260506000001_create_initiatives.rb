class CreateInitiatives < ActiveRecord::Migration[8.1]
  def change
    create_table :initiatives, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :name,                null: false
      t.text    :success_definition,  null: false
      t.string  :time_horizon,        null: false
      t.text    :current_state,       null: false
      t.text    :team_context,        null: false
      t.timestamps null: false
    end

    add_index :initiatives, [:user_id, :created_at]
  end
end
