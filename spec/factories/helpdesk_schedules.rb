# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :helpdesk_schedule do
    start_time ""
    duration ""
    day ""
    user nil
  end
end
