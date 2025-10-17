# Easy Docker Scripts

These scripts are provided to make it easy to execute routine tasks in Docker.  Unless stated otherwise, these scripts are meant to be executed from the root directory of this repository.  For example, entering `docker build` runs the initial build script.

## Initial Build Script
* You MUST execute the initial build script before you can do anything else.
* After you use the `git clone` command to download this repository, use the `cd` command to enter the root directory of this repository.
* Enter the command `docker/build` to run the initial build script.  This automatically provides the config/database.yml file and runs the `docker compose up` command.
* When the build process is complete, you will be able to view the app in your web browser at http://localhost:3000/ .
* You will NOT be able to execute other commands from the shell tab that's running the local Rails server.  Instead, you MUST start a new tab or window, use the `cd` command to enter the root directory of this repository (if necessary), and enter the commands there.

## Testing the App
* Enter the command `docker/test`.
* To see accurate test coverage results, enter the command `docker/test-cov`.  Because SimpleCov misses test coverage when parallel workers are used, this script disables the parallel workers feature in order to provide accurate test coverage results.

## Seeding Data
Enter the command `docker/seed`.

## Generating Block Diagrams
Enter the command `docker/outline`.

## Bash Shell
Enter the command `docker/bash` to enter a Bash shell within the Docker container.  This allows you to enter commands from directly within the Docker container.  Commands like `bundle install`, `rails db:migrate`, and `rails test` will work here.

## Sandbox
Enter the command `docker/sandbox` to enter the Rails sandbox within the Docker container.

## RuboCop
Enter the command `docker/cop` to run RuboCop.

## Git Check
Enter the command `docker/git-check` to test this app AND run RuboCop.  It's a convenient way to cover all your bases in just ONE step when you believe that you're ready to use the git add/commit/push commands.

## Nuking the Docker Environment
* Enter the command `docker/nuke` to remove all Docker containers and images on your local machine.
* After you've nuked your Docker environment, you'll have to use the initial build script (`docker/build`) again to set up this app.
* Nuking the Docker environment is handy if you think you accidentally messed up your development environment.  While this is a rare event, it's a good option to have when troubleshooting.
* Nuking the Docker environment was handy for making sure that these scripts work as intended.
