require 'task_serializer'

class HelpdeskScheduleSerializer < ActiveModel::Serializer
  attributes :start, :end, :title, :allDay

  def start
    object.start_time
  end 

  def end
    object.start_time + object.duration.minutes
  end

  def title
    object.user.name
  end

  def allDay
    false
  end 

end

