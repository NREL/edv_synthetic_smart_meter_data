source 'http://rubygems.org'
ruby '~>2.5'

allow_local = false
allow_local_bsync = false

gem 'rake', '13.0.1'
gem 'rexml', '3.2.4'

gem 'rspec', '~> 3.10'
gem 'multipart-post', '2.1.1'
gem 'geocoder', '1.6.4'

########################################################################
########################################################################

if allow_local && File.exist?('../OpenStudio-extension-gem')
  gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
else
  # edv Ruby-2.2.4 compatible version:
  # gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', :tag => 'v0.1.6'

  gem 'openstudio-extension'
end

########################################################################
########################################################################

if allow_local && File.exist?('../openstudio-model-articulation-gem')
  gem 'openstudio-model-articulation', path: '../openstudio-model-articulation-gem'
else
  # gem 'openstudio-model-articulation', github: 'NREL/openstudio-model-articulation-gem', branch: 'DA'

  gem 'openstudio-model-articulation'
end

########################################################################
########################################################################

if allow_local && File.exist?('../openstudio-common-measures-gem')
  gem 'openstudio-common-measures', path: '../openstudio-common-measures-gem'
else
  # edv ruby-2.2.4 compatible version:
  # gem 'openstudio-common-measures', github: 'NREL/openstudio-common-measures-gem', :tag => 'v0.1.1'

  gem 'openstudio-common-measures'
end

########################################################################
########################################################################

if allow_local && File.exist?('../openstudio-standards-gem')
  gem 'openstudio-standards', path: '../openstudio-standards'
else
  # edv ruby-2.2.4 compatible version:
  # gem 'openstudio-standards', github: 'NREL/openstudio-standards', :tag => 'v0.2.11'

  gem 'openstudio-standards'
end

########################################################################
########################################################################

if allow_local_bsync && File.exists?('../BuildingSync-gem')
  gem 'buildingsync', path: '../BuildingSync-gem'
else
  # edv ruby-2.2.4 compatible version:
  # gem 'buildingsync', github: 'BuildingSync/BuildingSync-gem', branch: 'DA_EDV_testing'

  gem 'buildingsync', github: 'BuildingSync/BuildingSync-gem', branch: 'develop'
end
=begin
########################################################################
########################################################################

if allow_local && File.exists?('../openstudio-occupant-variability-gem')
  gem 'openstudio-occupant-variability', path: '../openstudio-occupant-variability-gem'
else
  gem 'openstudio-occupant-variability', github: 'LBNL-ETA/openstudio-occupant-variability-gem', branch: 'master'
end

########################################################################
########################################################################

if allow_local && File.exists?('../openstudio-variability-gem')
  gem 'openstudio-variability', path: '../openstudio-variability-gem'
else
  gem 'openstudio-variability', github: 'LBNL-ETA/openstudio-variability-gem', branch: 'master'
end
=end
########################################################################
########################################################################

# simplecov has an unneccesary dependency on native json gem, use fork that does not require this
# gem 'simplecov', github: 'NREL/simplecov'
gem 'simplecov', require: false, group: :test
