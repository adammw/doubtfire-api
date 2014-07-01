class CreateHelpdeskSchedules < ActiveRecord::Migration
  def change
    create_table :helpdesk_schedules do |t|
      t.datetime :start_time
      t.int :duration
      t.int :day
      t.references :user, index: true
      t.timestamps
    end
  end
end
