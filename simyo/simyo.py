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

BASE_URL = "https://api.simyo.es/simyo-api"

def getApiSig(url):
	dig = hmac.new(b'BHqCzYg8BAmZ', msg='BHqCzYg8BAmZ' + url.lower(), digestmod=hashlib.sha256).digest()
	return url + "&apiSig=" + dig.encode('hex')

def simyopass():
	k = pyDes.triple_des("TFq2VBDo3BizNAcPEw1vB7i5", pyDes.ECB, "\0\0\0\0\0\0\0\0", pad=None, padmode=pyDes.PAD_PKCS5)
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

def api_request(url, data="", check=True):
	kPublicKey="1SCOPDqVeSPjTKy"

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

	if check==True:
		data = json.loads(result)['header']
		if int(data['code']) != 100:
			print "ERROR in request:\n" + str(url) + "\n"
			data = convert(data)
			pp = pprint.PrettyPrinter(indent=0)
			pp.pprint(data)
			sys.exit(1)

	return result

def api_logout():
	URL=BASE_URL+"/logout?sessionId=" + str(sessionId)
	result = api_request(URL,"",False)
	if VERBOSE: print result + "\n"

def api_login():
	global sessionId, customerId

	SIMYOPASS = simyopass()
	URL=BASE_URL+"/login?"
	data = "user=" + USERNAME + "&password=" + SIMYOPASS + "&apiSig=null"
	result = api_request(URL,data)
	if VERBOSE: print result + "\n"

	sessionId = json.loads(result)['response']['sessionId']
	customerId = json.loads(result)['response']['customerId']

def subscriptions():
	global registerDate, mainProductId, billCycleType, msisdn, subscriberId, payType

	URL=BASE_URL+"/subscriptions/" + str(customerId) + "?sessionId=" + str(sessionId)
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

def consumptionByCycle(billCycleCount=1):
	URL=BASE_URL+"/consumptionByCycle/" + str(customerId) + "?sessionId=" + str(sessionId) + "&msisdn=" + str(msisdn) + "&billCycleType=" + str(billCycleType) + "&registerDate=" + str(registerDate) + "&billCycle=" + str(billCycle) + "&billCycleCount=" + str(billCycleCount) + "&payType=" + str(payType)
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

def consumptionDetailByCycle(billCycleCount=1):
	URL=BASE_URL+"/consumptionDetailByCycle/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&billCycle=" + str(billCycle) + "&registerDate=" + str(registerDate) + "&billCycleCount=" + str(billCycleCount) + "&payType=" + str(payType)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	startDate=data['response']['consumptionDetailByCycleList'][0]['startDate']
	endDate=data['response']['consumptionDetailByCycleList'][0]['endDate']
	start = epoch2date(startDate)
	end = epoch2date(endDate)
	print "\nPeriodo de " + start + " a " + end + "\n"

	for day in data['response']['consumptionDetailByCycleList'][0]['consumptionsByDay']:
		date = epoch2date(day['date'])
		totalCharge = float(day['totalCharge'])
		print "{0} charge: {1}".format(date, totalCharge)

		# regular
		if 'voice' in day:
			hms = datetime.timedelta(seconds=day['voice']['count'])
			print "\tvoice: {0} ({1} EUR)".format (hms, float(day['voice']['chargeTotal']))
		else:
			print "\tvoice: 0:00:00 (0.0 EUR)"
		if 'sms' in day:
			print "\tsms: {0} ({1} EUR)".format (day['sms']['count'], float(day['sms']['chargeTotal']))
		else:
			print "\tsms: 0 (0.0 EUR)"
		if 'mms' in day:
			print "\tmms: {0} ({1} EUR)".format (day['mms']['count'], float(day['mms']['chargeTotal']))
		if 'data' in day:
			print "\tdata: {0:.2f} MB ({1} EUR)".format(day['data']['count']/1024.0/1024.0, float(day['data']['chargeTotal']))
		else:
			print "\tdata: 0 MB (0.0 EUR)"

		# premium
		if 'voicePremium' in day:
			hms = datetime.timedelta(seconds=day['voicePremium']['count'])
			print "\tPREMIUM voice: {0} ({1} EUR)".format (hms, float(day['voicePremium']['chargeTotal']))
		if 'smsPremium' in day:
			print "\tPREMIUM sms: {0} ({1} EUR)".format (day['smsPremium']['count'], float(day['smsPremium']['chargeTotal']))

		# roaming
		if 'voiceIngoingRoaming' in day:
			hms = datetime.timedelta(seconds=day['voiceIngoingRoaming']['count'])
			print "\tROAMING incoming voice: {0} ({1} EUR)".format (hms, float(day['voiceIngoingRoaming']['chargeTotal']))
		if 'voiceOutgoingRoaming' in day:
			hms = datetime.timedelta(seconds=day['voiceOutgoingRoaming']['count'])
			print "\tROAMING outgoing voice: {0} ({1} EUR)".format (hms, float(day['voiceOutgoingRoaming']['chargeTotal']))
		if 'smsRoaming' in day:
			print "\tROAMING sms: {0} ({1} EUR)".format (day['smsRoaming']['count'], float(day['smsRoaming']['chargeTotal']))
		if 'mmsRoaming' in day:
			print "\tROAMING mms: {0} ({1} EUR)".format (day['mmsRoaming']['count'], float(day['mmsRoaming']['chargeTotal']))
		if 'dataRoaming' in day:
			print "\tROAMING data: {0:.2f} MB ({1} EUR)".format(day['dataRoaming']['count']/1024.0/1024.0, float(day['dataRoaming']['chargeTotal']))


