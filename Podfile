source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.12'
use_frameworks!

target 'IdexTicker' do
  
pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', :tag => ‘4.7.0’




end


post_install do |installer|
   installer.pods_project.targets.each do |target|
       target.build_configurations.each do |config|
           config.build_settings['SWIFT_VERSION'] = '3.0'
       end
   end
end

