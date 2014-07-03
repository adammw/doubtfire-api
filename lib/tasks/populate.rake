namespace :db do

  desc "Clear the database and fill with test data"
  task populate: [:setup, :migrate] do
    require 'populator'
    require 'faker'
    require 'bcrypt'

    scale = ENV["SCALE"] || 'small'

    # if it is small scale less students and tutorials
    if scale == 'small'
      min_students = 5
      delta_students = 2
      few_tasks = 5
      some_tasks = 10
      many_task = 20
      few_tutorials = 1
      some_tutorials = 1
      many_tutorials = 1
      max_tutorials = 4
    else
      min_students = 15
      delta_students = 7
      few_tasks = 10
      some_tasks = 30
      many_task = 50
      few_tutorials = 1
      some_tutorials = 2
      many_tutorials = 4
      max_tutorials = 20
    end

    puts "--> Starting populate (#{scale} scale)"

    roles = [
      :student,
      :tutor,
      :convenor,
      :moderator
    ]

    users = {
      acain:              {first_name: "Andrew",         last_name: "Cain",                 nickname: "Macite", system_role: 'admin' },
      cwoodward:          {first_name: "Clinton",        last_name: "Woodward",             nickname: "The Giant", system_role: 'admin' },
      ajones:             {first_name: "Allan",          last_name: "Jones",                nickname: "P-Jiddy"},
      rliston:            {first_name: "Rohan",          last_name: "Liston",               nickname: "Gunner"},
      akihironoguchi:     {first_name: "Akihiro",        last_name: "Noguchi",              nickname: "Unneccesary Animations"},
      joostfunkekupper:   {first_name: "Joost",          last_name: "Funke Kupper",         nickname: "Joe"},
    }

    10.times do |count|
      tutor_name = "tutor_#{count}";
      users[tutor_name] = { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, nickname: tutor_name}
    end

    # user_roles = {
    #   student:   [:ajones, :rliston, :akihironoguchi, :joostfunkekupper],
    #   tutor:     [:acain, :cwoodward],
    #   convenor:  [:acain, :cwoodward],
    # }


    # List of subject names to use
    # subjects = {
    #   "COS10001" => "Introduction To Programming",
    #   "COS20007" => "Object-Oriented Programming",
    #   "COS03243" => "Games Programming",
    #   "COS03046" => "Artificial Intelligence for Games"
    # }

    unit_data = {
      intro_prog: { 
        code: "COS10001", 
        name: "Introduction to Programming", 
        convenors: [ :acain, :cwoodward ], 
        tutors: [ 
          { user: :acain, num: many_tutorials}, 
          { user: :cwoodward, num: many_tutorials}, 
          { user: :ajones, num: many_tutorials}, 
          { user: :rliston, num: many_tutorials}, 
          { user: :akihironoguchi, num: many_tutorials}, 
          { user: :joostfunkekupper, num: many_tutorials},
          { user: "tutor_1", num: some_tutorials},
          { user: "tutor_2", num: some_tutorials},
          { user: "tutor_3", num: some_tutorials},
          { user: "tutor_4", num: some_tutorials},
          { user: "tutor_5", num: some_tutorials},
          # { user: "tutor_6", num: 4},
          # { user: "tutor_7", num: 4},
          # { user: "tutor_8", num: 4},
          # { user: "tutor_9", num: 4},
          # { user: "tutor_10", num: 4},
        ], 
        num_tasks: some_tasks,
        students: [ ]
      },
      oop: { 
        code: "COS20007", 
        name: "Object Oriented Programming", 
        convenors: [ :acain, :cwoodward, :ajones ], 
        tutors: [ 
          { user: "tutor_1", num: few_tutorials }, 
          { user: "tutor_2", num: few_tutorials }, 
          { user: "tutor_3", num: few_tutorials }, 
          { user: :rliston, num: few_tutorials }, 
          { user: :akihironoguchi, num: few_tutorials }, 
          { user: :joostfunkekupper, num: few_tutorials },
        ], 
        num_tasks: many_task,
        students: [ ]
      },
      ai4g: { 
        code: "COS03046", 
        name: "Artificial Intelligence for Games", 
        convenors: [ :cwoodward ], 
        tutors: [ 
          { user: :cwoodward, num: few_tutorials }, 
        ], 
        num_tasks: few_tasks,
        students: [ :acain, :ajones ]
      },
      ai4g: { 
        code: "COS03243", 
        name: "Game Programming", 
        convenors: [ :cwoodward ], 
        tutors: [ 
          { user: :cwoodward, num: few_tutorials }, 
        ], 
        num_tasks: few_tasks,
        students: [ :acain, :ajones ]
      },
    }

    # Collection of weekdays
    days = %w[Monday Tuesday Wednesday Thursday Friday]

    puts "----> Create TaskStatus"
    TaskStatus.create(name:  "Not Submitted",     description:  "This task has not been submitted to marked by your tutor.")
    TaskStatus.create(name:  "Complete",          description:  "This task has been signed off by your tutor.")
    TaskStatus.create(name:  "Need Help",         description:  "Some help is required in order to complete this task.")
    TaskStatus.create(name:  "Working On It",     description:  "This task is currently being worked on.")
    TaskStatus.create(name:  "Fix and Resubmit",  description:  "This task must be resubmitted after fixing some issues.")
    TaskStatus.create(name:  "Fix and Include",   description:  "This task must be fixed and included in your portfolio, but should not be resubmitted.")
    TaskStatus.create(name:  "Redo",              description:  "This task needs to be redone.")
    TaskStatus.create(name:  "Discuss",           description:  "Your work looks good, discuss it with your tutor to complete.")
    TaskStatus.create(name:  "Ready to Mark",     description:  "This task is ready for the tutor to assess to provide feedback.")


    puts "----> Adding Roles"
    role_cache = {}
    roles.each do |role|
      role_cache[role] = Role.create!(name: role.to_s.titleize)
    end

    user_cache = {}

    # Create users
    puts "----> Adding users"
    users.each do |user_key, profile|
      username = user_key.to_s

      profile[:system_role] ||= 'basic'
      profile[:email]       ||= "#{username}@doubtfire.com"
      profile[:username]    ||= username

      user = User.create!(profile.merge({password: 'password', password_confirmation: 'password'}))
      user_cache[user_key] = user
    end

    # Function to find or create students
    find_or_create_student = lambda { |username|
      if user_cache.has_key?(username)
        return user_cache[username]
      else
        profile = { 
          first_name:   Faker::Name.first_name, 
          last_name:    Faker::Name.last_name, 
          nickname:     username,
          system_role:  'basic',
          email:        "#{username}@doubtfire.com",
          username:     username,
          password:     'password', 
          password_confirmation: 'password',
        }

        user = User.create!(profile)
        user_cache[username] = user
        return user       
      end
    }

    # print "----> Adding Students "
    # 1000.times do | count |
    #   username = "student_#{count}"

    #   if count % 100 == 0
    #     print '.'
    #   end

    #   profile = { 
    #     first_name:   Faker::Name.first_name, 
    #     last_name:    Faker::Name.last_name, 
    #     nickname:     "stud_#{count}",
    #     system_role:  'basic',
    #     email:        "#{username}@doubtfire.com",
    #     username:     username,
    #     password:     'password', 
    #     password_confirmation: 'password',
    #   }

    #   user = User.create!(profile)
    #   user_cache[username] = user
    # end
    # puts '!'


    puts "----> Adding Units"
    # Create projects (units) for each of the values in unit_data
    unit_data.each do | unit_key, unit_details |
      puts "------> #{unit_details[:code]}"
      unit = Unit.create!(
        code: unit_details[:code],
        name: unit_details[:name],
        description: Populator.words(10..15),
        start_date: Date.current,
        end_date: 13.weeks.since(Date.current)
      )

      puts "--------> #{unit_details[:num_tasks]} tasks"
      # Create tasks for unit
      unit_details[:num_tasks].times do |count|
        TaskDefinition.create(
          name: "Assignment #{count + 1}",
          abbreviation: "A#{count + 1}",
          unit_id: unit.id,
          description: Populator.words(5..10),
          weighting: BigDecimal.new("2"),
          required: rand < 0.9,   # 10% chance of being false
          target_date: ((count + 1) % 12).weeks.from_now # Assignment 6 due week 6, etc.
        )
      end

      # Create convenor roles
      unit_details[:convenors].each do | user_key |
        UnitRole.create!(role_id: role_cache[:convenor].id, user_id: user_cache[user_key].id, unit_id: unit.id)
      end

      student_count = 0
      tutorial_count = 0

      # Create tutorials and enrol students
      unit_details[:tutors].each do | user_details |
        #only up to 4 tutorials for small scale
        if tutorial_count > max_tutorials then break end
        tutorial_count += 1

        tutor = user_cache[user_details[:user]]
        puts "--------> Tutor #{tutor.name}"
        tutor_unit_role = UnitRole.create!(role_id: role_cache[:tutor].id, user_id: tutor.id, unit_id: unit.id)

        print "---------> #{user_details[:num]} tutorials"
        user_details[:num].times do | count |
          tutorial = Tutorial.create(
            unit_id: unit.id,
            unit_role_id: tutor_unit_role.id,
            meeting_time: "#{8 + rand(12)}:#{['00', '30'].sample}",    # Mon-Fri 8am-7:30pm
            meeting_day: "#{days.sample}",
            meeting_location: "#{['EN', 'BA'].sample}#{rand(7)}#{rand(1)}#{rand(9)}" # EN###/BA###
          )

          # Add a random number of students to the tutorial
          (min_students + rand(delta_students)).times do
            unit.add_user(find_or_create_student.call("student_#{student_count}").id, tutorial.id, "student")
            student_count += 1
          end

          print '.'

          # Add fixed students to first tutorial
          if count == 0
            unit_details[:students].each do | student_key |
              unit.add_user(user_cache[student_key].id, tutorial.id, "student")
            end
          end
        end
        puts "!"
      end #tutorial
    end #unit


    puts "creating schedules"
    schedule = [ 
      { tut: :acain, 
        times: [ 
          { day: 0, start_time: DateTime.parse("08:00"), duration: 120 }, 
          { day: 1, start_time: DateTime.parse("09:00"), duration: 120 }, 
          { day: 2, start_time: DateTime.parse("14:00"), duration: 120 }, 
          { day: 3, start_time: DateTime.parse("10:00"), duration: 120 }, 
          { day: 4, start_time: DateTime.parse("13:00"), duration: 120 } 
        ]
      }, 
      { tut: :cwoodward, 
        times: [ 
          { day: 0, start_time: DateTime.parse("08:00"), duration: 120 }, 
          { day: 1, start_time: DateTime.parse("10:00"), duration: 120 }, 
          { day: 2, start_time: DateTime.parse("15:00"), duration: 120 }, 
          { day: 3, start_time: DateTime.parse("12:00"), duration: 120 }, 
          { day: 4, start_time: DateTime.parse("09:00"), duration: 120 } 
        ]
      } 
    ]
    schedule.each do | s | 
      s[:times].each do | t | 
        test_schedule = HelpdeskSchedule.new(start_time: t[:start_time], duration: t[:duration], day: t[:day], user: user_cache[s[:tut]]) 
        test_schedule.save
      end 
    end #schedule



    puts "----> Done."
  end
end
