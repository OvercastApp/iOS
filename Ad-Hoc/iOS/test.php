<?php

$ipas = glob('*.ipa');
$provisioningProfiles = glob('*.mobileprovision');
$plists = glob('*.plist');

$sr = stristr( $_SERVER['SCRIPT_URI'], '.php' ) === false ? 
    $_SERVER['SCRIPT_URI'] : dirname($_SERVER['SCRIPT_URI']) . '/';
$provisioningProfile = $sr . $provisioningProfiles[0];
$ipa = $sr . $ipas[0];
$itmsUrl = urlencode( $sr . 'index.php?plist=' . str_replace( '.plist', '', $plists[0] ) );


if ($_GET['plist']) {
    $plist = file_get_contents( dirname(__FILE__) 
        . DIRECTORY_SEPARATOR 
        . preg_replace( '/![A-Za-z0-9-_]/i', '', $_GET['plist']) . '.plist' );
    $plist = str_replace('Applications/Overcast.app', $ipa, $plist);
    header('content-type: application/xml');
    echo $plist;
    die();
}


?><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>Install iOS App</title>
<style type="text/css">

li {
    padding: 1em;
}

</style>
<!-- Art Direction Styles -->

</head>
<body>
<ul>
    <li><a href="<? echo $provisioningProfile; ?>">Install Team Provisioning File</a></li>
    <li><a href="itms-services://?action=download-manifest&url=<? echo $itmsUrl; ?>">
         Install Application</a></li>
</ul>
</body>
</html>