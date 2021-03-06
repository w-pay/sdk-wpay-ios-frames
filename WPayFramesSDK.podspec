#
# Be sure to run `pod lib lint WPayFramesSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.cocoapods_version = ">= 1.10"

  s.name             = "WPayFramesSDK"
  s.version          = "0.4.1"
  s.summary          = "iOS wrapper around WPay Frames JS SDK."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
iOS wrapper around WPay Frames JS SDK.
                       DESC

  s.homepage         = "https://github.com/w-pay/sdk-wpay-ios-frames"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = { :type => "WPAY", :file => "LICENSE" }
  s.author           = { "Kieran Simpson" => "kieran@redcrew.com.au" }
  s.source           = { :git => "https://github.com/w-pay/sdk-wpay-ios-frames.git", :branch => "main" }
  # s.social_media_url = "https://twitter.com/<TWITTER_USERNAME>"

  s.platform = :ios, "11.0"

  s.source_files = "WPayFramesSDK/**/*.{swift}"

  s.resource_bundles = {
    "WPayFramesSDK" => [ "WPayFramesSDK/Assets/*" ]
  }

  # s.frameworks = "UIKit", "MapKit"
  # s.dependency "AFNetworking", "~> 2.3"
end
