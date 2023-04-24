# frozen_string_literal: true

require "spec_helper"
require "dependabot/azure"

RSpec.describe Dependabot::Azure do
  describe "Dependency#display_name" do
    subject(:display_name) do
      Dependabot::Dependency.new(**dependency_args).display_name
    end

    let(:dependency_args) do
      { name: name, requirements: [], package_manager: "azurerm" }
    end
    
    context "registry source" do
      let(:name) { "Microsoft.Compute" }
    
      it { is_expected.to eq("Microsoft.Compute") }
    end
    
  end
end
