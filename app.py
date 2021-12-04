import pymysql

username = input("Enter username: ")
password = input("Enter your password: ")

try:
    cnx = pymysql.connect(host='localhost', user=username,
                          password=password,
                      db='cubes', charset='utf8mb4',
                          cursorclass=pymysql.cursors.DictCursor)

except pymysql.err.OperationalError:
    print('Error: %d: %s' % (e.args[0], e.args[1]))




try:
    print('Connected successfully')
except pymysql.Error as e:
    print('Error: %d: %s' % (e.args[0], e.args[1]))


finally:
    cnx.close()
    quit()




