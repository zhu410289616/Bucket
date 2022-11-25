Pod::Spec.new do |spec|

  spec.name         = "CCDBucket"
  spec.version      = "0.0.2"
  spec.summary      = "Bucket: 数据跟踪能力集合"

  spec.description  = <<-DESC
			数据跟踪能力集合，支持通过浏览器查看实时日志
                   DESC

  spec.homepage     = "https://github.com/zhu410289616/Bucket"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "zhu410289616" => "zhu410289616@163.com" }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/zhu410289616/Bucket.git", :tag => "#{spec.version}" }
  
  spec.default_subspec = "Core"
  
  spec.subspec "Core" do |cs|
    cs.source_files = "Pod/Core/**/*.{h,m,mm}"
    cs.dependency "CocoaLumberjack"
  end
  
#  spec.subspec "MarsLogger" do |cs|
#    cs.source_files = "Pod/MarsLogger/**/*"
#    cs.vendored_frameworks = [
#      "Pod/MarsLogger/mars.framework"
#    ]
#    cs.frameworks = "SystemConfiguration", "CoreTelephony"
#    cs.libraries = "z", "resolv.9", "stdc++"
#  end
  
  spec.subspec "DamServer" do |cs|
    cs.source_files = "Pod/DamServer/**/*.{h,m,mm}"
    cs.resource = "Pod/DamServer/**/*.bundle"
    cs.dependency "GCDWebSocket"
  end

#  ### usbmux
#  ### https://github.com/zhu410289616/KKConnector
#  spec.subspec "PeerTalkServer" do |cs|
#    cs.source_files = "Pod/PeerTalkServer/**/*.{h,m,mm}"
#    cs.dependency "KKConnectorServer"
#  end
  
end
