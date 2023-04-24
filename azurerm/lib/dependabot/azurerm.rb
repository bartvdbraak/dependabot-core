# frozen_string_literal: true

# These all need to be required so the various classes can be registered in a
# lookup table of package manager names to concrete classes.
require "dependabot/azurerm/file_fetcher"
require "dependabot/azurerm/file_parser"
require "dependabot/azurerm/update_checker"
require "dependabot/azurerm/file_updater"
require "dependabot/azurerm/metadata_finder"
require "dependabot/azurerm/requirement"
require "dependabot/azurerm/version"

require "dependabot/pull_request_creator/labeler"
Dependabot::PullRequestCreator::Labeler.
  register_label_details("azurerm", name: "azurerm", colour: "008AD7")

require "dependabot/dependency"
Dependabot::Dependency.
  register_production_check("azurerm", ->(_) { true })

require "dependabot/utils"
Dependabot::Utils.register_always_clone("azurerm")

Dependabot::Dependency.
  register_display_name_builder(
    "azurerm",
    lambda { |name|
      # Only modify the name if it a git source dependency
      return name unless name.include? "::"

      name.split("::").first + "::" + name.split("::")[2].split("/").last.split("(").first
    }
  )
