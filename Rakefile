require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = ['test/*.rb']
  t.warning = true
end

Rake::TestTask.new(bench: :loadavg) do |t|
  t.pattern = ['test/bench/*.rb']
  t.warning = true
  t.description = "Run benchmarks"
end

desc "Show current system load"
task :loadavg do
  puts "/proc/loadavg %s" % (File.read("/proc/loadavg") rescue "Unavailable")
end

task :default => :test
