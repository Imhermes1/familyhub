require 'xcodeproj'
proj = Xcodeproj::Project.open('Pulse.xcodeproj')

target = proj.targets.find { |t| t.name == 'Pulse' } || proj.targets.first
target&.tap do |t|
  t.name = 'Pulse'
  t.product_name = 'Pulse'
  t.product_reference.path = 'Pulse.app' if t.product_reference
end

proj.root_object.name = 'Pulse'
proj.save
puts 'Renamed target/project to Pulse'
