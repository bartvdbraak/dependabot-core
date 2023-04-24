# frozen_string_literal: true

require "dependabot/file_fetchers"
require "dependabot/file_fetchers/base"

module Dependabot
  module AzureResourceManager
    class FileFetcher < Dependabot::FileFetchers::Base
      def self.required_files_in?(filenames)
        filenames.any? { |f| f.end_with?(".json", ".bicep") }
      end

      def self.required_files_message
        "Repo must contain an Azure Resource Manager template file."
      end

      private

      def fetch_files
        fetched_files = []
        fetched_files += arm_template_files

        return fetched_files if fetched_files.any?

        raise(
          Dependabot::DependencyFileNotFound,
          File.join(directory, "<anything>.json or <anything>.bicep")
        )
      end

      def arm_template_files
        @arm_template_files ||=
          repo_contents(raise_errors: false).
          select { |f| f.type == "file" && f.name.end_with?(".json", ".bicep") }.
          map { |f| fetch_file_from_host(f.name) }
      end
    end
  end
end

Dependabot::FileFetchers.
  register("azure_resource_manager", Dependabot::AzureResourceManager::FileFetcher)
