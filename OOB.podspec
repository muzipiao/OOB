Pod::Spec.new do |s|
  s.name             = 'OOB'
  s.version          = '0.1.4'
  s.summary          = 'iOS 通过摄像头图像识别，基于 OpenCV 实现。'
  s.description      = <<-DESC
                        基于 OpenCV “模板匹配法”的图像识别工具类，可通过 cocoapods 一键集成，快速使用。
                       DESC
  s.homepage         = 'https://github.com/muzipiao'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lifei' => 'lifei_zdjl@126.com' }
  s.source           = { :git => 'https://github.com/muzipiao/OOB.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.prefix_header_file = false
  s.static_framework   = true
  s.source_files = 'OOB/Classes/**/*'
  s.dependency 'OpenCV2', '~> 4.1.0'
  s.frameworks = 'Foundation', 'UIKit', 'AVFoundation'
  s.requires_arc = true
end
