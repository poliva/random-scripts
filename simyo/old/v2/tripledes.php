<?

$key = "25d1d4cb0a08403e2acbcbe0f25a2";
$input = simyoize_password($argv[1]);
$str= encrypt($input,$key);
#echo "Start: $input\nEncrypted: $str\nDecrypted: ".decrypt($str,$key)."\n";
echo urlencode("$str\n")."\n";

function simyoize_password($input) {
	$binarydata = pack("C*", 0x8);
	for ($i=0;$i<8;$i++) {
		$input.=$binarydata;
	}
	return "$input";
}

function encrypt($input,$key) {
	$cipher = mcrypt_module_open(MCRYPT_TRIPLEDES,'','ecb','');
        $iv = mcrypt_create_iv(mcrypt_enc_get_iv_size($cipher), MCRYPT_RAND);
    	$key = substr($key, 0, mcrypt_enc_get_key_size($cipher));
	mcrypt_generic_init($cipher, $key, $iv);
	$decrypted = mcrypt_generic($cipher,$input);
	mcrypt_generic_deinit($cipher);
	return base64_encode($decrypted);
}

function decrypt($encrypted_text,$key){
	$cipher = mcrypt_module_open(MCRYPT_TRIPLEDES,'','ecb','');
        $iv = mcrypt_create_iv(mcrypt_enc_get_iv_size($cipher), MCRYPT_RAND);
    	$key = substr($key, 0, mcrypt_enc_get_key_size($cipher));
	mcrypt_generic_init($cipher, $key, $iv);
	$decrypted = mdecrypt_generic($cipher,base64_decode(urldecode($encrypted_text)));
	mcrypt_generic_deinit($cipher);
	return $decrypted;
}

?>
