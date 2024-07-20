platform :macos, '10.13'
inhibit_all_warnings!

target 'WeChatTweak' do
  pod 'JRSwizzle'
  pod 'GCDWebServer'
  pod 'fishhook', :podspec => 'fishhook.podspec'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'ARCHS'
      config.build_settings.delete 'MACOSX_DEPLOYMENT_TARGET'
    end
  end
end
