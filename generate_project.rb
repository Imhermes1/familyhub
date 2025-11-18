require 'xcodeproj'
require 'pathname'

project_path = 'Family Hub.xcodeproj'
proj = Xcodeproj::Project.new(project_path)

app_target = proj.new_target(:application, 'Family Hub', :ios, '18.0')
base = Pathname(File.expand_path(Dir.pwd))

def add_files_to_target(proj, group, base_path, target, base_dir)
  Dir.glob(File.join(base_path, '**', '*'), File::FNM_DOTMATCH).sort.each do |path|
    next if ['.', '..'].include?(File.basename(path))
    next if File.directory?(path)
    rel_path = Pathname(File.expand_path(path)).relative_path_from(base_dir).to_s
    file_ref = proj.files.find { |f| f.path == rel_path } || group.new_file(rel_path)
    ext = File.extname(path)
    case ext
    when '.swift'
      target.add_file_references([file_ref])
    when '.xcassets', '.strings', '.json', '.plist'
      target.add_resources([file_ref]) unless File.basename(path) == 'Info.plist'
    end
  end
end

proj.new_group('Config', 'Config') if Dir.exist?('Config')
pulse_group = proj.new_group('Pulse', 'Pulse')
add_files_to_target(proj, pulse_group, 'Pulse', app_target, base)

app_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.familyhub'
  config.build_settings['INFOPLIST_FILE'] = 'Pulse/Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Pulse/Pulse.entitlements'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
end

proj.save
puts "Generated #{project_path} with target 'Family Hub'"
