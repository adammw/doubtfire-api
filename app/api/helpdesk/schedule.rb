require 'grape'

module Api
  module Helpdesk 
    class Schedule < Grape::API
      helpers AuthHelpers

      before do
        authenticated?
      end

      desc "Get the helpdesk schedule"
      params do 
        optional :date, type: DateTime, desc: "A date in the week that a schedule is being requested"
      end 
      get '/helpdesk/schedule' do
        requested_week = Time.now
        if params[:date] 
          requested_week = params[:date]
        end 

        schedules = HelpdeskSchedule.all
        this_week = requested_week.beginning_of_week
        schedules.each do |s|
          schedule_date = this_week + s.day.days
          s.start_time = s.start_time.change(year: schedule_date.year, month: schedule_date.month, day: schedule_date.day) 
        end 
        ActiveModel::ArraySerializer.new(schedules, each_serializer: HelpdeskScheduleSerializer)
      end

    end
  end
end
