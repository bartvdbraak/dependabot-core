# frozen_string_literal: true

# These all need to be required so the various classes can be registered in a
# lookup table of package manager names to concrete classes.
# require "dependabot/arm/file_fetcher"
# require "dependabot/arm/file_parser"
# require "dependabot/arm/update_checker"
# require "dependabot/arm/file_updater"
# require "dependabot/arm/metadata_finder"
# require "dependabot/arm/requirement"
# require "dependabot/arm/version"

require "dependabot/pull_request_creator/labeler"
Dependabot::PullRequestCreator::Labeler.
  register_label_details("arm", name: "arm", colour: "3278D0")

require "dependabot/dependency"
Dependabot::Dependency.
  register_production_check("arm", ->(_) { true })

require "dependabot/utils"
Dependabot::Utils.register_always_clone("arm")

Dependabot::Dependency.
  register_display_name_builder(
    "arm",
    lambda { |name|
      # Only modify the name if it a git source dependency
      return name unless name.include? "::"

      name.split("::").first + "::" + name.split("::")[2].split("/").last.split("(").first
    }
  )
