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
	<div id="tab_addassets">
		<ul>
			<li><a href="##addsingle" onclick="loadcontent('addsingle','#myself##xfa.addsingle#&folder_id=#folder_id#');">#defaultsObj.trans("header_add_asset")#</a></li>
			<cfif !application.razuna.isp AND !application.razuna.custom.enabled OR (application.razuna.custom.enabled AND application.razuna.custom.tab_add_from_server)>
				<li><a href="##addserver">#defaultsObj.trans("header_add_asset_server")#</a></li>
			</cfif>
			<cfif !application.razuna.custom.enabled OR (application.razuna.custom.enabled AND application.razuna.custom.tab_add_from_email)>
				<li><a href="##addemail" onclick="loadcontent('addemail','#myself##xfa.addemail#&folder_id=#folder_id#');">#defaultsObj.trans("header_add_asset_email")#</a></li>
			</cfif>
			<cfif !application.razuna.custom.enabled OR (application.razuna.custom.enabled AND application.razuna.custom.tab_add_from_ftp)>
				<li><a href="##addftp" onclick="loadcontent('addftp','#myself##xfa.addftp#&folder_id=#folder_id#');">#defaultsObj.trans("header_add_asset_ftp")#</a></li>
			</cfif>
			<cfif !application.razuna.custom.enabled OR (application.razuna.custom.enabled AND application.razuna.custom.tab_add_from_link)>
				<li><a href="##addlink" onclick="loadcontent('addlink','#myself##xfa.addlink#&folder_id=#folder_id#');">#defaultsObj.trans("link_tab_header")#</a></li>
			</cfif>
		</ul>
		<div id="addsingle" style="padding:0px;margin:0px;">#defaultsObj.loadinggif("#dynpath#")#</div>
		<cfif !application.razuna.isp AND !application.razuna.custom.enabled OR (application.razuna.custom.enabled AND application.razuna.custom.tab_add_from_server)>
			<div id="addserver">
				<p><a href="##" onclick="showwindow('#myself##xfa.addserver#&folder_id=#folder_id#','#defaultsObj.trans("header_add_asset_server")#',800,2);">#defaultsObj.trans("import_from_folder")#</a> #defaultsObj.trans("import_from_folder_custom")#.</p>
				<p>
					<strong>#defaultsObj.trans("link_folder_path_header")#</strong><br />
					<input type="text" style="width:400px;" id="folder_path" /> <input type="button" value="#defaultsObj.trans("validate")#" onclick="importfoldercheck();" class="button" /><br /><span style="color:red;">#defaultsObj.trans("import_from_folder_foreign")#</span><br /><div id="path_validate"></div>
				</p>
				<p>
					#defaultsObj.trans("import_from_folder_desc")#
				</p>
				<p>
					<input type="button" value="#defaultsObj.trans("import_from_folder_button")#" onclick="importpath();" class="button" />
				</p>
			</div>
		</cfif>
		<cfif !application.razuna.custom.enabled OR (application.razuna.custom.enabled AND application.razuna.custom.tab_add_from_email)><div id="addemail">#defaultsObj.loadinggif("#dynpath#")#</div></cfif>
		<cfif !application.razuna.custom.enabled OR (application.razuna.custom.enabled AND application.razuna.custom.tab_add_from_ftp)><div id="addftp">#defaultsObj.loadinggif("#dynpath#")#</div></cfif>
		<cfif !application.razuna.custom.enabled OR (application.razuna.custom.enabled AND application.razuna.custom.tab_add_from_link)><div id="addlink">#defaultsObj.loadinggif("#dynpath#")#</div></cfif>
	</div>
	<!--- Activate the Tabs --->
<script language="JavaScript" type="text/javascript">
	jqtabs("tab_addassets");
	$("##tab_addassets").tabs('select', 0);
	loadcontent('addsingle','#myself##xfa.addsingle#&folder_id=#folder_id#');
	// Check folder path
	function importfoldercheck(){
		// Check link
		loadcontent('path_validate','#myself#c.folder_link_check&link_path=' + escape($('##folder_path').val()));
	}
	// Submit path
	function importpath(){
		// Get path
		var p = $('##folder_path').val();
		// Open window
		window.open('#myself#c.asset_add_path&theid=#attributes.folder_id#&folder_path=' + p);
	}
</script>
</cfoutput>