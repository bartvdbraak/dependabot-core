# frozen_string_literal: true

module FileSelector
  private

  def arm_files
    dependency_files.select { |f| arm_file?(f.name) }
  end

  def arm_file?(file_name)
    file_name.end_with?(".bicep", ".json")
  end
end
