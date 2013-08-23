require 'yaml'
require 'i18n'
require 'crichton'
require 'lint/resource_descriptor_validator'

module Lint
  # check for a variety of errors and other syntactical issues in a resource descriptor file's contents
  def self.validate(filename)

    @rdv = ResourceDescriptorValidator.new

    # the resource descriptor validator does all the heavy lifting, calling validator subclasses
    @rdv.validate(filename)

    # once all validations done, output the results
    @rdv.report_lint_issues
  end

end

