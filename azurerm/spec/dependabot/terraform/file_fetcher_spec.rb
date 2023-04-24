# frozen_string_literal: true

require "spec_helper"
require "dependabot/file_fetchers/azure/arm"

RSpec.describe Dependabot::FileFetchers::Azure::ARM do
  it_behaves_like "a dependency file fetcher"

  let(:source) do
    Dependabot::Source.new(
      provider: "github",
      repo: "gocardless/bump",
      directory: directory
    )
  end

  let(:file_fetcher_instance) do
    described_class.new(source: source, credentials: [], repo_contents_path: repo_contents_path)
  end

  let(:project_name) { "example-resource-group" }
  let(:directory) { "/" }
  let(:repo_contents_path) { build_tmp_repo(project_name) }

  after do
    FileUtils.rm_rf(repo_contents_path)
  end

  context "with .bicep files" do
    let(:project_name) { "bicep-files" }

    it "fetches the .bicep files" do
      expect(file_fetcher_instance.files.map(&:name)).
        to match_array(%w(main.bicep variables.bicep))
    end
  end

  context "with .json files" do
    let(:project_name) { "json-files" }

    it "fetches the .json files" do
      expect(file_fetcher_instance.files.map(&:name)).
        to match_array(%w(main.json variables.json))
    end
  end

  context "with a directory that doesn't exist" do
    let(:directory) { "/nonexistent" }

    it "raises a helpful error" do
      expect { file_fetcher_instance.files }.
        to raise_error(Dependabot::DependencyFileNotFound)
    end
  end
end
