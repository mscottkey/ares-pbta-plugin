#!/bin/bash

echo "Reorganizing project into an AresMUSH plugin standalone repository..."

# 1. Create target directories
mkdir -p plugin/commands
mkdir -p plugin/models
mkdir -p plugin/web
mkdir -p plugin/locales
mkdir -p game/config
mkdir -p webportal/templates
mkdir -p webportal/routes
mkdir -p custom_files

# 2. Move backend Ruby plugin files
mv aresmush/plugins/heroesguild/heroesguild.rb plugin/
mv aresmush/plugins/heroesguild/engine.rb plugin/
mv aresmush/plugins/heroesguild/helpers.rb plugin/

mv aresmush/plugins/heroesguild/commands/* plugin/commands/ 2>/dev/null
mv aresmush/plugins/heroesguild/models/* plugin/models/ 2>/dev/null
mv aresmush/plugins/heroesguild/web/* plugin/web/ 2>/dev/null

# Locales (Ares plugins usually look for locales/en.yml)
mv aresmush/plugins/heroesguild/locale/en.yml plugin/locales/en.yml 2>/dev/null

# 3. Move Game Configurations
mv aresmush/game/config/heroesguild.yml game/config/
mv aresmush/game/config/chargen.yml game/config/heroesguild_chargen.yml 2>/dev/null

# 4. Move Custom Review / Field Plugins to custom_files
mv aresmush/plugins/chargen/custom_app_review.rb custom_files/ 2>/dev/null
mv aresmush/plugins/profile/custom_char_fields.rb custom_files/ 2>/dev/null

# 5. Move webportal files.
# Components and standard templates
mv ares-webportal/app/templates/heroesguild-jobboard.hbs webportal/templates/ 2>/dev/null
mv ares-webportal/app/routes/heroesguild-jobboard.js webportal/routes/ 2>/dev/null

# Move Ember custom hooks to custom_files
mv ares-webportal/app/templates/components/chargen-custom-tabs.hbs custom_files/ 2>/dev/null
mv ares-webportal/app/templates/components/chargen-custom.hbs custom_files/ 2>/dev/null
mv ares-webportal/app/components/chargen-custom.js custom_files/ 2>/dev/null

mv ares-webportal/app/templates/components/profile-custom-tabs.hbs custom_files/ 2>/dev/null
mv ares-webportal/app/templates/components/profile-custom.hbs custom_files/ 2>/dev/null
mv ares-webportal/app/components/profile-custom.js custom_files/ 2>/dev/null

mv ares-webportal/app/custom-routes.js custom_files/ 2>/dev/null

# 6. Cleanup empty directories
rm -rf aresmush/
rm -rf ares-webportal/

echo "Reorganization complete! Your repo now matches the standalone plugin folder structure."
