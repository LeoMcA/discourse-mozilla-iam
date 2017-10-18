require_relative '../iam_helper'
require_relative '../support/serialize_mozilla_iam_shared_examples'

describe UserSerializer do
  include_examples "serialize mozilla_iam custom_fields"
end
