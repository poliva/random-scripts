#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# quick-n-dirty simyo.es consumption checker v3
# (c) 2013 Pau Oliva - pof [at] eslack (.) org
#
# license: WTFPL (Do What The Fuck You Want To Public License)
# 
# api functions reverse engineered from the com.simyo android app
#
# enter your simyo.es username and password below

import sys
import argparse
import pyDes
import base64
import urllib
import urllib2
import hmac
import hashlib
import json
import datetime
import pprint
import collections
from time import time

__author__ = 'Pau Oliva Fora'

USERNAME = ""
PASSWORD = ""

def getApiSig(url):
	dig = hmac.new(b'f25a2s1m10', msg='f25a2s1m10' + url.lower(), digestmod=hashlib.sha256).digest()
	return url + "&apiSig=" + dig.encode('hex')

def simyopass():
	k = pyDes.triple_des("25d1d4cb0a08403e2acbcbe0", pyDes.ECB, "\0\0\0\0\0\0\0\0", pad=None, padmode=pyDes.PAD_PKCS5)
	d = urllib.quote(base64.b64encode(k.encrypt(PASSWORD)) + '\n')
	#print "Encrypted: %r" % d
	#print "Decrypted: %r" % k.decrypt(base64.b64decode(urllib.unquote(d)))
	return d

def writeFile(filename, content):
	in_file = open(filename,"wb")
	in_file.write(content)
	in_file.close()

def convert(data):
	# http://stackoverflow.com/q/1254454/
	if isinstance(data, basestring):
		return str(data)
	elif isinstance(data, collections.Mapping):
		return dict(map(convert, data.iteritems()))
	elif isinstance(data, collections.Iterable):
		return type(data)(map(convert, data))
	else:
		return data

def epoch2date(timestamp, format='%d/%m/%Y'):
	timestamp = str(timestamp)[0:10]
	return datetime.datetime.fromtimestamp(int(timestamp)).strftime(format)

def api_request(url, data=""):
	kPublicKey="a654fb77dc654a17f65f979ba8794c34"

	if url[-1:] == "?":
		url=url + "publicKey=" + kPublicKey
	else:
		url=url + "&publicKey=" + kPublicKey

	url=getApiSig(url)

	if VERBOSE:
		print "URL: " + url

	if data=="":
		req = urllib2.Request(url)
	else:
		req = urllib2.Request(url,data)

	try:
		result = urllib2.urlopen(req).read()
	except urllib2.HTTPError as e:
		print e
		sys.exit(1)
	except urllib2.URLError as e:
		print e
		sys.exit(1)
	except:
		print "Unexpected error :("
		raise

	return result

def api_logout():
	URL="https://www.simyo.es/api/logout?sessionId=" + str(sessionId)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

def api_login():
	global sessionId, customerId

	SIMYOPASS = simyopass()
	URL="https://www.simyo.es/api/login?"
	data = "user=" + USERNAME + "&password=" + SIMYOPASS + "&apiSig=null"
	result = api_request(URL,data)
	if VERBOSE: print result + "\n"

	sessionId = json.loads(result)['response']['sessionId']
	customerId = json.loads(result)['response']['customerId']

def subscriptions():
	global registerDate, mainProductId, billCycleType, msisdn, subscriberId, payType

	URL="https://www.simyo.es/api/subscriptions/" + str(customerId) + "?sessionId=" + str(sessionId)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	for subscription in reversed(data['response']['subcriptions']):
		registerDate = subscription['registerDate']
		mainProductId = subscription['mainProductId']
		billCycleType = subscription['billCycleType']
		msisdn = subscription['msisdn']
		subscriberId = subscription['subscriberId']
		payType = subscription['subscriberId']
		if SHOWMSISDN:	
			print "MSISDN: " + msisdn + " (product=" + mainProductId +")"
		else:
			if msisdn == MSISDN:
				break

	if SHOWMSISDN:
		api_logout()
		sys.exit(0)

