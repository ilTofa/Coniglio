#! /usr/bin/python
# This is the python script for sending the radio to the nabaztag
#
#  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
#  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#

import datetime
import time
import sqlite3
import urllib
import logging
import logging.handlers

# Get time
ora = int(time.time())
# Setup logging
logFilename = '/conigliopath/alarm/alarm.log'
# Set up a specific logger with our desired output level
myLogger = logging.getLogger('MyLogger')
myLogger.setLevel(logging.INFO)
# Add the log message handler to the logger
handler = logging.handlers.RotatingFileHandler(logFilename, maxBytes=65535, backupCount=5)
myLogger.addHandler(handler)
# Ready. Go ahead, then
myLogger.info("%s (%d): alarmsender.py v.1.05 started." % (datetime.datetime.fromtimestamp(ora).ctime(), ora))
opener = urllib.FancyURLopener()
conn = sqlite3.connect('/conigliopath/alarms.db')
c = conn.cursor()
timeForAlarm = ora + 100	# Get 1.5 minutes before to account for seconds in setting alarm
c.execute("select sn, radiourl, alarmtime, token from alarms where alarmtime < :ora and active = '1'", {"ora" : timeForAlarm})
li = c.fetchall()
for row in li:
	myLogger.info("%s (%d): alarm found for %s with URI %s" % (datetime.datetime.fromtimestamp(ora).ctime(), ora, row[0], row[1]))
	try:
	# the nabaztag is sleeping?
		testUrl = "http://api.wizz.cc/?sn=%s&token=%s&action=7" % (row[0], row[3])
		f = opener.open(testUrl)
		testResult = f.read(1024)
		f.close()
		if(testResult.find("YES") != -1):
			myLogger.info("%s (%d): %s is sleeping. Waking him/her." % (datetime.datetime.fromtimestamp(ora).ctime(), ora, row[0]))
		    # wake the nabaztag
			wakeUrl = "http://api.wizz.cc/?sn=%s&token=%s&action=14" % (row[0], row[3])
			f = opener.open(wakeUrl)
		else:
   		    myLogger.debug("%s is awake." % (row[0]))
		    # Now go ahead with the radio...
   		    radioUrl = "http://api.wizz.cc/?sn=%s&token=%s&urlList=%s" % (row[0], row[3], row[1])
		    f = opener.open(radioUrl)
	        # on success delete row
		    myLogger.info("%s (%d): radio sent to %s." % (datetime.datetime.fromtimestamp(ora).ctime(), ora, row[0]))
		    c.execute("delete from alarms where sn=:sn", {"sn" : row[0]})
	except IOError:
		myLogger.error("ERROR: Invalid URL: %s" % (row[1]))
	finally:
		f.close()
conn.commit()
conn.close()
endTime = time.time()
myLogger.info("%s (%d): stopping after %d seconds." % (datetime.datetime.fromtimestamp(endTime).ctime(), endTime, endTime - ora))
