Pod::Spec.new do |s|
  s.name         = "ETBinding"
  s.version      = "1.1"
  s.summary      = "ETBinding"
  s.description  = <<-DESC
    LiveData is an observable data holder class. Unlike a regular observable, LiveData is lifecycle-aware, meaning it respects the lifecycle of its owner. This awareness ensures LiveData only updates app component observers that are in an active lifecycle state.
  DESC
  s.homepage     = "https://github.com/EtneteraMobile/ETBinding"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Jan Cislinsky" => "jan.cislinsky@etnetera.cz" }
  s.social_media_url   = ""
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/EtneteraMobile/ETBinding.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "Foundation"
  s.dependency 'ETObserver'
end
