<!---
*
* Copyright (C) 2005-2008 Razuna
*
* This file is part of Razuna - Enterprise Digital Asset Management.
*
* Razuna is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Razuna is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Affero Public License for more details.
*
* You should have received a copy of the GNU Affero Public License
* along with Razuna. If not, see <http://www.gnu.org/licenses/>.
*
* You may restribute this Program with a special exception to the terms
* and conditions of version 3.0 of the AGPL as described in Razuna's
* FLOSS exception. You should have received a copy of the FLOSS exception
* along with Razuna. If not, see <http://www.razuna.com/licenses/>.
*
--->
<cfoutput>
<cfcontent reset="true">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" dir="ltr" lang="en-US">
<head>
<title>Razuna Enterprise Digital Asset Management</title>
<meta http-equiv="content-type" content="text/html;charset=utf-8" />
<cfheader name="Expires" value="#GetHttpTimeString(Now())#">
<cfheader name="CACHE-CONTROL" value="NO-CACHE, no-store, must-revalidate">
<cfheader name="PRAGMA" value="#GetHttpTimeString(Now())#">
<script language="JavaScript" type="text/javascript">var dynpath = '#dynpath#';</script>
<cfif application.razuna.isp>
<!--- JS --->
<script src="//d3jcwo7gahoav9.cloudfront.net/razuna/js/jquery-1.6.4.min.js" type="text/javascript"></script>
<script src="//d3jcwo7gahoav9.cloudfront.net/razuna/js/jquery-ui-1.8.16.custom/js/jquery-ui-1.8.16.custom.min.js" type="text/javascript"></script>
<script type="text/javascript" src="//d3jcwo7gahoav9.cloudfront.net/razuna/js/flowplayer-3.2.6.min.js"></script>
<script type="text/javascript" src="//d3jcwo7gahoav9.cloudfront.net/razuna/js/AC_QuickTime.js"></script>
<script type="text/javascript" src="//d3jcwo7gahoav9.cloudfront.net/razuna/js/global.js"></script>
<!--- CSS --->
<link rel="stylesheet" type="text/css" href="//d3jcwo7gahoav9.cloudfront.net/razuna/css/main.css" />
<link rel="stylesheet" type="text/css" href="//d3jcwo7gahoav9.cloudfront.net/razuna/css/error.css" />
<link rel="stylesheet" type="text/css" href="//d3jcwo7gahoav9.cloudfront.net/razuna/css/multiple-instances.css" />
<link rel="stylesheet" type="text/css" href="//d3jcwo7gahoav9.cloudfront.net/razuna/js/jquery-ui-1.8.16.custom/css/smoothness/jquery-ui-1.8.16.custom.css" />
<cfelse>
<script type="text/javascript" src="#dynpath#/global/js/jquery-1.6.4.min.js"></script>
<script type="text/javascript" src="#dynpath#/global/js/jquery-ui-1.8.16.custom/js/jquery-ui-1.8.16.custom.min.js"></script>
<script type="text/javascript" src="#dynpath#/global/videoplayer/js/flowplayer-3.2.6.min.js"></script>
<script type="text/javascript" src="#dynpath#/global/js/AC_QuickTime.js"></script>
<script type="text/javascript" src="#dynpath#/global/host/dam/js/global.js"></script>
<link rel="stylesheet" type="text/css" href="#dynpath#/global/host/dam/views/layouts/main.css" />
<link rel="stylesheet" type="text/css" href="#dynpath#/global/host/dam/views/layouts/error.css" />
<link rel="stylesheet" type="text/css" href="#dynpath#/global/videoplayer/css/multiple-instances.css" />
<link rel="stylesheet" type="text/css" href="#dynpath#/global/js/jquery-ui-1.8.16.custom/css/smoothness/jquery-ui-1.8.16.custom.css" />
</cfif>
<link rel="SHORTCUT ICON" href="#dynpath#/global/host/dam/images/favicon.ico" />
<style>
##apDiv4 {
	position: absolute;
	left:20px;
	top:50px;
	height: auto;
	width: 95%;
	min-width: 680px;
	z-index:4;
	padding-left: 10px;
	padding-right: 10px;
	padding-bottom: 10px;
}
.ui-widget { font-family: Helvetica Neue,Helvetica,Arial,Nimbus Sans L,sans-serif; font-size: 12px; }
.ui-widget input, .ui-widget select, .ui-widget textarea, .ui-widget button { font-family: Helvetica Neue,Helvetica,Arial,Nimbus Sans L,sans-serif; font-size: 1em; }
</style>
</head>
<body>
<div id="container">
	<div id="apDiv1">#trim( headercontent )#</div>
	<!--- <div id="apDiv3">#trim( leftcontent )#</div> --->
	<div id="apDiv4">#trim( maincontent )#</div>
</div>
<div id="footer">#trim( footercontent )#</div>
<div id="thewindowcontent1" style="padding:10px;display:none;"></div>
<div id="thewindowcontent2" style="padding:10px;display:none;"></div>
</body>
</html>
<!--- JS: BASKET --->
<cfinclude template="../../js/basket.cfm">
</cfoutput>