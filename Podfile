# Uncomment the next line to define a global platform for your project
platform :macos, '12.0'

target 'VMware' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for VMware
  pod 'GitHubRelease', :git => 'https://github.com/MarLoe/GitHub.Release'
  pod 'STPrivilegedTask', :git => 'https://github.com/sveinbjornt/STPrivilegedTask'
end

target 'VMware.Debug' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for VMware.Debug

end

# Some pods (e.g. STPrivilegedTask) declare a deployment target older than the
# minimum the current Xcode supports. Lift them to the project's minimum.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