def frequentNumbers():
	month=billCycle # Parameter month is mandatory
	URL=BASE_URL+"/frequentNumbers/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&registerDate=" + str(registerDate) + "&month=" + str(month)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	print "msisdn\t\tcount"
	print "-----------\t-----"
	for num in data['response']['frequentNumbers']:
		print '{0}\t{1}'.format(num['msisdn'], num['count'])

def messages():
	start=1
	count=500
	URL=BASE_URL+"/messages/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&billCycle=" + str(billCycle) + "&registerDate=" + str(registerDate) + "&start=" + str(start) + "&count=" + str(count)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	startDate=data['response']['sms']['startDate']
	endDate=data['response']['sms']['endDate']
	start = epoch2date(startDate)
	end = epoch2date(endDate)
	print "\nPeriodo de " + start + " a " + end + "\n"

	print  "date			cost		duration	category	msisdn"
	print  "-------------------	--------	--------	--------	-----------"
	for sms in reversed(data['response']['sms']['messagesInfo']):
		date = epoch2date(sms['date'], '%d/%m/%Y %H:%M:%S')
		duration = datetime.timedelta(seconds=sms['duration'])
		print '{0}\t{1}\t{2}\t\t{3}\t\t{4}'.format(date, sms['charge'], duration, sms['category'], sms['msisdn'])
	print

def voiceCalls():
	start=1
	count=500
	URL=BASE_URL+"/voiceCalls/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&billCycle=" + str(billCycle) + "&registerDate=" + str(registerDate) + "&start=" + str(start) + "&count=" + str(count)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	data = json.loads(result)
	startDate=data['response']['voiceCalls']['startDate']
	endDate=data['response']['voiceCalls']['endDate']
	start = epoch2date(startDate)
	end = epoch2date(endDate)
	print "\nPeriodo de " + start + " a " + end + "\n"

	print  "date			type		duration	category	msisdn"
	print  "-------------------	--------	--------	--------	-----------"
	for call in reversed(data['response']['voiceCalls']['voiceCallInfo']):
		date = epoch2date(call['date'], '%d/%m/%Y %H:%M:%S')
		if call['type'] == 1:
			calltype="Outgoing"
		elif call['type'] == 2:
			calltype="Incoming"
		else:
			calltype=call['type']
		duration = datetime.timedelta(seconds=call['duration'])
		print '{0}\t{1}\t{2}\t\t{3}\t\t{4}'.format(date, calltype, duration, call['category'], call['msisdn'])
	print

def rechargeHistory():
	startDate=registerDate
	endDate = time()
	endDate = int(endDate) * 1000
	URL=BASE_URL+"/rechargeHistory/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&registerDate=" + str(registerDate) + "&startDate=" + str(startDate) + "&endDate=" + str(endDate)
	result = api_request(URL)
	if VERBOSE: print result + "\n"

	print "\nHistorico de regargas:\n"

	print 'date\t\t\t\tfee'
	print '-------------------\t\t----'
	data = json.loads(result)
	for recharge in data['response']['rechargeHistory']:
		date = epoch2date(recharge['date'], '%d/%m/%Y %H:%M:%S')
		fee = recharge['fee']
		print '{0}\t\t{1}'.format(date, fee)

def mgmHistory():
	URL=BASE_URL+"/mgmHistory/" + str(customerId) + "?sessionId=" + str(sessionId)
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
	URL=BASE_URL+"/invoiceList/" + str(customerId) + "?msisdn=" + str(msisdn) + "&sessionId=" + str(sessionId) + "&billCycleType=" + str(billCycleType) + "&registerDate=" + str(registerDate)
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

	URL=BASE_URL+"/downloadInvoice?sessionId=" + str (sessionId) + "&invoiceNO=" + str(invoiceNO) + "&invoiceId=" + str(invoiceId)
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
#https://api.simyo.es/api/contact
