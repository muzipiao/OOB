
Pod::Spec.new do |s|

  s.name         = "OOB"
  s.version      = "1.0.0"
  s.summary      = "iOS 通过摄像头图像识别，基于 OpenCV 实现。"
  s.homepage     = "https://github.com/muzipiao/OOB"
  s.license      = "MIT"
  s.author       = { "lifei" => "lifei_zdjl@126.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/muzipiao/OOB.git", :tag => s.version}

  s.source_files = "OOB/**/*.{h,m}"
  s.requires_arc = true
  s.frameworks = 'Foundation', 'UIKit', 'AVFoundation'

end
