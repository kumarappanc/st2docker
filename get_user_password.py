import sys
import json

username = sys.argv[1]
filename = sys.argv[2]
json_data=open(filename).read()

data = json.loads(json_data)

for user in data['users']:
    if user['name'] == username:
        print(user['password'])
