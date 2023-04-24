# frozen_string_literal: true

require "dependabot/file_updaters"
require "dependabot/file_updaters/base"
require "dependabot/errors"
require "dependabot/shared_helpers"

module Dependabot
  module ARM
    class FileUpdater < Dependabot::FileUpdaters::Base
      def self.updated_files_regex
        [/\.json$/, /\.bicep$/]
      end

      def updated_dependency_files
        updated_files = []

        [*json_files, *bicep_files].each do |file|
          next unless file_changed?(file)

          updated_content = updated_arm_file_content(file)

          raise "Content didn't change!" if updated_content == file.content

          updated_file = updated_file(file: file, content: updated_content)

          updated_files << updated_file unless updated_files.include?(updated_file)
        end

        raise "No files changed!" if updated_files.none?

        updated_files
      end

      private

      def updated_arm_file_content(file)
        content = file.content.dup

        reqs = dependency.requirements.zip(dependency.previous_requirements).
               reject { |new_req, old_req| new_req == old_req }

        # Loop through each changed requirement and update the files
        reqs.each do |new_req, old_req|
          raise "Bad req match" unless new_req[:file] == old_req[:file]
          next unless new_req.fetch(:file) == file.name

          case new_req[:source][:type]
          when "registry"
            update_registry_declaration(new_req, old_req, content)
          else
            raise "Don't know how to update a #{new_req[:source][:type]} " \
                  "declaration!"
          end
        end

        content
      end

      def update_registry_declaration(new_req, old_req, updated_content)
        regex = registry_declaration_regex

        updated_content.gsub!(regex) do |regex_match|
          regex_match.sub(/^\s*\"#{Regexp.escape(old_req[:name])}\"\s*:\s*\"#{Regexp.escape(old_req[:requirement])}\"/) do |req_line_match|
            req_line_match.sub(Regexp.escape(old_req[:requirement]), new_req[:requirement])
          end
        end
      end
    end
  end
end
