Pod::Spec.new do |s|
  s.name         = "ETBinding"
  s.version      = "3.1"
  s.summary      = "ETBinding"
  s.description  = <<-DESC
    ETBinding is set of observable classes. Unlike a regular observable is lifecycle-aware, meaning it respects the lifecycle of its owner.
  DESC
  s.homepage     = "https://github.com/EtneteraMobile/ETBinding"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Jan Cislinsky" => "jan.cislinsky@etnetera.cz" }
  s.social_media_url   = ""
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/EtneteraMobile/ETBinding.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "Foundation"
end
