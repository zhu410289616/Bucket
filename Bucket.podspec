Pod::Spec.new do |spec|

  spec.name         = "Bucket"
  spec.version      = "0.0.1"
  spec.summary      = "Bucket: 数据跟踪能力集合"

  spec.description  = <<-DESC
			数据跟踪能力集合，支持通过浏览器查看实时日志
                   DESC

  spec.homepage     = "https://github.com/zhu410289616/Bucket"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "zhu410289616" => "zhu410289616@163.com" }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/zhu410289616/Bucket.git", :tag => "#{spec.version}" }
  
  spec.default_subspec = "Logger"
  
  spec.subspec "Logger" do |cs|
    cs.source_files = "Pod/Logger/**/*.{h,m,mm}"
    cs.dependency "CocoaLumberjack"
  end
  
  spec.subspec "MarsLogger" do |cs|
    cs.source_files = "Pod/Classes/**/*"
    cs.vendored_frameworks = [
      "Pod/Frameworks/mars.framework"
    ]
    cs.frameworks = "SystemConfiguration", "CoreTelephony"
    cs.libraries = "z", "resolv.9", "stdc++"
  end
  
  spec.subspec "DamServer" do |cs|
    cs.source_files = "Pod/DamServer/**/*.{h,m,mm}"
    cs.resource = "Pod/DamServer/**/*.bundle"
    cs.dependency "GCDWebServer/WebSocket"
  end
  
end
