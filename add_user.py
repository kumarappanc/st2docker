import sys
import json
import os
import crypt

filename = sys.argv[1]
json_data=open(filename).read()

data = json.loads(json_data)

for user in data['users']:
    print('creating user {0}'.format(user['name']))
    password = user['password']
    encPass = crypt.crypt(password,"22")
    os.system("useradd -p "+encPass+" "+ user['name'])
    dataMap  = ('---',
        ' username: "{0}"'.format(user['name']),
        ' description: "{0}"'.format(user['description']),
        ' enabled: {0}'.format(user['enabled']),
        ' roles:',
        '  - "{0}"'.format(user['roles'])
        )
    yamlfile = '/opt/stackstorm/rbac/assignments/'+ user['name']+'.yaml'
    with open(yamlfile,'w') as outfile:
        for line in dataMap:
            outfile.write(str(line) + "\n")