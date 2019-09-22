<b>SIMYO.ES API NOTES:</b>
(reverse engineered from the <a href="https://play.google.com/store/apps/details?id=com.simyo">com.simyo</a> mobile app)

- The password used by the API is your Simyo password encripted using
TripleDES with this key: `TFq2VBDo3BizNAcPEw1vB7i5` 

- All requests to the API have a signature which is sent in the parameter
"`apiSig=xxxx`", this signature is calculated like this:
  1. convert to lowercase the complete request URL except the apiSig
parameter 
  2. concatenate the string "`BHqCzYg8BAmZ`" + the lowercased URL
  3. the signature is obtained by computing the HMAC-SHA256 hash of the
string obtained in the previous step, using the key "`BHqCzYg8BAmZ`".

- All api requests need the parameter "`publicKey=xxxx`", the value of
this public key is: `1SCOPDqVeSPjTKy`

The rest is a piece of cake, make the request and parse the received
json response.

<b>SAMPLE COMMAND LINE APPLICATION:</b>

Usage:
<pre>
pau@maco:~/simyo$ ./simyo.py -h
usage: simyo.py [-h] [-v] [-c] [-y] [-l] [-s] [-g] [-o] [-e] [-r] [-f]
                [-b BILLCYCLE] [-m MSISDN] [-d INVOICE_ID]

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         verbose mode
  -c, --bycycle         show consumption detail by billing cycle (default)
  -y, --byday           show consumption detail by day
  -l, --listinvoice     list all downloadable invoices
  -s, --showmsisdn      list the msisdns available in the account
  -g, --mgm             show member-get-member history
  -o, --voicecalls      show voice call records
  -e, --messages        show sms records
  -r, --recharge        show recharge history
  -f, --frequent        show frequent numbers
  -b BILLCYCLE, --billcycle BILLCYCLE
                        specify the billing cycle (from 1 to 6), default=1
  -m MSISDN, --msisdn MSISDN
                        specify the msisdn if you have more than 1 line
  -d INVOICE_ID, --download INVOICE_ID
                        download invoice specified by INVOICE_ID
</pre>

Current billing cycle:
<pre>
pau@maco:~/simyo$ ./simyo.py

Periodo de 01/09/2013 a 30/09/2013

Llamadas: 0:27:10 (1.5941 EUR)
SMS: 0 (0.0 EUR)
Datos: 336.61 MB (0.0 EUR)

Datos Roaming: 15.55 MB (8.4608 EUR)

Consumo total: 10.0549 EUR
</pre>

List invoices:
<pre>
pau@maco:~/simyo$ ./simyo.py -l
Factura 2010813-00037922 (id=H2013081014623847) del 01/08/2013 al 31/08/2013
Factura 2010713-00034044 (id=H2013071014073781) del 01/07/2013 al 31/07/2013
Factura 2010613-00032410 (id=H2013061013549461) del 01/06/2013 al 30/06/2013
Factura 2010513-00032987 (id=H2013051012990184) del 01/05/2013 al 31/05/2013
Factura 2010413-00032133 (id=H2013041012458163) del 01/04/2013 al 30/04/2013
</pre>

Download invoice:
<pre>
pau@maco:~/simyo$ ./simyo.py -d H2013071014073781
File: factura_12345_1984119_2010713-00034044_010912.pdf
</pre>

<b>INSTALL:</b>

On Ubuntu/Debian systems, you need to install the required dependencies first:
<pre>
$ sudo apt-get install python-pip python-argparse
$ sudo pip install pyDes
</pre>
