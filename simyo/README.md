<b>SIMYO.ES API NOTES:</b>

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

