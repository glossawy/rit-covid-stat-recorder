###
# This is for local use
###

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :path, File.expand_path('../', __dir__)
set :output, File.expand_path('../log/cron.log', __dir__)
set :job_template, "/bin/zsh --login -c ':job'"

env 'PATH', ENV['PATH']

job_type :command, "cd :path && :task :output"
job_type :script, "cd :path && ./script/:task :output"
job_type :bundle_exec,  "cd :path && bundle exec :task :output"
job_type :recorder_exec, "cd :path && bin/recorder :task :output"

every 1.hours do 
  recorder_exec 'scrape fetch --notify'
end

every 24.hours, at: '9:00 pm' do
  script './backup'
end
