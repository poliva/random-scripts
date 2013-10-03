<b>SIMYO.ES API NOTES:</b>
(reverse engineered from the <a href="https://play.google.com/store/apps/details?id=com.simyo">com.simyo</a> mobile app)

- The password used by the API is not the same as your Simyo password:
you need to encrypt it using TripleDES with this key: 
`25d1d4cb0a08403e2acbcbe0f25a2` and if your passord has less than 16
characters, then you need to add padding using the byte `0x08` (`\b`).
Sample functions to encrypt/decrypt the password are in "`tripledes.php`"

- All requests to the API have a signature which is sent in the parameter
"`apiSig=xxxx`", this signature is calculated like this:
  1. convert to lowercase the complete request URL except the apiSig
parameter 
  2. concatenate the string "`f25a2s1m10`" + the lowercased URL
  3. the signature is obtained by computing the HMAC-SHA256 hash of the
string obtained in the previous step, using the key "`f25a2s1m10`".

- All api requests need the parameter "`publicKey=xxxx`", the value of
this public key is: `a654fb77dc654a17f65f979ba8794c34`

The rest is a piece of cake, make the request and parse the received
json response.

<b>SAMPLE COMMAND LINE APPLICATION:</b>

Usage:
<pre>
pau@maco:~/simyo$ ./simyo.sh -h
Usage: ./simyo.sh [-h|-v|-b num|-l|-d id]
    -h     : show this help
    -v     : verbose mode
    -b num : bill cycle (from 1 to 6)
    -l     : invoice list
    -d id  : download invoice
</pre>

Current billing cycle:
<pre>
pau@maco:~/simyo$ ./simyo.sh

Periodo de 01/09/13 a 30/09/13

Llamadas: 27m 10s (1.594118 EUR)
SMS: 0 (0.000000 EUR)
Datos: 336.61 MB (0.000000 EUR)

Datos Roaming: 15.55 MB (8.460800 EUR)

Consumo total: 10.054918 EUR
</pre>

List invoices:
<pre>
pau@maco:~/simyo$ ./simyo.sh -l
Factura 2010813-00037922 (id=H2013081014623847) del 01/08/13 al 31/08/13
Factura 2010713-00034044 (id=H2013071014073781) del 01/07/13 al 31/07/13
Factura 2010613-00032410 (id=H2013061013549461) del 01/06/13 al 30/06/13
Factura 2010513-00032987 (id=H2013051012990184) del 01/05/13 al 31/05/13
Factura 2010413-00032133 (id=H2013041012458163) del 01/04/13 al 30/04/13
</pre>

Download invoice:
<pre>
pau@maco:~/simyo$ ./simyo.sh -d H2013071014073781
File: factura_12345_1984119_2010713-00034044_010912.pdf
</pre>
