require 'xcodeproj'
proj = Xcodeproj::Project.open('Family Hub.xcodeproj')

target = proj.targets.find { |t| t.name == 'Family Hub' }
if target
  target.name = 'Pulse'
  target.product_name = 'Pulse'
  target.product_reference.path = 'Pulse.app' if target.product_reference
end

proj.root_object.name = 'Pulse'
proj.save
puts 'Renamed target/project to Pulse'
