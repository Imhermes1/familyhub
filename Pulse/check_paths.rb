require 'xcodeproj'
require 'pathname'
base = Pathname(File.expand_path('.'))
proj = Xcodeproj::Project.open('Family Hub.xcodeproj')
missing = []
proj.files.each do |f|
  next unless f.path
  path = Pathname(f.real_path)
  missing << [f.path, path] unless path.exist?
end
puts "Missing refs: #{missing.size}"
missing.each { |p, full| puts "- #{p} -> #{full}" }
