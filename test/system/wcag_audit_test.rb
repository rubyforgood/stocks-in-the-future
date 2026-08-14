# frozen_string_literal: true

require "application_system_test_case"

# WCAG 2.2 AA, measured on the rendered page across fifteen screens and all three roles.
#
# What it checks, and why each is measured rather than grepped: 1.4.3 contrast, 1.1.1 images and icon-only
# controls, 1.3.1 labels, header cells and heading order, 2.4.2 page title, 2.5.8 target size with the
# spec's inline and spacing exceptions, and 4.1.2 accessible names.
#
# **Contrast is measured by painting a pixel.** `getComputedStyle` returns `oklch()` in this browser, and
# reading those three numbers as RGB reports slate-600 on slate-50 as 1.05:1 - which this repo has already
# once reported as five contrast failures that did not exist. The first version of *this* file made the
# mirror-image mistake: it painted each colour over opaque black, which destroyed the alpha, resolved every
# transparent background to black, and reported slate-900 body text at 1.18:1.
#
# So there is a test below that injects one violation of every kind and asserts the audit catches it. A
# clean report from a broken instrument is worse than no report.
class WcagAuditTest < ApplicationSystemTestCase
  AUDIT = <<~JS
    (function () {
      // Contrast by painting a pixel and reading it back. getComputedStyle returns oklch() in this
      // browser, and parsing those three numbers as if they were RGB reports slate-600 on slate-50 as
      // 1.05:1 - which is how five contrast failures were once reported that did not exist.
      const cv = document.createElement("canvas");
      cv.width = cv.height = 1;
      const cx = cv.getContext("2d", { willReadFrequently: true });
      const cache = {};
      function rgb(colour) {
        if (cache[colour]) return cache[colour];
        // No underlay. Painting the colour over opaque black makes every read-back alpha 1, so a
        // transparent background reads as black - which reported slate-900 body text at 1.18:1.
        cx.clearRect(0, 0, 1, 1);
        cx.fillStyle = "rgba(0,0,0,0)";
        cx.fillStyle = colour;
        cx.fillRect(0, 0, 1, 1);
        const d = cx.getImageData(0, 0, 1, 1).data;
        return (cache[colour] = [d[0], d[1], d[2], d[3] / 255]);
      }
      function lum(c) {
        const f = c.slice(0, 3).map(function (v) {
          v /= 255;
          return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        });
        return 0.2126 * f[0] + 0.7152 * f[1] + 0.0722 * f[2];
      }
      function ratio(fg, bg) {
        const a = lum(fg), b = lum(bg);
        return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
      }
      function backdrop(el) {
        let n = el;
        while (n && n !== document.documentElement) {
          const c = rgb(getComputedStyle(n).backgroundColor);
          if (c[3] > 0.95) return c;
          n = n.parentElement;
        }
        return [255, 255, 255, 1];
      }
      function name(el) {
        const aria = el.getAttribute("aria-label");
        if (aria && aria.trim()) return aria.trim();
        const by = el.getAttribute("aria-labelledby");
        if (by) {
          const t = by.split(/\\s+/).map(function (id) {
            const n = document.getElementById(id);
            return n ? n.textContent : "";
          }).join(" ").trim();
          if (t) return t;
        }
        if (el.labels && el.labels.length) return el.labels[0].textContent.trim();
        const title = el.getAttribute("title");
        if (title && title.trim()) return title.trim();
        const alt = el.getAttribute("alt");
        if (alt !== null && alt.trim()) return alt.trim();
        if (el.value && el.type === "submit") return el.value.trim();
        const text = (el.innerText || "").trim();
        if (text) return text;
        // An anchor wrapping an image takes the image's alt - the site logo is exactly this, and reading
        // `alt` on the anchor itself reported it as unnamed.
        const img = el.querySelector("img[alt]:not([alt=''])");
        if (img) return img.getAttribute("alt").trim();
        const svgTitle = el.querySelector("svg title");
        return svgTitle ? svgTitle.textContent.trim() : "";
      }
      function onScreen(el) {
        return el.getClientRects().length > 0 && el.checkVisibility && el.checkVisibility();
      }

      const out = { contrast: [], noName: [], noAlt: [], smallTarget: [], headings: [], thNoScope: 0,
                    unlabelledInput: [], darkVariant: [] };

      // 1.4.3 - text against its own painted backdrop.
      document.querySelectorAll("main *, nav *, header *, footer *").forEach(function (el) {
        if (!onScreen(el)) return;
        const own = Array.from(el.childNodes).some(function (n) {
          return n.nodeType === 3 && n.textContent.trim().length > 1;
        });
        if (!own) return;
        const cs = getComputedStyle(el);
        const size = parseFloat(cs.fontSize);
        const bold = parseInt(cs.fontWeight, 10) >= 700;
        const large = size >= 24 || (size >= 18.66 && bold);
        const r = ratio(rgb(cs.color), backdrop(el));
        if (r < (large ? 3 : 4.5)) {
          out.contrast.push({ text: el.innerText.trim().slice(0, 34), size: Math.round(size),
                              ratio: Math.round(r * 100) / 100, cls: (el.className || "").toString().slice(0, 40) });
        }
      });

      // 4.1.2 / 1.1.1 - every interactive thing needs a name; 2.5.8 - and 24x24 of target.
      document.querySelectorAll("a, button, input, select, textarea, [role=button]").forEach(function (el) {
        if (!onScreen(el)) return;
        if (el.type === "hidden") return;
        if (!name(el)) out.noName.push(el.tagName.toLowerCase() + "." + (el.className || "").toString().slice(0, 40));
        const b = el.getBoundingClientRect();
        if (b.width >= 24 && b.height >= 24) return;
        // **Inline**: a link whose size is set by the line-height of the text around it is exempt by name
        // in 2.5.8. That covers body links and the breadcrumb trail.
        const cs2 = getComputedStyle(el);
        if (el.tagName === "A" && cs2.display.indexOf("inline") === 0) return;
        // A checkbox or radio with a `for` label is targeted through the label too, so measure the pair.
        let box = b;
        if (el.labels && el.labels[0]) {
          const lb = el.labels[0].getBoundingClientRect();
          box = { width: Math.max(b.width, lb.width), height: Math.max(b.height, lb.height),
                  left: Math.min(b.left, lb.left), top: Math.min(b.top, lb.top) };
        }
        if (box.width >= 24 && box.height >= 24) return;
        // **Spacing**: exempt if a 24px circle centred on the target reaches no other target.
        const cx0 = box.left + box.width / 2, cy0 = box.top + box.height / 2;
        const crowded = Array.from(document.querySelectorAll("a, button, input, select, [role=button]"))
          .some(function (o) {
            if (o === el || !onScreen(o)) return false;
            const ob = o.getBoundingClientRect();
            const dx = Math.max(ob.left - cx0, 0, cx0 - ob.right);
            const dy = Math.max(ob.top - cy0, 0, cy0 - ob.bottom);
            return Math.sqrt(dx * dx + dy * dy) < 12;
          });
        if (!crowded) return;
        out.smallTarget.push({ el: el.tagName.toLowerCase(), name: name(el).slice(0, 26),
                               w: Math.round(box.width), h: Math.round(box.height) });
      });

      document.querySelectorAll("img").forEach(function (el) {
        if (el.getAttribute("alt") === null) out.noAlt.push(el.getAttribute("src") || "");
      });

      // 1.3.1 - heading order, and a header cell that names no direction.
      let last = 0;
      document.querySelectorAll("h1, h2, h3, h4, h5, h6").forEach(function (h) {
        const lvl = parseInt(h.tagName[1], 10);
        if (last && lvl > last + 1) out.headings.push("h" + last + " -> h" + lvl + ": " + h.innerText.trim().slice(0, 30));
        last = lvl;
      });
      out.h1 = document.querySelectorAll("main h1, h1").length;
      document.querySelectorAll("th").forEach(function (th) { if (!th.getAttribute("scope")) out.thNoScope++; });
      document.querySelectorAll("input, select, textarea").forEach(function (el) {
        if (el.type === "hidden" || !onScreen(el)) return;
        if (!name(el)) out.unlabelledInput.push(el.name || el.id);
      });

      // 1.4.11 Non-text contrast: a control's boundary must reach 3:1 against what is next to it.
      out.borders = [];
      document.querySelectorAll("input, select, textarea, button, .tw-btn-secondary, .tw-btn-danger-outline, .tw-switch")
              .forEach(function (el) {
        if (el.type === "hidden" || !onScreen(el)) return;
        const cs = getComputedStyle(el);
        if (parseFloat(cs.borderTopWidth) === 0) return;
        // A filled control is identified by its fill, so its border is not carrying 1.4.11. Only a control
        // whose inside matches the page around it depends on its boundary to be seen at all.
        const around = backdrop(el.parentElement || el);
        const own = rgb(cs.backgroundColor);
        if (own[3] > 0.95 && ratio(own, around) >= 3) return;
        const r = ratio(rgb(cs.borderTopColor), around);
        if (r < 3) {
          out.borders.push({ el: el.tagName.toLowerCase() + (el.type ? "[" + el.type + "]" : ""),
                             colour: cs.borderTopColor, ratio: Math.round(r * 100) / 100 });
        }
      });

      // 1.3.5 Identify input purpose: a field collecting the user's own data names its purpose.
      out.noAutocomplete = [];
      const purposes = { name: "name", username: "username", email: "email", password: "password" };
      document.querySelectorAll("input").forEach(function (el) {
        if (el.type === "hidden" || !onScreen(el)) return;
        const n = (el.name || "").toLowerCase();
        const wants = Object.keys(purposes).some(function (k) { return n.indexOf(k) !== -1; });
        if (wants && !el.getAttribute("autocomplete")) out.noAutocomplete.push(el.name);
      });

      out.title = document.title;
      return out;
    })()
  JS

  # **1.4.11 is asserted now.** It was measured-but-not-asserted for one commit, because two tokens
  # `design.md` named by hand failed it: `.tw-input-primary`'s `border-slate-300` at **1.49:1** and
  # `.tw-btn-secondary`'s `border-slate-200` at **1.23:1**, each the only thing identifying its control on a
  # white card. Both are `slate-500` now - the first token that clears the bar, since `slate-400` measures
  # 2.63:1 and does not.
  #
  # A **filled** control is exempt and the check knows it: a primary button is identified by its own fill,
  # so its border carries nothing. Only a control whose inside matches the surface around it depends on its
  # boundary to be seen at all.
  def audit(label)
    r = page.evaluate_script(AUDIT)
    failures =
      r["contrast"].map { |c| "1.4.3 #{c['ratio']}:1 at #{c['size']}px - #{c['text'].inspect}" } +
      r["noName"].uniq.map { |n| "4.1.2 no accessible name - #{n}" } +
      r["noAlt"].map { |n| "1.1.1 img with no alt - #{n}" } +
      r["unlabelledInput"].map { |n| "1.3.1 input with no label - #{n}" } +
      r["headings"].map { |n| "1.3.1 heading level skipped - #{n}" }
    failures << "1.3.1 #{r['thNoScope']} th without scope" if r["thNoScope"].to_i.positive?
    failures << "2.4.2 no page title" if r["title"].to_s.strip.empty?
    failures << "1.3.1 #{r['h1']} h1 elements, expected 1" unless r["h1"] == 1
    r["smallTarget"].uniq.each { |t| failures << "2.5.8 #{t['w']}x#{t['h']} - #{t['name'].inspect}" }
    r["borders"].uniq.each { |b| failures << "1.4.11 #{b['el']} boundary #{b['ratio']}:1 - #{b['colour']}" }

    assert_empty failures, "#{label}:\n  " + failures.join("\n  ")
  end

  def fixtures_for_audit
    classroom = create(:classroom, :with_trading, name: "Period 3")
    student = create(:student, :with_portfolio, classroom:, name: "Robin Fields")
    student.reload
    stock = create(:stock, ticker: "AAPL")
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 2)
    Announcement.create!(title: "Notice", content: "Body")
    [classroom, student, stock]
  end

  # **Proving the instrument before believing it.** A clean report from a broken audit is worse than no
  # audit: the first version of this file measured contrast by painting the colour over opaque black, which
  # destroyed the alpha, resolved every transparent background to black and reported slate-900 body text at
  # 1.18:1. The inverse - a check that silently matches nothing and reports clean - is the same fault.
  test "the audit detects each violation it claims to check" do
    _classroom, student, = fixtures_for_audit
    sign_in(student)
    visit root_path

    page.execute_script(<<~JS)
      const m = document.querySelector("main");
      m.insertAdjacentHTML("afterbegin", [
        "<p style='color:#bbb;background:#fff'>Low contrast sentence here</p>",
        "<button></button>",
        "<img src='/x.png'>",
        "<input type='text' name='nameless'>",
        "<h1>One</h1><h4>Skipped two levels</h4>",
        "<table><tr><th>No scope</th></tr><tbody><tr><td>x</td></tr></tbody></table>",
        "<input type='text' name='faint' style='border:1px solid #f2f2f2;background:#fff' aria-label='Faint'>",
        "<div><a href='#' style='display:block;width:16px;height:16px'>a</a>",
        "<a href='#' style='display:block;width:16px;height:16px'>b</a></div>"
      ].join(""));
    JS

    r = page.evaluate_script(AUDIT)

    assert_operator r["contrast"].size, :>, 0, "1.4.3 did not catch #bbb on white"
    assert_operator r["noName"].size, :>, 0, "4.1.2 did not catch an empty button"
    assert_operator r["noAlt"].size, :>, 0, "1.1.1 did not catch an img with no alt"
    assert_operator r["unlabelledInput"].size, :>, 0, "1.3.1 did not catch an unlabelled input"
    assert_operator r["headings"].size, :>, 0, "1.3.1 did not catch h1 -> h4"
    assert_operator r["thNoScope"], :>, 0, "1.3.1 did not catch a th with no scope"
    assert_operator r["smallTarget"].size, :>, 0, "2.5.8 did not catch two crowded 16px targets"
    assert_operator r["borders"].size, :>, 0, "1.4.11 did not catch a control with a near-invisible boundary"
  end

  # **2.4.11 Focus Not Obscured (Minimum)**, new in WCAG 2.2 AA: a focused control must not be *entirely*
  # hidden by author-created content. This app has three pieces of it - the staging ribbon, the fixed header
  # under it, and `.tw-form-actions`, which becomes `sticky bottom-0` the moment an update form is dirty.
  #
  # It failed when this was written. With the form dirty, `admin/stocks/new`'s `employees` input landed at
  # 1213-1233 inside a save bar occupying 1161-1233: the browser scrolls a Tab target to the scrollport's
  # edge, which is behind the bar. `scroll-padding` on `:root` tells it where the usable scrollport really
  # starts and ends, which is why the fix is three lines of CSS rather than a scroll handler.
  test "no focused control is entirely hidden by the fixed chrome" do
    create(:student, classroom: create(:classroom, :with_trading))
    create(:stock)
    sign_in(create(:admin))

    [new_admin_stock_path, admin_students_path, new_admin_teacher_path].each do |path|
      visit path
      # Dirty the form, so the save row is sticky and in the way where there is one. `minimum: 0` because
      # an index page has no text field and `first` raises rather than returning nil.
      first("input[type=text]", minimum: 0)&.set("x")

      hidden = page.evaluate_script(<<~JS)
        (function () {
          const fixed = Array.from(document.querySelectorAll("body *")).filter(function (el) {
            const p = getComputedStyle(el).position;
            return (p === "fixed" || p === "sticky") && el.getClientRects().length > 0;
          });
          const out = [];
          Array.from(document.querySelectorAll("a[href], button, input, select, textarea"))
               .filter(function (el) { return el.getClientRects().length > 0 && !el.disabled; })
               .forEach(function (el) {
                 el.focus();
                 const b = el.getBoundingClientRect();
                 if (b.width === 0 || b.height === 0) return;
                 const covered = fixed.some(function (f) {
                   if (f.contains(el)) return false;
                   const r = f.getBoundingClientRect();
                   return r.left <= b.left && r.right >= b.right && r.top <= b.top && r.bottom >= b.bottom;
                 });
                 if (covered || b.bottom < 0 || b.top > window.innerHeight) {
                   out.push((el.name || el.innerText || el.tagName).toString().slice(0, 30));
                 }
               });
          return out;
        })()
      JS

      assert_empty hidden,
                   "#{path}: focusing #{hidden.inspect} left it entirely behind the fixed header or the " \
                   "sticky save row. 2.4.11 asks that a focused control not be completely hidden; " \
                   "`scroll-padding` on :root is what keeps the scrollport clear of both."
    end
  end

  # 1.4.12 Text Spacing: with these four overrides applied, no content or function may be lost. `.tw-card`
  # is `overflow-hidden`, so a clipped element never grows the page - a page-level check cannot see this,
  # which is why each element is compared to its own card.
  test "text spacing overrides lose no content" do
    classroom = create(:classroom, :with_trading, name: "Period 3")
    student = create(:student, :with_portfolio, classroom:, name: "Robin Fields")
    create(:stock)
    sign_in(create(:admin))

    { "student record" => admin_student_path(student.reload), "classroom" => classroom_path(classroom),
      "new stock" => new_admin_stock_path }.each do |name, path|
      visit path
      page.execute_script(<<~JS)
        const s = document.createElement("style");
        s.textContent = "* { line-height: 1.5 !important; letter-spacing: 0.12em !important;" +
                        " word-spacing: 0.16em !important; } p { margin-bottom: 2em !important; }";
        document.head.appendChild(s);
      JS

      clipped = page.evaluate_script(<<~JS)
        (function () {
          const out = [];
          document.querySelectorAll("main .tw-card").forEach(function (card) {
            const cb = card.getBoundingClientRect();
            card.querySelectorAll("*").forEach(function (el) {
              if (!el.getClientRects().length) return;
              const b = el.getBoundingClientRect();
              if (b.width === 0) return;
              const over = Math.round(Math.max(b.right - cb.right, cb.left - b.left));
              if (over > 1) out.push(over + "px: " + (el.innerText || "").trim().slice(0, 24));
            });
          });
          return out.slice(0, 5);
        })()
      JS

      assert_empty clipped, "#{name}: #{clipped.inspect} is clipped by its card at WCAG text spacing"
    end
  end

  # 2.4.2 Page Titled asks for a title that describes *this page*, and the machine half of this audit only
  # checked that one existed. Five app pages fell through to the layout's bare "Stocks in the Future": the
  # portfolio, the trading floor, transactions, classes and a grade book. So this asserts the title is
  # distinct from the site name and that no two pages share one - which is what "describes its topic" means
  # in practice.
  test "every page has a title of its own" do
    classroom = create(:classroom, :with_trading, name: "Period 3")
    student = create(:student, :with_portfolio, classroom:, name: "Robin Fields")
    stock = create(:stock, ticker: "AAPL")
    grade_book = create(:grade_book, classroom:)
    create(:school)
    sign_in(create(:admin, admin: true, classroom: nil))

    seen = {}
    { "portfolio" => user_portfolio_path(student.reload, student.portfolio),
      "trading floor" => stocks_path, "stock" => stock_path(stock), "transactions" => orders_path,
      "classes" => classrooms_path, "classroom" => classroom_path(classroom),
      "grade book" => classroom_grade_book_path(classroom, grade_book),
      "admin dashboard" => admin_root_path, "admin students" => admin_students_path,
      "admin student" => admin_student_path(student) }.each do |name, path|
      visit path
      title = page.title

      assert_not_equal "Stocks in the Future", title,
                       "#{name} falls through to the site name; 2.4.2 asks for a title describing the page"
      assert_nil seen[title], "#{name} and #{seen[title]} share the title #{title.inspect}"
      # "Admin | Admin | Stocks in the Future" - the dashboard's own crumb is already the section name.
      parts = title.split(" | ")
      assert_equal parts.uniq, parts, "#{name}: #{title.inspect} repeats a segment"
      seen[title] = name
    end
  end

  # 2.4.9 Link Purpose (Link Only) is **AAA**, and it is the one AAA criterion this app both fails and can
  # fix without arguing with a decision: a screen reader's link list shows link text and nothing else, so
  # five rows of "Archive" were five identical links to five different students. In context the row names
  # the record, which is why 2.4.4 passes at AA - the AAA bar is the link alone.
  #
  # `orders#index` already solved it with a visible verb plus an `sr-only` remainder, and `action_label`
  # is that, in the helpers every row action goes through.
  test "no two row actions share a name and point at different records" do
    classroom = create(:classroom, :with_trading)
    2.times { |i| create(:student, classroom:, name: "Student #{i}") }
    create(:teacher_classroom, teacher: create(:teacher), classroom:)
    sign_in(create(:admin, admin: true, classroom: nil))

    [admin_students_path, admin_users_path, admin_classrooms_path, classrooms_path].each do |path|
      visit path

      ambiguous = page.evaluate_script(<<~JS)
        (function () {
          const seen = {};
          Array.from(document.querySelectorAll("td.table-actions-cell a, td.table-actions-cell button"))
               .forEach(function (el) {
                 if (!el.getClientRects().length) return;
                 const name = (el.getAttribute("aria-label") || el.innerText || "").trim()
                                .replace(/\s+/g, " ");
                 const target = el.getAttribute("href") || el.closest("form")?.getAttribute("action") || "";
                 if (!name) return;
                 seen[name] = seen[name] || [];
                 if (seen[name].indexOf(target) === -1) seen[name].push(target);
               });
          return Object.keys(seen).filter(function (k) { return seen[k].length > 1; });
        })()
      JS

      assert_empty ambiguous,
                   "#{path}: #{ambiguous.inspect} names more than one destination. A row action needs the " \
                   "record's name in an `sr-only` remainder - `action_label` does it."
    end
  end

  test "as a student" do
    _classroom, student, stock = fixtures_for_audit
    sign_in(student)

    { "student home" => root_path, "student portfolio" => user_portfolio_path(student, student.portfolio),
      "trading floor" => stocks_path, "stock" => stock_path(stock),
      "orders" => orders_path, "profile" => edit_profile_path }.each do |l, p|
      visit p
      audit(l)
    end
  end

  test "as a teacher" do
    classroom, = fixtures_for_audit
    teacher = create(:teacher, name: "Alex Rivers")
    create(:teacher_classroom, teacher:, classroom:)
    grade_book = create(:grade_book, classroom:)
    sign_in(teacher)

    { "classes" => classrooms_path, "classroom" => classroom_path(classroom),
      "grade book" => classroom_grade_book_path(classroom, grade_book),
      "new student" => new_classroom_student_path(classroom) }.each do |l, p|
      visit p
      audit(l)
    end
  end

  test "as an admin" do
    _classroom, student, = fixtures_for_audit
    create(:school)
    sign_in(create(:admin, admin: true, classroom: nil))

    { "admin dashboard" => admin_root_path, "admin students" => admin_students_path,
      "admin student" => admin_student_path(student), "admin stocks" => admin_stocks_path,
      "admin new teacher" => new_admin_teacher_path }.each do |l, p|
      visit p
      audit(l)
    end
  end
end
