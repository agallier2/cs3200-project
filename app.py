import pymysql

from getpass import getpass
from inspect import signature
from typing import Tuple, List, Optional, Set

# Valid commands and help text
COMMANDS = [
    ('q', 'quit'),
    ('help', 'see list of commands'),
    ('login', 'login via username'),
    ('logout', 'reset current user'),
    ('current_user', 'check current user'),
    ('create_user', 'add a new user to the database'),
    ('create_session', 'self explanatory'),
    ('find_friends', 'see friends of the current user')
]

def valid_commands() -> Set[str]:
    """
    Retrieve a set of valid commands.
    """
    return {command for command, _ in COMMANDS}


def is_valid_command(command: str) -> bool:
    return command in valid_commands()


def print_help() -> None:
    for command, help in COMMANDS:
        print(f'  {command}: {help}')


class FrontendState:
    """
    State within the lifecycle of the command loop.
    """
    current_user = None
    current_session_id = None

    def __init__(self, cnx: pymysql.connections.Connection):
        self.cnx = cnx

    @staticmethod
    def _get_function_return_value(row: dict) -> any:
        """
        The DictCursor key on a function call makes it hard to grab
        the return value, this method helps with that.
        """
        return next(iter(row.values()))

    def login(self, username: str) -> Optional[int]:
        """
        Login a user by username. If username is valid, return the user id.
        """
        with self.cnx.cursor() as cur:
            sql = 'SELECT get_user_id(%s)'
            cur.execute(sql, (username,))

            user_id = self._get_function_return_value(cur.fetchone())
            if user_id:
                self.current_user = {'id': user_id, 'username': username}
                return self.current_user['id']

    def logout(self) -> None:
        self.current_user = None

    def check_logged_in(self) -> bool:
        if not self.current_user:
            print('Please login first')
        return bool(self.current_user)


class CommandExecutor:
    """
    Implementations for all commands executable from the command line interface.
    """

    def __init__(self, fe_state: FrontendState):
        self.fe_state = fe_state

    def login(self, username: str) -> bool:
        """
        Log in via username. Return `True` if successful, `False` otherwise.
        """
        v = self.fe_state.login(username)
        return bool(v)

    def logout(self) -> None:
        self.fe_state.logout()

    def current_user(self) -> dict:
        return self.fe_state.current_user

    def create_user(self, username: str):
        return execute_proc(self.fe_state.cnx, 'create_user', [username])

    def delete_account(self) -> bool:
        if not self.fe_state.check_logged_in():
            return False

        execute_proc(self.fe_state.cnx, 'remove_user', [self.fe_state.current_user['username']])
        self.logout()
        return True

    def find_friends(self) -> Optional[List[str]]:
        """
        Get friends of the current user. Return `None` if not logged in.
        """
        if not self.fe_state.check_logged_in():
            return None

        result = execute_proc(self.fe_state.cnx, 'find_friends', [self.fe_state.current_user['username']])
        return [row['username'] for row in result]

    def add_friend(self, friend_name: str) -> bool:
        """
        Add a friend.
        """
        if not self.fe_state.check_logged_in():
            return False

        execute_proc(self.fe_state.cnx, 'add_friend', [self.fe_state.current_user['username'], friend_name])
        return True

    def remove_friend(self, friend_name: str) -> bool:
        if not self.fe_state.check_logged_in():
            return False

        execute_proc(self.fe_state.cnx, 'remove_friend', [self.fe_state.current_user['username'], friend_name])
        return True

    def create_session(self, session_name: str, cube_type: str) -> Optional[int]:
        """
        Create a session. Return the session ID, or `None` if not logged in.
        """
        return execute_proc(self.fe_state.cnx, 'create_session', [session_name, cube_type])

    def list_sessions(self) -> List[dict]:
        return execute_proc(self.fe_state.cnx, 'list_sessions', [])

    def add_round(self, scramble: str, session_id: int):
        return execute_proc(self.fe_state.cnx, 'add_round', [scramble, session_id])

    def list_rounds(self, session_id: int):
        return execute_proc(self.fe_state.cnx, 'list_rounds', [session_id])

    def add_solve(self, round_id: int, time: float, penalty: str = None):
        if not self.fe_state.check_logged_in():
            return None

        return execute_proc(
            self.fe_state.cnx, 'add_solve',
            [self.fe_state.current_user['id'], round_id, time, penalty]
        )

    def list_solves(self, round_id: int):
        return execute_proc(self.fe_state.cnx, 'list_solves', [round_id])

    def my_solves(self):
        if not self.fe_state.check_logged_in():
            return None

        return execute_proc(self.fe_state.cnx, 'find_solves_for_user', [self.fe_state.current_user['username']])

    def my_average_of_5(self):
        if not self.fe_state.check_logged_in():
            return None

        return execute_proc(self.fe_state.cnx, 'average_of_5', [self.fe_state.current_user['username']])

    @staticmethod
    def _argument_error_text(command: str, args_required: int, args_given: int) -> str:
        return f'Error: {command} takes {args_required} arguments, but {args_given} given'

    def execute_command(self, command, args) -> None:
        """
        Execute a command with the given arguments. Print results and errors.
        """
        if hasattr(self, command):
            f = getattr(self, command)

            try:
                result = f(*args)
                if result is not None:
                    print(result)
            except TypeError:
                num_params = len(signature(f).parameters)
                print(self._argument_error_text(f.__name__, num_params, len(args)))
            except pymysql.Error as e:
                err_code, err_desc = e.args
                print(f'Error: {err_code}: {err_desc}')

        else:
            print('Invalid command')

        print()


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
        db='cubes3',
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )


def execute_proc(
    cnx: pymysql.connections.Connection,
    command: str, args: List[str]
) -> List[dict]:
    """
    Executes a command with the given arguments.

    :raises pymysql.Error: if a database error occurs
    """
    cur = cnx.cursor()
    cur.callproc(command, (args))
    return cur.fetchall()


def parse_user_input(user_input: str) -> Tuple[str, List[str]]:
    """
    :return: a tuple of `(command, [arguments...])`
    """
    if not user_input:
        return None, []

    terms = user_input.split()
    return terms[0], terms[1:]


def run_command_loop(cnx: pymysql.connections.Connection) -> None:
    print('Enter commands. To see a list of possible commands, type "help".\n')
    state = FrontendState(cnx)
    exc = CommandExecutor(state)

    command, args = None, []

    while True:
        user_input = input('> ')
        command, args = parse_user_input(user_input)

        if command == "help":
            print_help()
        elif command == 'q':
            break
        else:
            exc.execute_command(command, args)

    # cnx.commit()


def main():
    username, password = get_db_credentials()

    try:
        cnx = connect_to_db(username, password)
    except pymysql.err.OperationalError as e:
        error_code, error_description = e.args
        print(f'Error: {error_code}: {error_description}')
        return
    except RuntimeError:
        print('Invalid credentials')
        return

    run_command_loop(cnx)

    cnx.close()


if __name__ == '__main__':
    main()
