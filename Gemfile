source 'http://rubygems.org'
ruby '~>2.2'

allow_local = false
allow_local_bsync = false

gem 'rake', '12.3.1'
gem 'rexml', '3.2.2'

gem 'rspec', '~> 3.8'
gem 'multipart-post', '2.1.1'
gem 'geocoder'

if allow_local && File.exist?('../OpenStudio-extension-gem')
  gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
else
  # gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
  # Last edv compatible OS-ext-gem version:
  gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', :tag => 'v0.1.6'
end

if allow_local && File.exist?('../openstudio-model-articulation-gem')
  # gem 'openstudio-model-articulation', github: 'NREL/openstudio-model-articulation-gem', branch: 'develop'
  gem 'openstudio-model-articulation', path: '../openstudio-model-articulation-gem'
else
  gem 'openstudio-model-articulation', github: 'NREL/openstudio-model-articulation-gem', branch: 'DA'
end

if allow_local && File.exist?('../openstudio-common-measures-gem')
  # gem 'openstudio-model-articulation', github: 'NREL/openstudio-common-measures-gem', branch: 'develop'
  gem 'openstudio-common-measures', path: '../openstudio-common-measures-gem'
else
  gem 'openstudio-common-measures', github: 'NREL/openstudio-common-measures-gem', :tag => 'v0.1.1'
end

if allow_local && File.exist?('../openstudio-standards-gem')
  gem 'openstudio-standards', '>=0.2.9'
  # gem 'openstudio-standards', path: '../openstudio-standards'
else
  gem 'openstudio-standards', '>=0.2.9'
end

if allow_local_bsync && File.exists?('../BuildingSync-gem')
  # gem 'buildingsync', github: 'BuildingSync/BuildingSync-gem', branch: 'DA'
  gem 'buildingsync', path: '../BuildingSync-gem'
else
  gem 'buildingsync', github: 'BuildingSync/BuildingSync-gem', branch: 'DA_EDV_testing'
end

if allow_local && File.exists?('../openstudio-occupant-variability-gem')
  # gem 'openstudio-occupant-variability', github: 'tsbyq/openstudio-occupant-variability-gem', branch: 'master'
  gem 'openstudio-occupant-variability', path: '../openstudio-occupant-variability-gem'
else
  #gem 'openstudio-occupant-variability', github: 'tsbyq/openstudio-occupant-variability-gem', branch: 'master'
  gem 'openstudio-occupant-variability', github: 'LBNL-ETA/openstudio-occupant-variability-gem', branch: 'master'
end

# simplecov has an unneccesary dependency on native json gem, use fork that does not require this
gem 'simplecov', github: 'NREL/simplecov'