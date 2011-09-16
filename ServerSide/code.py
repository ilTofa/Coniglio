#! /usr/bin/python
#
# This is the main file for web.py and for interaction with coniglio iOS client
#
#  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
#  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#

import web
import subprocess
import os
import hashlib
import sqlite3
import datetime

urls = (
  '/', 'index',
  '/trans', 'mp3transcoder',
  '/alarm', 'radioalarm'
)

dbPath = '/conigliopath/alarms.db'

app = web.application(urls, globals())

def auth(remoteID, authKey):
    # Check remote client
    m = hashlib.sha256()
    m.update("gt")
    m.update(remoteID)
    m.update("SHAsalt")
    if(m.hexdigest() != authKey):
        return False
    return True
    
class index:
    def GET(self):
        return "Coniglio backend, version 2.0.2"

class radioalarm:
    def GET(self):
        x = web.input(myfile={})
        if not('device' in x):
            return "!Error (2) in authentication. Please contact the developer.\n"
        if not('authenticator' in x):
            return "!Error (1) in authentication. Please contact the developer.\n"
        if not('sn' in x):
            return "!Error (3) in authentication. Please contact the developer.\n"          
        if not(auth(x.device, x.authenticator)):
            return "NOT authenticated on a GET on /alarm"
        conn = sqlite3.connect(dbPath)
        c = conn.cursor()
        c.execute("select alarmtime, radiourl, active from alarms where sn=:sn", {"sn" : x.sn})
        row = c.fetchone()
        if row == None:
            retValue = "0|None|0"
        else:
            # print "0:", row[0]
            # print "1:", row[1]
            # print "2:", row[2]
            # print "DUDU"
            # print "X:", '%d|%s|%s' % (row[0], row[1], row[2])
            retValue = '%d|%s|%s' % (row[0], row[1], row[2])
        conn.close()    
        return retValue

    def POST(self):
        x = web.input(myfile={})
        # print "DEBUG: ", x
        if not('device' in x):
            return "!Error (2) in authentication. Please contact the developer.\n"
        if not('authenticator' in x):
            return "!Error (1) in authentication. Please contact the developer.\n"
        if not(auth(x.device, x.authenticator)):
            return "!Error (3) in authentication. Please contact the developer.\n"
        if not('uri' in x):
            return "!Error (4) in parsing. Please contact the developer.\n"
        if not('alarmtime' in x):
            return "!Error (5) in parsing. Please contact the developer.\n"
        if not('token' in x):
            return "!Error (6) in parsing. Please contact the developer.\n"
        if not('sn' in x):
            return "!Error (7) in parsing. Please contact the developer.\n"
        if not('active' in x):
            return "!Error (8) in parsing. Please contact the developer.\n"
        # print ("received: ", '%s|%s|%s|%s|%s|%d' % (x.device, x.sn, x.token, x.uri, x.active, int(x.alarmtime)))

        conn = sqlite3.connect(dbPath)
        c = conn.cursor()
        # delete row and then insert
        c.execute("delete from alarms where sn=:sn", {"sn" : x.sn})
        c.execute("insert into alarms values (?,?,?,?,?,?)", (x.device, x.sn, x.token, x.uri, x.active, int(x.alarmtime)))
        conn.commit()
        conn.close()    
        return "0"

class mp3transcoder:
    def POST(self):
        x = web.input(myfile={})
        filedir = '/websitepath/mp3s'
        urldir = 'http://website/mp3s'
        # ensure that data is here.
        if not('myfile' in x):
            return "!Error in file transfer. Please retry.\n"
        if not('device' in x):
            return "!Error (2) in authentication. Please contact the developer.\n"
        if not('authenticator' in x):
            return "!Error (1) in authentication. Please contact the developer.\n"
        # Authentication (with backdoor)
        if not(auth(x.device, x.authenticator)):
            return "!Error (3) in authentication. Please contact the developer.\n"
        # remote end authenticated. Transcode.
        filepath=x['myfile'].filename.replace('\\','/')
        # splits the and chooses the last part (the filename with extension)
        filename=filepath.split('/')[-1]
        m4afilename=filedir +'/'+ filename
        # creates the file and store the received data
        fout = open(m4afilename,'w')
        fout.write(x.myfile.file.read())
        fout.close()
        # call ffmpeg for mp3 conversion
        mp3filename=m4afilename[:-4] + '.mp3'
        cmdparams="/usr/bin/ffmpeg -y -i " + m4afilename + " -ab 33000 " + mp3filename
        # if reading parameters will be required => x.parameter_name
        retcode = subprocess.call(cmdparams, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if retcode != 0:
            return "!Error in transcoding. Please retry\n"
        # return to the caller the URL for the transcoded file
        return urldir + '/' + filename[:-4] + '.mp3'

if __name__ == "__main__": app.run()

web.config.debug=False
