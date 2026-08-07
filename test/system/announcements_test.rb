# frozen_string_literal: true

require "application_system_test_case"

class AnnouncementsTest < ApplicationSystemTestCase
  setup do
    @announcement = Announcement.create!(
      title: "Test Announcement",
      content: "Test content"
    )
  end

  test "students can view announcements" do
    student = create(:student)
    sign_in student

    visit announcement_url(@announcement)
    assert_text @announcement.title
  end

  test "teachers can view announcements" do
    teacher = create(:teacher)
    sign_in teacher

    visit announcement_url(@announcement)
    assert_text @announcement.title
  end

  test "should display announcement content properly" do
    student = create(:student)
    sign_in student

    visit announcement_url(@announcement)
    assert_text @announcement.title
    # ActionText content should be displayed
    assert_selector ".trix-content"
  end

  # One icon per card. The announcements card carried `megaphone` twice: 16px in a 32x32 blue-50 tile in
  # the header, and 20px bare slate-500 in the body's empty state - bigger, a different colour, no tile,
  # so the pair read as unrelated. Reported that way.
  #
  # An icon in an empty state is a focal point for a region where the emptiness *is* the screen. Inside a
  # titled card the header already has one, so a second competes with it 40px below. The compact variant
  # is text.
  test "the announcements card shows one icon, in its header" do
    Announcement.destroy_all
    teacher = create(:teacher)
    sign_in teacher

    visit root_path

    icons = page.evaluate_script(<<~JS)
      (function () {
        const heading = Array.from(document.querySelectorAll("h2, h3, p"))
          .find(function (e) { return e.textContent.trim() === "Announcements"; });
        const card = heading.closest(".tw-card");
        return Array.from(card.querySelectorAll("svg")).map(function (s) {
          const box = s.getBoundingClientRect();
          return { size: Math.round(box.width), tiled: getComputedStyle(s.parentElement).backgroundColor };
        });
      })()
    JS

    assert_equal 1, icons.size,
                 "the card has #{icons.size} icons: #{icons.inspect} - the header identifies it, and a " \
                 "second glyph in the body is a competing focal point"
    assert_equal 16, icons.first["size"]
  end

  # An empty state occupies the same box as the content it replaces, so the text does not move when the
  # content arrives. The icon plus its gap indented the copy 32px past the card's content edge.
  test "the empty announcement text sits where a real announcement's title sits" do
    Announcement.destroy_all
    teacher = create(:teacher)
    sign_in teacher

    read_left = <<~JS
      (function () {
        const heading = Array.from(document.querySelectorAll("h2, h3, p"))
          .find(function (e) { return e.textContent.trim() === "Announcements"; });
        const card = heading.closest(".tw-card");
        const body = Array.from(card.querySelectorAll("p, h3"))
          .filter(function (e) { return e !== heading && e.textContent.trim().length > 0; })[0];
        return Math.round(body.getBoundingClientRect().left);
      })()
    JS

    visit root_path
    empty_left = page.evaluate_script(read_left)

    Announcement.create!(title: "Half day on Friday", content: "School closes at noon.")
    visit root_path
    filled_left = page.evaluate_script(read_left)

    assert_equal filled_left, empty_left,
                 "the empty state starts at #{empty_left}px and the announcement at #{filled_left}px, " \
                 "so the text moves when an announcement arrives"
  end
end
