#! /usr/bin/python
import sqlite3

conn = sqlite3.connect('/conigliopath/alarms.db')
c = conn.cursor()
c.execute("create table alarms (device text, sn text, token text, radiourl text, active text, alarmtime integer)")
conn.commit()
c.close()