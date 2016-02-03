class CreateConnections < ActiveRecord::Migration
  def change
    create_table :connections do |t|
    	t.integer "user_id"
    	t.string "session_id"
    	t.string "uuid"
    	t.timestamps
    end
  end
end
