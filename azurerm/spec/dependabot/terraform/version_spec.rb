# frozen_string_literal: true

require "spec_helper"
require "dependabot/azurerm/version"

RSpec.describe Dependabot::AzureRM::Version do
  subject(:version) { described_class.new(version_string) }
  let(:version_string) { "1.0.0" }

  describe "#to_s" do
    subject { version.to_s }

    context "with a non-prerelease" do
      let(:version_string) { "1.0.0" }
      it { is_expected.to eq "1.0.0" }
    end

    context "with a normal prerelease" do
      let(:version_string) { "1.0.0-preview1" }
      it { is_expected.to eq "1.0.0-preview1" }
    end

    context "with an AzureRM-style prerelease" do
      let(:version_string) { "1.0.0-preview.1" }
      it { is_expected.to eq "1.0.0-preview.1" }
    end
  end
end
