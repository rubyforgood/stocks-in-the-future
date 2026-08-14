# frozen_string_literal: true

# Every failing test appends its own name to `tmp/test-failures.log`, whatever the command was piped
# through.
#
# This exists because a one-in-many failure was seen and its **name was lost**: the command was
# `bin/rails test:system 2>&1 | tail -3`, which keeps the counts and discards the only lines that identify
# the test. CLAUDE.md has carried a warning about that since the previous time it happened, and the warning
# did not prevent it happening again - so the runner records the name itself rather than depending on how
# somebody chose to invoke it. `bin/flake-hunt` keeps whole logs and is still the tool for *hunting* a
# flake; this is the safety net for the run nobody expected to fail.
#
# **Not a Minitest plugin.** The obvious implementation is `minitest/*_plugin.rb`, and it does not work
# here: Rails calls `Minitest.load_plugins` while parsing options, which is before any test file - and so
# before `test_helper` - has been read, so nothing a test file adds to `$LOAD_PATH` can be found. Verified
# by instrumenting the plugin file and watching it never load. `after_teardown` cannot be mistimed that
# way, and it runs inside the forked worker, so a parallel run records too.
#
# **Only a failure writes.** A green run leaves the file alone, so a later pass cannot erase the record of
# an earlier failure - which is exactly how the last one was lost.
module FailureRecorder
  PATH = Rails.root.join("tmp/test-failures.log")

  def after_teardown
    super

    real = failures.grep_v(Minitest::Skip)
    return if real.empty?

    file, line = self.class.instance_method(name).source_location
    location = "#{Pathname(file).relative_path_from(Rails.root)}:#{line}"

    entry = "#{Time.now.utc.iso8601}  seed=#{Minitest.seed}  #{self.class}##{name}\n"
    entry << "    #{location}\n"
    entry << "    replay: PARALLEL_WORKERS=1 bin/rails test #{location} --seed #{Minitest.seed}\n"
    real.each { |failure| entry << "    #{failure.result_label}: #{failure.message.lines.first&.strip}\n" }

    PATH.dirname.mkpath
    # One `write` per test under O_APPEND, so ten parallel workers cannot interleave mid-entry.
    File.open(PATH, "a") { |f| f.write(entry) }
  end
end
