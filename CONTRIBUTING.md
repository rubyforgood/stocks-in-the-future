# Contributing

## Workflow for Contributors

1. **Find an issue** to work on from our existing issues. If you've identified a bug or potential improvement, please discuss it in the #stocks-in-the-future Slack channel before starting work.

2. **Create a branch** from `main` with a descriptive name including the issue number

   ```console
   $ git checkout main
   $ git pull
   $ git checkout -b feature-description-123
   ```

3. **Make your changes** and commit them with descriptive messages

   ```console
   $ git add .
   $ git commit -m "Add feature X that solves problem Y"
   ```

4. **Run linting** to ensure code quality

   ```console
   $ bin/lint
   ```

   If issues are found, fix them or use auto-fix when appropriate:

   ```console
   $ bundle exec rubocop -A
   ```

5. **Run tests** to verify your changes don't break existing functionality

   ```console
   $ bin/rails test
   ```

   To check test coverage, run:

   ```console
   $ bin/coverage
   ```

   This generates an HTML coverage report at `coverage/index.html`

6. **Push your branch** to GitHub

   ```console
   # For the first push to a new branch
   $ git push --set-upstream origin feature-description-123

   # For all subsequent pushes
   $ git push
   ```

7. **Open a Pull Request** against the `main` branch
   - Include a clear description of the changes
   - Linking the issue number in the PR's description (e.g., `Resolves #123`)
      - [More about linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)
   - Wait for CI checks to pass
   - Request review from team members

## Getting Help

If you need help at any point, comment on the issue you're working on or ask in the #stocks-in-the-future channel on the Ruby for Good Slack.

## Troubleshooting

### ASDF

If you find yourself in a cycle of encountering errors such as:

```
in stocks-in-the-future/ on main
› asdf install ruby 3.4.4

in stocks-in-the-future/ on main
› asdf set local ruby 3.4.4

in stocks-in-the-future/ on main
› ruby --version
No version is set for command ruby
Consider adding one of the following versions in your config file at /Users/america/dev/stocks-in-the-future/.tool-versions
ruby 3.3.6
ruby 3.1.6
```

Try upgrading asdf and trying again.
