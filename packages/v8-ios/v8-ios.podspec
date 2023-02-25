require "json"

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']
  s.license      = package['license']

  s.authors      = package['author']
  s.homepage     = package['homepage']
  s.platforms    = { :ios => "12.0" }

  s.source       = { :http => "https://registry.npmjs.org/v8-ios/-/v8-ios-#{s.version}.tgz" }

  s.vendored_framework   = 'v8.xcframework'
  s.source_files         = 'include/**/*.h'
  s.preserve_paths       = 'include'
  s.header_mappings_dir  = 'include'
end
