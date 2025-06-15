"""
Script to run RSpec tests inside a Docker container. Works with the Ruby LSP
VSCode extension [1] and the Ruby Test Explorer [2].

For ongoing development, see also [3] and [4].

[1] https://marketplace.visualstudio.com/items?itemName=Shopify.ruby-lsp
[2] https://marketplace.visualstudio.com/items?itemName=connorshea.vscode-ruby-test-adapter
[3] https://github.com/Shopify/ruby-lsp/issues/3586
[4] https://github.com/Shopify/ruby-lsp/pull/2919
"""

import sys
import subprocess

FORMATTER_PATH_IN_DOCKER = "/root/tmp/formatter.rb"
PROJECT_ROOT_FOLDER_NAME = "mampf"
DOCKER_SERVICE_NAME = "mampf"
DOCKER_COMPOSE_FOLDER = "./docker/test"


def switch_formatter_path():
    """
    Memory-maps the custom formatter of the Ruby Test Explorer extension.

    The Ruby Test Explorer extension uses a custom formatter to get a specific
    output format for the test runs. The path to the formatter is automatically
    passed as an argument to the rspec command. We need to replace this path by
    the path to the memory-mapped formatter in the Docker container.
    """
    formatter_argument_index = None
    for i, arg in enumerate(sys.argv):
        if arg in ("--require", "-r"):
            formatter_argument_index = i
            break

    if formatter_argument_index is None:
        # the extension should pass this automatically for you
        print('Please specify "--require path/to/custom/formatter.rb"')
        sys.exit(1)

    # Switch the path of the custom formatter to the memory-mapped path
    path_on_host = sys.argv[formatter_argument_index + 1]
    sys.argv[formatter_argument_index + 1] = FORMATTER_PATH_IN_DOCKER

    return path_on_host


def replace_absolute_paths_by_relative_paths(path):
    """
    Replaces absolute paths by relative paths for usage inside the Docker container.
    """
    res = path.split(PROJECT_ROOT_FOLDER_NAME + "/")[1]
    if not res:
        print(f"Path {path}" f' does not contain string "{PROJECT_ROOT_FOLDER_NAME}/"')
        sys.exit(1)
    return "./" + res


def main():
    """
    Main function to run RSpec tests inside a Docker container.
    """
    formatter_path_on_host = switch_formatter_path()
    for i, arg in enumerate(sys.argv):
        if not arg.startswith("./") and "spec" in arg:
            sys.argv[i] = replace_absolute_paths_by_relative_paths(sys.argv[i])

    rspec_args = " ".join(sys.argv[1:])
    test_command = f"bundle install && RAILS_ENV=test bundle exec rspec {rspec_args}"

    docker_cmd = (
        f'cd {DOCKER_COMPOSE_FOLDER} && docker compose run --rm -T --entrypoint="" '
        f"-v {formatter_path_on_host}:{FORMATTER_PATH_IN_DOCKER} "
        f'{DOCKER_SERVICE_NAME} sh -c "{test_command}"'
    )

    result = subprocess.run(
        docker_cmd, shell=True, capture_output=True, text=True, check=False
    )
    print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
