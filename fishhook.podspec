Pod::Spec.new do |spec|
  spec.name             = "fishhook"
  spec.version          = "0.2"
  spec.license          = { :type => "BSD", :file => "LICENSE" }
  spec.homepage         = 'https://github.com/facebook/fishhook'
  spec.author           = { "Facebook, Inc." => "https://github.com/facebook" }
  spec.summary          = "A library that enables dynamically rebinding symbols in Mach-O binaries running on iOS."
  spec.source           = { :git => "https://github.com/facebook/fishhook.git", :tag => '0.2'}
  spec.source_files     = "fishhook.{h,c}"
  spec.social_media_url = 'https://twitter.com/fbOpenSource'

  spec.macos.deployment_target = '10.9'
end
