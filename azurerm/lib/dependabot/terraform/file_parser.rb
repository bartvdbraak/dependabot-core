# frozen_string_literal: true

require "dependabot/dependency"
require "dependabot/file_parsers"
require "dependabot/file_parsers/base"
require "dependabot/errors"

module Dependabot
  module ARM
    class FileParser < Dependabot::FileParsers::Base
      def parse
        dependencies = []

        # Traverse each ARM file and get its dependencies
        arm_files.each do |file|
          content = file.content
          dependencies += get_arm_dependencies(content, file.name)
        end

        dependencies.sort_by(&:name)
      end

      private

      def get_arm_dependencies(content, file_name)
        dependencies = []

        json = JSON.parse(content)

        # Traverse each ARM resource and get its dependencies
        resources = json["resources"] || []
        resources.each do |resource|
          type_parts = resource["type"].split("/")
          provider = type_parts.first.downcase
          name = type_parts.last.downcase

          # For now, we assume the version is not specified
          version = nil

          # If the source of the provider is specified
          if resource["properties"] && resource["properties"]["source"]
            source = resource["properties"]["source"].downcase
            source_parts = source.split("/")
            if source_parts.length > 1
              provider = source_parts[-2].downcase
              name = source_parts[-1].downcase
            end
          end

          # Create a new dependency object
          dependencies << Dependency.new(
            name: "#{provider}/#{name}",
            version: version,
            package_manager: "azure",
            requirements: [
              {
                requirement: nil,
                groups: [],
                file: file_name,
                source: { type: "registry", name: provider, source: name }
              }
            ]
          )
        end

        dependencies
      end

      def arm_files
        @arm_files ||=
          begin
            # For now, we support only Bicep and JSON files
            files = []
            files += repo_contents("**/*.bicep")
            files += repo_contents("**/*.json")
            files
          end
      end
    end
  end
end
