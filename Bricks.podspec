Pod::Spec.new do |spec|
  spec.name             = 'Bricks'
  spec.version          = '1.0.0'
  spec.license          = { :type => 'MIT' }
  spec.homepage         = 'https://github.com/aniramskaya/bricks'
  spec.authors          = { 'Marina Chemezova' => 'aniramskaya@gmail.com' }
  spec.summary          = 'Building blocks for data loading services.'
  spec.source           = { :git => 'https://github.com/aniramskaya/bricks.git', :tag => 'v1.0.0' }
  spec.source_files     = 'bricks/source/*.swift'
end