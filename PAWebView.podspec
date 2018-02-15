

Pod::Spec.new do |s|

  s.name         = "PAWebView"
  s.version      = "0.0.1"
  s.summary      = " An component WebView for iOS base on WKWebView ."
  s.description  = <<-DESC
                   PAWeView is an extensible WebView which is built on top of WKWebView, the modern WebKit framework debuted in iOS 8.0. It provides fast Web for developing sophisticated iOS native or hybrid applications.
                   DESC
 
  s.homepage     = "https://github.com/llyouss/PAWeView"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Luoshengyou" => "13798686545@163.com" }
  s.platform     = :ios, "8.0"
  s.requires_arc = true   
  s.source       = { :git => "https://github.com/llyouss/PAWeView.git", :tag => "0.0.1" }
  s.source_files  ="PAWebView/**/*.{m,h}"
  s.resources = "PAWebView/PAWKNative/views/*.png"


end
