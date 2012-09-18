#!/usr/bin/php
<?
error_reporting(0);

$rp=$argv[1];
$money=$argv[2];
$infile=$argv[3];

echo "\nQuick-n-dirty 'Drag Racing' save.dat file patcher (needs root!)\n";
echo "(c)2011 Pau Oliva - pof[@]eslack[.]org\n\n";
echo " > Respect Points increased to: 65535\n";
echo " > Money increased to: 16777215\n\n";

if (!is_numeric($rp) || !is_numeric($money)) {
	echo "USAGE: ".$argv[0]." <respect-points> <money> [save.dat]\n\n";
	echo "EXAMPLE: if you have 300 respect points and $15000\n";
	echo "\t$ adb pull /data/data/com.creativemobile.DragRacing/files/save.dat\n";
	echo "\t$ ".$argv[0]." 300 15000\n";
	echo "\t$ adb push save-patched.dat /data/data/com.creativemobile.DragRacing/files/save.dat\n";
	echo "\t$ adb push save-patched.dat /data/data/com.creativemobile.DragRacing/files/save2.dat\n\n";
	exit;
}

// if no infile specified, use "save.dat" by default
if ($infile=="") $infile="save.dat";
$in=file($infile) || die ("ERROR: Could not open '$infile'\n");;

// convert respect points and money to its hex values
$hrp=dechex($rp);
$hmoney=dechex($money);

// base64 decode the input file
$input=$in[0];
$out=base64_decode($input);

// make sure all bytes are represented with 2 ascii chars, add 0 at the begining otherwise
if ((strlen($hrp) % 2) != 0) $hrp="0".$hrp;
if ((strlen($hmoney) % 2) != 0) $hmoney="0".$hmoney;


// print original file and find positions
echo "\n==== ORIGINAL ===";
$countmoney=0;
$countrp=0;
$posmoney=0;
$posrp=0;
$n=0;
for ($i=0;$i<strlen($out);$i++) {

	if ($n % 10 == 0) echo "\n";
	$n++;

	$cur = dechex(ord($out[$i]));
	if (strlen($cur) == 1) $cur="0".$cur;
	echo " $cur ";

	// find money position
	if ($cur == $hmoney[0].$hmoney[1]) {
		$cur2 = dechex(ord($out[$i+1]));
		if ($cur2 == $hmoney[2].$hmoney[3]) {
			$countmoney++;
			$posmoney=$i;
		}
	}

	// find respect points position
	if ($cur == $hrp[0].$hrp[1]) {
		$cur2 = dechex(ord($out[$i+1]));
		if ($cur2 == $hrp[2].$hrp[3]) {
			$countrp++;
			$posrp=$i;
		}
	}

}

echo "\n\nMoney position: $posmoney\n";
echo "Respect Points position: $posrp\n";

if ($countmoney!=1) die("ERROR: money value\n");
if ($countrp!=1) die("ERROR: respect points value\n");

// distance between respect points and money should be 5, if its less, we have a lower value and must adjust.
$distance=$posrp-$posmoney;
if ($distance < 5) $posmoney--;

$distance=$posrp-$posmoney;
echo "Distance: $distance\n";
if ($distance!=5) die("ERROR: distance value != 5\n");


// generate the patched output
echo "\n==== PATCHED ===";
$newbin="";
$n=0;
for ($i=0;$i<strlen($out);$i++) {

	$cur = dechex(ord($out[$i]));
	if (strlen($cur) == 1) $cur="0".$cur;

	// patch money value (3 bytes)
	if ($i == $posmoney) {
		$newbin.=chr(0xff);
		if ($n % 10 == 0) echo "\n";
		$n++;
		echo "[ff]";

		$newbin.=chr(0xff);
		if ($n % 10 == 0) echo "\n";
		$n++;
		echo "[ff]";

		$newbin.=chr(0xff);
		if ($n % 10 == 0) echo "\n";
		$n++;
		echo "[ff]";

		$i = $i+2;
	}

	// patch respect points value (2 bytes)
	elseif ($i == $posrp) {
		$newbin.=chr(0xff);
		if ($n % 10 == 0) echo "\n";
		$n++;
		echo "[ff]";

		$newbin.=chr(0xff);
		if ($n % 10 == 0) echo "\n";
		$n++;
		echo "[ff]";

		$i++;
	}

	else {
		$newbin.=$out[$i];
		if ($n % 10 == 0) echo "\n";
		$n++;
		echo " $cur ";
	}

}
echo "\n";


// write the patched file
$log=base64_encode($newbin);
$fh = fopen("save-patched.dat", 'wb');
fwrite($fh, $log);
fclose($fh);
echo "Output: save-patched.dat\n";

?>
