Pod::Spec.new do |s|
    s.name             = "AsyncActivityItemProvider"
    s.version          = "0.0.1"
    s.summary          = "AsyncActivityItemProvider provides a closure-based interface for generating and providing items to UIActivityViewController"
    s.description      = <<-DESC
    AsyncActivityItemProvider provides a closure-based interface for generating and providing items to UIActivityViewController.
        DESC
        s.homepage         = "https://github.com/jedlewison/AsyncActivityItemProvider"
        s.license          = 'MIT'
        s.author           = { "Jed Lewison" => "jed@.....magic....app....factory.com" }
        s.source           = { :git => "https://github.com/jedlewison/AsyncActivityItemProvider.git", :tag => s.version.to_s }
        s.platform     = :ios, '8.0'
        s.requires_arc = true
        s.source_files = 'Pod/*.swift'
        s.dependency = 'AsyncOpKit'
end
