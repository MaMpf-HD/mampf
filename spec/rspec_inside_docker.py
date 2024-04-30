import sys
import subprocess

# Path where the custom formatter of the Ruby Test explorer extension is memory-mapped
FORMATTER_PATH_IN_DOCKER = "/root/tmp/formatter.rb"
PROJECT_ROOT_FOLDER_NAME = "mampf"
DOCKER_SERVICE_NAME = "mampf"


def switch_formatter_path():
    """
    Memory-maps the custom formatter of the Ruby Test explorer extension.

    The Ruby Test explorer extension uses a custom formatter to get a specific
    output JSON format. The path to the formatter is automatically passed as an
    argument to the rspec command by the extension. We need to replace this
    path by the path to the memory-mapped formatter in the Docker container.
    """

    formatter_argument_index = None
    for i, arg in enumerate(sys.argv):
        if arg == '--require':
            formatter_argument_index = i
            break

    if formatter_argument_index == None:
        print('Please specify "--require path/to/custom/formatter.rb"')
        sys.exit(1)

    # Switch the path to the custom formatter to the memory-mapped path
    formatter_path_on_host = sys.argv[formatter_argument_index + 1]
    sys.argv[formatter_argument_index + 1] = FORMATTER_PATH_IN_DOCKER

    return formatter_path_on_host


def process_paths():
    for i, arg in enumerate(sys.argv):
        if not arg.startswith('./') and "spec" in arg:
            sys.argv[i] = replace_absolute_paths_by_relative_paths(sys.argv[i])


def replace_absolute_paths_by_relative_paths(path):
    res = path.split(PROJECT_ROOT_FOLDER_NAME + '/')[1]
    if not res:
        print(f'Path {path}'
              f' does not contain string "{PROJECT_ROOT_FOLDER_NAME}/"')
        sys.exit(1)
    return './' + res  # make path relative


if __name__ == '__main__':
    formatter_path_on_host = switch_formatter_path()
    process_paths()

    rspec_args = ' '.join(sys.argv[1:])
    test_command = f'set -o allexport && . ./docker-dummy.env && set +o allexport && \
        RAILS_ENV=test bundle exec rspec {rspec_args}'

    docker_cmd = f'cd ./docker/test && docker compose run --rm -T --entrypoint="" -v {formatter_path_on_host}:{FORMATTER_PATH_IN_DOCKER} {DOCKER_SERVICE_NAME} sh -c "{test_command}"'

    subprocess.call(docker_cmd, shell=True)
