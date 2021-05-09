platform :osx, '10.10'
inhibit_all_warnings!

target 'WeChatTweak' do
  pod 'JRSwizzle'
  pod 'GCDWebServer'
  pod 'YYModel'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = 10.11
    end
  end
end
