class CreateHelpdeskSchedules < ActiveRecord::Migration
  def change
    create_table :helpdesk_schedules do |t|
      t.datetime :start_time
      t.integer :duration
      t.integer :day
      t.references :user, index: true
      t.timestamps
    end
  end
end
