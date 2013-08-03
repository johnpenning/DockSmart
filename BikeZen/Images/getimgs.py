#!/usr/bin/python

#--------------------------------------
# getimgs.py
# Gets icon image files in sequential order
# Copyright John Penning, August 2013
#--------------------------------------

import sys, os

for i in range(100):
	# print str('%02d' % i)
	os.system('curl http://google-maps-icons.googlecode.com/files/red' + str('%02d' % i) + '.png > red' + str('%02d' % i) + '.png')