def consumptionByCycle():
	billCycleCount=""
	URL="https://www.simyo.es/api/consumptionByCycle/" + str(customerId) + "?sessionId=" + str(sessionId) + "&msisdn=" + str(msisdn) + "&billCycleType=" + str(billCycleType) + "&registerDate=" + str(registerDate) + "&billCycle=" + str(billCycle) + "&billCycleCount=" + str(billCycleCount) + "&payType=" + str(payType)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)

	startDate=data['response']['consumptionsByCycle'][0]['startDate']
	endDate=data['response']['consumptionsByCycle'][0]['endDate']
	start = epoch2date(startDate)
	end = epoch2date(endDate)
	print "\nPeriodo de " + start + " a " + end + "\n"

	count = data['response']['consumptionsByCycle'][0]['voice']['count']
	chargeTotal = float(data['response']['consumptionsByCycle'][0]['voice']['chargeTotal'])
	hms = datetime.timedelta(seconds=count)
	print "Llamadas: " + str(hms) + " (" + str(chargeTotal) + ") EUR"

	count = data['response']['consumptionsByCycle'][0]['sms']['count']
	chargeTotal = float(data['response']['consumptionsByCycle'][0]['sms']['chargeTotal'])
	print "SMS: " + str(count) + " (" + str(chargeTotal) + " EUR)"

	count = data['response']['consumptionsByCycle'][0]['mms']['count']
	if count > 0:
		chargeTotal = data['response']['consumptionsByCycle'][0]['mms']['chargeTotal']
		print "MMS: " + str(count) + " (" + str(chargeTotal) + " EUR)"
		
	count = data['response']['consumptionsByCycle'][0]['data']['count']
	chargeTotal = float(data['response']['consumptionsByCycle'][0]['data']['chargeTotal'])
	count = count/1024.0/1024.0
	print "Datos: {0:.2f} MB (".format(count) + str(chargeTotal) + " EUR)"

	PRINT=1

	count = data['response']['consumptionsByCycle'][0]['voicePremium']['count']
	if count > 0:
		chargeTotal = float(data['response']['consumptionsByCycle'][0]['voicePremium']['chargeTotal'])
		hms = datetime.timedelta(seconds=count)
		if PRINT: print ; PRINT=0
		print "Llamadas Premium: " + str(hms) + " (" + str(chargeTotal) + ") EUR"

	count = data['response']['consumptionsByCycle'][0]['smsPremium']['count']
	if count > 0:
		chargeTotal = data['response']['consumptionsByCycle'][0]['smsPremium']['chargeTotal']
		if PRINT: print ; PRINT=0
		print "SMS Premium: " + str(count) + " (" + str(chargeTotal) + " EUR)"

	PRINT=1

	count = data['response']['consumptionsByCycle'][0]['voiceOutgoingRoaming']['count']
	if count > 0:
		chargeTotal = float(data['response']['consumptionsByCycle'][0]['voiceOutgoingRoaming']['chargeTotal'])
		hms = datetime.timedelta(seconds=count)
		if PRINT: print ; PRINT=0
		print "Llamadas Salientes Roaming: " + str(hms) + " (" + str(chargeTotal) + ") EUR"

	count = data['response']['consumptionsByCycle'][0]['voiceIngoingRoaming']['count']
	if count > 0:
		chargeTotal = float(data['response']['consumptionsByCycle'][0]['voiceIngoingRoaming']['chargeTotal'])
		hms = datetime.timedelta(seconds=count)
		if PRINT: print ; PRINT=0
		print "Llamadas Entrantes Roaming: " + str(hms) + " (" + str(chargeTotal) + ") EUR"

	count = data['response']['consumptionsByCycle'][0]['smsRoaming']['count']
	if count > 0:
		chargeTotal = data['response']['consumptionsByCycle'][0]['smsRoaming']['chargeTotal']
		if PRINT: print ; PRINT=0
		print "SMS Roaming: " + str(count) + " (" + str(chargeTotal) + " EUR)"

	count = data['response']['consumptionsByCycle'][0]['mmsRoaming']['count']
	if count > 0:
		chargeTotal = data['response']['consumptionsByCycle'][0]['mmsRoaming']['chargeTotal']
		if PRINT: print ; PRINT=0
		print "MMS Roaming: " + str(count) + " (" + str(chargeTotal) + " EUR)"

	count = data['response']['consumptionsByCycle'][0]['dataRoaming']['count']
	if count > 0:
		chargeTotal = float(data['response']['consumptionsByCycle'][0]['dataRoaming']['chargeTotal'])
		count = count/1024.0/1024.0
		if PRINT: print ; PRINT=0
		print "Datos Roaming: {0:.2f} MB (".format(count) + str(chargeTotal) + " EUR)"

	chargeTotal = float(data['response']['consumptionsByCycle'][0]['chargeTotal'])
	print "\nConsumo total: " + str(chargeTotal) + " EUR\n"

