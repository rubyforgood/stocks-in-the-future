# frozen_string_literal: true

require "test_helper"

# Verifies that image_processing/ruby-vips can generate ActiveStorage variants.
# This is the path used by app/views/active_storage/blobs/_blob.html.erb to
# render images embedded in rich text (e.g. Announcement content).
class ActiveStorageImageProcessingTest < ActiveSupport::TestCase
  test "generates an image variant via ruby-vips" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("sample_image.png").open,
      filename: "sample_image.png",
      content_type: "image/png"
    )

    assert blob.representable?

    variant = blob.representation(resize_to_limit: [100, 100]).processed
    assert_equal "image/png", variant.image.blob.content_type
  end
end
