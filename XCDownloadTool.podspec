
Pod::Spec.new do |s|

  s.name         = "XCDownloadTool"
  s.version      = "0.1.2"
  s.summary      = "Swift breakpoint continuingly download tools"

  s.description  = <<-DESC
                  Swift breakpoint continuingly download tools, restart the APP temporarily download data recovery
                   DESC

  s.homepage     = "https://github.com/wuchun4/XCDownloadTool"
  s.screenshots  = "https://github.com/wuchun4/XCDownloadTool/blob/master/2017-03-07%2010.46.53.gif" #, "www.example.com/screenshots_2.gif"
  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "https://github.com/wuchun4/XCDownloadTool/blob/master/LICENSE" }
  s.author             = { "Simon" => "870396896@qq.com" }

  # s.platform     = :ios
  s.platform     = :ios, "8.0"

  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/wuchun4/XCDownloadTool.git", :tag => "#{s.version}", :submodules => true  }

  s.ios.source_files  = "XCDownloadTool/**/*.{swift}"
  #s.exclude_files = "Classes/Exclude"

  s.requires_arc = true

end
