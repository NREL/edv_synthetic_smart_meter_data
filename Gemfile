source 'http://rubygems.org'
ruby '~>2.5'

allow_local = true
allow_local_bsync = true

gem 'geocoder', '1.6.4'
gem 'multipart-post', '2.1.1'
gem 'rake', '~>13.0.1'
gem 'rexml', '3.2.4'
gem 'rspec', '~>3.10'


########################################################################
########################################################################

if allow_local && File.exist?('../OpenStudio-extension-gem')
  puts "<<<<<<------DEBUGGING------>>>>>> using local OS extension gem" 
  gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
else
  gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', tag: 'v0.2.6'
end

########################################################################
########################################################################

if allow_local && File.exist?('../openstudio-model-articulation-gem')
  puts "<<<<<<------DEBUGGING------>>>>>> using local OS model articulation gem" 
  gem 'openstudio-model-articulation', path: '../openstudio-model-articulation-gem'
else
  gem 'openstudio-model-articulation', github: 'NREL/openstudio-model-articulation-gem', tag: 'v0.2.1'
end

########################################################################
########################################################################

# Temporary
=begin
if allow_local && File.exist?('../openstudio-common-measures-gem')
  gem 'openstudio-common-measures', path: '../openstudio-common-measures-gem'
else
  gem 'openstudio-common-measures', github: 'NREL/openstudio-common-measures-gem', tag: 'v0.2.1'
end
=end

########################################################################
########################################################################

if allow_local && File.exist?('../openstudio-standards')
  puts "<<<<<<------DEBUGGING------>>>>>> using local OS standards gem"
  gem 'openstudio-standards', path: '../openstudio-standards'
else
  gem 'openstudio-standards', github: 'NREL/openstudio-standards', tag: 'v0.2.14'
end

########################################################################
########################################################################

if allow_local_bsync && File.exist?('../BuildingSync-gem')
  puts "<<<<<<------DEBUGGING------>>>>>> using local BSync gem"
  gem 'buildingsync', path: '../BuildingSync-gem'
else
  # gem 'buildingsync', github: 'BuildingSync/BuildingSync-gem', tag: 'v0.2.1'
  gem 'buildingsync', github: 'BuildingSync/BuildingSync-gem', branch: 'fix/134_load_system_error'
end

########################################################################
########################################################################

if allow_local && File.exist?('../openstudio-occupant-variability-gem')
  puts "<<<<<<------DEBUGGING------>>>>>> using local occ var gem"
  gem 'openstudio-occupant-variability', path: '../openstudio-occupant-variability-gem'
else
  gem 'openstudio-occupant-variability', github: 'LBNL-ETA/openstudio-occupant-variability-gem', branch: 'ruby_upgrade'
end

########################################################################
########################################################################

if allow_local && File.exist?('../openstudio-variability-gem')
  puts "<<<<<<------DEBUGGING------>>>>>> using local var gem"
  gem 'openstudio-variability', path: '../openstudio-variability-gem'
else
  gem 'openstudio-variability', github: 'LBNL-ETA/openstudio-variability-gem', branch: 'ruby_upgrade'
end

########################################################################
########################################################################

# openstudio-bldgs-calibration-gem requires openstudio-extension-gem v0.2.6
# temporary disable for repo release.
# gem 'openstudio-bldgs-calibration', path: '../openstudio-bldgs-calibration-gem'

########################################################################
########################################################################

# simplecov has an unneccesary dependency on native json gem, use fork that does not require this
# gem 'simplecov', github: 'NREL/simplecov'
gem 'simplecov', require: false, group: :test
