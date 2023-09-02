platform :macos, '10.12'
inhibit_all_warnings!

target 'WeChatTweak' do
  pod 'JRSwizzle'
  pod 'GCDWebServer'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'ARCHS'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = 10.12
    end
  end
end
