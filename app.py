import pymysql

username = input("Enter username: ")
password = input("Enter your password: ")

#Connect to server
try:
    cnx = pymysql.connect(host='localhost', user=username,
                          password=password,
                      db='cubes', charset='utf8mb4',
                          cursorclass=pymysql.cursors.DictCursor)

except pymysql.err.OperationalError:
    print('Error: %d: %s' % (e.args[0], e.args[1]))

command = ""
valid_commands = ["q", "help", "friends"]
help_statement = """ q: quit 
help: see list of commands"""

#Loop--user can keep entering commands until they quit
while command != "q":
    command = input ('Please enter a command. To see a list of possible commands, type "help".\n') 
    command_as_list = command.split()
    if command_as_list[0] not in valid_commands:
        print("Invalid command. Please try again.")
    elif command_as_list[0] == "help":
        print(help_statement)
    else:
        execute(command_as_list)

#Will be reached when the loop breaks
cnx.close()
quit()

def execute(command_list):
    try:
        cur = cnx.cursor()
        command = command_list[0]

        #Still need to 
        if command == "friends":
            user = command_list[1]
            cur.callproc("find_friends",([user]))

    except pymysql.Error as e:
        print('Error: %d: %s' % (e.args[0], e.args[1]))
