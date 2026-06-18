#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_fortress.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_fortress'
  s.version          = '0.1.0'
  s.summary          = 'Runtime Application Self-Protection (RASP) for Flutter.'
  s.description      = <<-DESC
A production-ready RASP security plugin that adds SSL pinning, root/jailbreak detection, anti-Frida, anti-screenshot, and app tamper detection to Flutter apps.
                       DESC
  s.homepage         = 'https://github.com/example/flutter_fortress'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Fortress' => 'dev@flutterfortress.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_fortress/Sources/flutter_fortress/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'flutter_fortress_privacy' => ['flutter_fortress/Sources/flutter_fortress/PrivacyInfo.xcprivacy']}
end