def consumptionDetailByCycle():
	billCycleCount=""
	URL="https://www.simyo.es/api/consumptionDetailByCycle/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&billCycle=" + str(billCycle) + "&registerDate=" + str(registerDate) + "&billCycleCount=" + str(billCycleCount) + "&payType=" + str(payType)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = convert(json.loads(result)['response']['consumptionDetailByCycleList'])
	pp = pprint.PrettyPrinter(indent=4)
	pp.pprint(data)

def frequentNumbers():
	month=billCycle # Parameter month is mandatory
	URL="https://www.simyo.es/api/frequentNumbers/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&registerDate=" + str(registerDate) + "&month=" + str(month)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = convert(json.loads(result)['response'])
	pp = pprint.PrettyPrinter(indent=4)
	pp.pprint(data)

def messages():
	start=1
	count=500
	URL="https://www.simyo.es/api/messages/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&billCycle=" + str(billCycle) + "&registerDate=" + str(registerDate) + "&start=" + str(start) + "&count=" + str(count)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = convert(json.loads(result)['response'])
	pp = pprint.PrettyPrinter(indent=4)
	pp.pprint(data)

def voiceCalls():
	start=1
	count=500
	URL="https://www.simyo.es/api/voiceCalls/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&billCycle=" + str(billCycle) + "&registerDate=" + str(registerDate) + "&start=" + str(start) + "&count=" + str(count)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	startDate=data['response']['voiceCalls']['startDate']
	endDate=data['response']['voiceCalls']['endDate']
	start = epoch2date(startDate)
	end = epoch2date(endDate)
	print "\nPeriodo de " + start + " a " + end + "\n"

	print  "date                type duration category msisdn"
	print  "------------------- ---- -------- -------- -----------"
	for call in data['response']['voiceCalls']['voiceCallInfo']:
		date = epoch2date(call['date'], '%d/%m/%Y %H:%M:%S')
		duration = datetime.timedelta(seconds=call['duration'])
		print '{0}    {1}  {2}       {3} {4}'.format(date, call['type'], duration, call['category'], call['msisdn'])
	print

def rechargeHistory():
	startDate=registerDate
	endDate = time()
	endDate = int(endDate) * 1000
	URL="https://www.simyo.es/api/rechargeHistory/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&registerDate=" + str(registerDate) + "&startDate=" + str(startDate) + "&endDate=" + str(endDate)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	print "\nHistorial de regargas:\n"
	data = convert(json.loads(result)['response']['rechargeHistory'])
	pp = pprint.PrettyPrinter(indent=4)
	pp.pprint(data)

def mgmHistory():
	URL="https://www.simyo.es/api/mgmHistory/" + str(customerId) + "?sessionId=" + str(sessionId)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	receivedPoints=data['response']['mgmHistoryList']['receivedPoints']
	usedPoints=data['response']['mgmHistoryList']['usedPoints']
	totalAvailablePoints=data['response']['mgmHistoryList']['totalAvailablePoints']

	print "EUROS GANADOS: " + str(receivedPoints)
	print "EUROS GASTADOS: " + str(usedPoints)
	print "TOTAL DISPONIBLE: " + str(totalAvailablePoints)

def invoiceList():
	URL="https://www.simyo.es/api/invoiceList/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&registerDate=" + str(registerDate)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	return data

def printInvoiceList():
	data = invoiceList()
	for invoice in data['response']['invoiceList']:
		startDate=invoice['startDate']
		endDate=invoice['endDate']
		invoiceNO=invoice['invoiceNO']
		invoiceId=invoice['invoiceId']
		start = epoch2date(startDate)
		end = epoch2date(endDate)
		print "Factura " + str(invoiceNO) + " (id=" + str(invoiceId) + ") del " + str(start) + " al " + str(end)

