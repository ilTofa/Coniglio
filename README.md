Introduction
------------

Coniglio is an universal application for iOS the controls a Nabaztag. It do not move ears but does the useful things a Nabaztag should do.
Coniglio means, in Italian, what Nabaztag means in Armenian: Bunny.

The application has been sold on AppStore for a couple years. In July 2011 Mindscape cut the support to Nabaztag and shut down its server. I pulled Coniglio from the AppStore because the nabaztags were completely unuseful.

*The OpenJabNab project*

In the last months a couple of OpenJabNab server have been brought up everywhere (the most part in France, of course). wizz.cc (the author of the very good web application [NabaztagController](http://nabz.wizz.cc/)) brought up some API that allowed me to have Coniglio work again.

*The openource path*

Meanwhile I really use my nabaztag only as radio, the features of Coniglio are not used by me, nor tested and, in any case, the OpenJabNab ecosystem is _fragile_, I cannot ensure the level of support the I would like.

The solution? Opensource the project, so that if someone is interested to it he could fork from here and have its product.

The source is released under the MIT License (basically, make anything you want with the code, preserving my copyright notice).

Informations on Coniglio
------------------------

Usage, instructions, screenshots, etc. can be found on the original web site of [Coniglio](http://www.iltofa.com/Coniglio/).

iOS code
--------

The code is compilable as is on XCode 4.x runs on iOS4, _should_ run also on iOS3.1 or later but I have no device to test on it so I'm not sure. It works under the beta of the next version of iOS.

The code is stand alone for the most part. The radioalarm and the voice recorder system needs some server-side components that are into the ServerSide directory. Beware of the server URL and SHA salt in AlarmChooser.h and of the MainViewController.h. The constants are kAlarmBaseURI, kRecordingURI and kSHASalt.

The code is dependent on an ancient version of the Facebook connect (FBConnect) iOS framework for facebook status reading (you will need key and secret in Facebook.m to have meaningful answers from Facebook) and from [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/) for some of the network I/O.

Of course, you will need a developer certificate to use it on your device (or to publish it on the AppStore). Contact me if you need help on publishing, I could be available to push a new version (for free) if someone is available to support it.

Server-side code
----------------

The server side code are 3 python script, designed to be run under [web.py](http://webpy.org/). I personally run it on a [Linode](http://www.linode.com/) VPS, with Debian 6 and lighttpd as web server. Any supported platform for web.py capable of running ffmpeg binaries will do. The code is very easy to understand. code.py is the "main" responder, while alarmsender.py should be called by cron to send the radioalarms to the remote nabaztag.

The server-side code and the iOS code needs to be syncronized in called URLs and SHA salt. Beware also that some paths are hardcoded in serverside code (/usr/bin/ffmpeg, the location of SQLite db and the log files). Be aware of that and have fun!

If you need help/informations on this code
------------------------------------------

Feel free to write me, I will try to help: gt AT iltofa.it Check also the [original web site](http://www.iltofa.com/Coniglio) for more informations and help.
