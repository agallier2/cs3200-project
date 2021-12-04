import pymysql

from getpass import getpass
from typing import Tuple, List, Optional

VALID_COMMANDS = {"q", "help", "friends"}
HELP_STATEMENT = """  q: quit
  help: see list of commands"""


def get_db_credentials() -> Tuple[str, str]:
    print('Connect to database')
    username = input('Enter username: ')
    password = getpass('Enter your password: ')

    return username, password


def connect_to_db(username: str, password: str) -> pymysql.connections.Connection:
    """
    Attempt to connect to the cubes MySQL database. If there is an error,
    output it and return `None`.

    :raises pymysql.err.OperationalError: if a connection error occurs
    """
    return pymysql.connect(
        host='localhost',
        user=username,
        password=password,
        db='cubes',
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )


def is_valid_command(command: str) -> bool:
    return command in VALID_COMMANDS


def execute(cnx: pymysql.connections.Connection, current_user: str, command: str, args: List[str]):
    """
    Executes a command as the given user with the given arguments.

    If an error occurs, prints "Error: (code): (description)"
    """
    try:
        cur = cnx.cursor()
        cur.callproc(command, (args))
        return cur.fetchall()

    except pymysql.Error as e:
        err_code, err_desc = e.args
        print(f'Error: {err_code}: {err_desc}')


def parse_user_input(user_input: str) -> Tuple[str, List[str]]:
    """
    :return: a tuple of `(command, [arguments...])`
    """
    if not user_input:
        return None, []

    terms = user_input.split()
    return terms[0], terms[1:]


def login(args: List[str]) -> Optional[str]:
    if not args:
        print('Please provide a username')
    return args[0]


def run_command_loop(cnx: pymysql.connections.Connection) -> None:
    print('Enter commands. To see a list of possible commands, type "help".\n')
    command, args = None, []
    current_user = None

    while True:
        user_input = input('> ')
        command, args = parse_user_input(user_input)

        if command == "help":
            print(HELP_STATEMENT)
        elif command == 'q':
            break
        elif command == 'login':
            current_user = login(args)
        elif command == 'logout':
            current_user = None
        elif is_valid_command(command):
            execute(cnx, current_user, command, args)
        else:
            print("Invalid command. Please try again.")

        print()


def main():
    username, password = get_db_credentials()

    try:
        cnx = connect_to_db(username, password)
    except pymysql.err.OperationalError as e:
        error_code, error_description = e.args
        print(f'Error: {error_code}: {error_description}')
        return

    run_command_loop(cnx)

    cnx.close()


if __name__ == '__main__':
    main()