def downloadInvoice():
	data = invoiceList()
	for invoice in data['response']['invoiceList']:
		invoiceId=invoice['invoiceId']
		if invoiceId == reqInvoiceId:
			invoiceNO=invoice['invoiceNO']
			break
	if invoiceNO=="":
		print "Can't find invoice with id = " + str(reqInvoiceId)
		sys.exit(1)

	URL="https://www.simyo.es/api/downloadInvoice?sessionId=" + str (sessionId) + "&invoiceNO=" + str(invoiceNO) + "&invoiceId=" + str(invoiceId)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	filename = data['response']['invoice']['filename']
	print "File: " + str(filename)
	content=base64.b64decode(data['response']['invoice']['content'])
	writeFile(filename, content)

def parse_cmd():
	global VERBOSE, INVOICELIST, MSISDN, SHOWMSISDN, SHOWMGM, INVOICEDOWNLOAD, VOICECALLS, MESSAGES, RECHARGE, FREQUENT, BYDAY
	global billCycle, reqInvoiceId

	parser = argparse.ArgumentParser()
	parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='verbose mode')
	parser.add_argument('-c', '--bycycle', dest='bycyle', action='store_true', help='show consumption detail by billing cycle (default)')
	parser.add_argument('-y', '--byday', dest='byday', action='store_true', help='show consumption detail by day')
	parser.add_argument('-l', '--listinvoice', dest='invoicelist', action='store_true', help='list all downloadable invoices')
	parser.add_argument('-s', '--showmsisdn', dest='showmsisdn', action='store_true', help='list the msisdns available in the account')
	parser.add_argument('-g', '--mgm', dest='showmgm', action='store_true', help='show member-get-member history')
	parser.add_argument('-o', '--voicecalls', dest='voicecalls', action='store_true', help='show voice call records')
	parser.add_argument('-e', '--messages', dest='messages', action='store_true', help='show sms records')
	parser.add_argument('-r', '--recharge', dest='recharge', action='store_true', help='show recharge history')
	parser.add_argument('-f', '--frequent', dest='frequent', action='store_true', help='show frequent numbers')

	parser.add_argument('-b', '--billcycle', dest='billCycle', help='specify the billing cycle (from 1 to 6), default=1')
	parser.add_argument('-m', '--msisdn', dest='msisdn', help='specify the msisdn if you have more than 1 line')
	parser.add_argument('-d', '--download', dest='invoice_id', help='download invoice specified by INVOICE_ID')
	args = parser.parse_args()

	if USERNAME=="":
		print "Edit the script to enter your username/password"
		sys.exit(1)

	VERBOSE = args.verbose
	MSISDN = args.msisdn
	SHOWMSISDN = args.showmsisdn
	SHOWMGM = args.showmgm
	INVOICELIST = args.invoicelist
	VOICECALLS = args.voicecalls
	MESSAGES = args.messages
	RECHARGE = args.recharge
	FREQUENT = args.frequent
	BYDAY = args.byday

	if args.invoice_id == None:
		INVOICEDOWNLOAD=0
	else:
		reqInvoiceId = args.invoice_id
		INVOICEDOWNLOAD=1

	if args.billCycle == None:
		billCycle = int(1)
	else:
		billCycle = int(args.billCycle)

	if (billCycle > 6) or (billCycle < 1):
		sys.stderr.write('Billing Cycle must be an integer from 1 (current month) to 6\n');
		sys.exit(1)

if __name__ == '__main__':
	parse_cmd()
	api_login()
	subscriptions()
	if BYDAY:
		consumptionDetailByCycle()
		api_logout()
		sys.exit(0)
	if FREQUENT:
		frequentNumbers()
		api_logout()
		sys.exit(0)
	if RECHARGE:
		rechargeHistory()
		api_logout()
		sys.exit(0)
	if MESSAGES:
		messages()
		api_logout()
		sys.exit(0)
	if VOICECALLS:
		voiceCalls()
		api_logout()
		sys.exit(0)
	if SHOWMGM:
		mgmHistory()
		api_logout()
		sys.exit(0)
	if INVOICELIST:
		printInvoiceList()
		api_logout()
		sys.exit(0)
	if INVOICEDOWNLOAD:
		downloadInvoice()
		api_logout()
		sys.exit(0)
	# default if no parameters specified
	consumptionByCycle()
	api_logout()
	sys.exit(0)

#TODO:
#https://www.simyo.es/api/contact
