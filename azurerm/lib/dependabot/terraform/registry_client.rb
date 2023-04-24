# frozen_string_literal: true

require "dependabot/dependency"
require "dependabot/errors"
require "dependabot/registry_client"
require "dependabot/source"

module Dependabot
  module Azure
    # Azure::RegistryClient is a basic API client to interact with Azure Resource Manager:
    # https://docs.microsoft.com/en-us/rest/api/resources/resources
    class RegistryClient
      ARM_ARCHIVE_EXTENSIONS = %w(.zip .rar .7z .tar .tar.gz .tar.xz).freeze
      ARM_RESOURCE_PROVIDER_URL = "https://management.azure.com/providers/Microsoft.Compute?api-version=2022-03-01"
      ARM_PUBLIC_HOSTNAME = "management.azure.com"

      def initialize(hostname: ARM_PUBLIC_HOSTNAME, credentials: [])
        @hostname = hostname
        @tokens = credentials.each_with_object({}) do |item, memo|
          memo[item["host"]] = item["token"] if item["type"] == "arm_registry"
        end
      end

      # Fetch all the versions of an ARM Resource Provider
      #
      # @param provider_name [String] the name of the provider, i.e:
      # "Microsoft.Compute"
      # @return [Array<String>]
      # @raise [Dependabot::DependabotError] when the versions cannot be retrieved
      def all_provider_versions(provider_name:)
        response = http_get!(URI.parse(ARM_RESOURCE_PROVIDER_URL))

        JSON.parse(response.body).
          fetch("resourceTypes").
          find { |res| res["resourceType"] == provider_name }.
          fetch("apiVersions")
      rescue Excon::Error
        raise error("Could not fetch provider versions")
      end

      # Fetch the "source" for an ARM resource. We use the API to fetch
      # the source for a dependency, this typically points to a source code
      # repository, and then instantiate a Dependabot::Source object that we
      # can use to fetch Metadata about a specific version of the dependency.
      #
      # @param dependency [Dependabot::Dependency] the dependency who's source
      # we're attempting to find
      # @return [nil, Dependabot::Source]
      def source(dependency:)
        raw_source = dependency.requirements.first[:source][:url]
        type = dependency.requirements.first[:source][:type]
        case type
        when "azurerm_registry"
          source_url = get_proxied_source(raw_source)
          Source.from_url(source_url)
        when "azure_provider"
          base_url = "https://#{dependency.name.split('/')[0..-2].join('/')}"
          download_url = "#{base_url}/#{dependency.name.split('/')[-1]}?api-version=#{dependency.version}"
          response = http_get!(URI.parse(download_url))
          return nil unless response.status == 200

          source_url = JSON.parse(response.body)["properties"]["templateLink"]["uri"]
          Source.from_url(source_url)
        else
          raise "Unsupported ARM resource type: #{type}"
        end
      end

      private

      attr_reader :hostname

      def get_proxied_source(raw_source)
        return raw_source unless raw_source.start_with?("http")

        uri = URI.parse(raw_source.split(%r{(?<!:)//}).first)
        return raw_source if uri.path.end_with?(*ARM_ARCHIVE_EXTENSIONS)

        url = raw_source.split(%r{(?<!:)//}).first + "?terraform-get=1"
        host
