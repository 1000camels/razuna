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
<!--- 
Page output starts here
 --->
<cfoutput>
<div id="login_div">
	<span class="loginform_header">
		<cfif fileexists("#ExpandPath("../..")#global/host/logo/#session.hostid#/logo.jpg")>
			<img src="#dynpath#/global/host/logo/#session.hostid#/logo.jpg" border="0" />
		<cfelse>
			<img src="#dynpath#/global/host/dam/images/razuna_logo-200.png" width="200" height="29" border="0" style="padding:3px 0px 0px 5px;">
		</cfif>
	</span>
	<cfif attributes.shared EQ "T">
		<br />
		<span class="loginform_header">#defaultsObj.trans("share_header_login")#</span>
		<br />
		<br />
		<form action="#self#" method="post" name="form_login_<cfif attributes.wid EQ 0>share<cfelse>widget</cfif>" id="form_login_<cfif attributes.wid EQ 0>share<cfelse>widget</cfif>">
		<input type="hidden" name="#theaction#" value="#xfa.submitform#">
		<input type="hidden" name="fid" value="#attributes.fid#">
		<input type="hidden" name="wid" value="#attributes.wid#">
		<table width="100%" border="0" cellpadding="0" cellspacing="0">
		    <!--- If this is a normal group access login --->
		    <cfif attributes.perm_password EQ "F">
			    <tr>
			        <td width="100%" nowrap>#defaultsObj.trans("username")#</td>
				</tr>
				<tr>
					<td width="100%" nowrap style="padding-bottom:10px;">
						<label for="name" class="error">Enter a username!</label>
			       	 	<div id="login_name"><input type="text" name="name" id="name" size="30" /></div>
					</td>
			    </tr>
			    <tr>
			        <td>#defaultsObj.trans("password")#</td>
				</tr>
				<tr>
			        <td>
				        <label for="pass" class="error">Enter a password!</label>
				    	<div id="login_password"><input type="password" name="pass" id="pass" size="30" /></div>
					</td>
			    </tr>
			    <tr>
			        <td align="right" style="padding-bottom:10px;padding-top:10px;"><input type="submit" name="submitbutton" value="#defaultsObj.trans("button_login")#" class="button" /></td>
			    </tr>
				<cfif qry_langs.recordcount NEQ 1 AND attributes.wid EQ 0>
					<tr>
				        <td align="right" style="padding-bottom:10px;">
							<select name="app_lang" onChange="javascript:changelang('form_login_share');">
								<option value="javascript:void();" selected>#defaultsObj.trans("changelang")#</option>
								<cfloop query="qry_langs">
								<option value="#myself##xfa.switchlang#&thelang=#lang_name#&to=share">#lang_name#</option>
								</cfloop>
							</select>
						</td>
				    </tr>
				</cfif>
		   	<!--- This is protected with a normal password --->
		   	<cfelse>
		   		<tr>
			        <td width="100%" colspan="2" style="padding-bottom:15px;">#defaultsObj.trans("widget_password")#</td>
				</tr>
				<tr>
					<td valign="top">#defaultsObj.trans("password")#</td>
				</tr>
				<tr>
			        <td>
				    	<div id="login_password"><input type="password" name="pass" id="pass" size="30" /></div>
				    	<label for="pass" class="error">Enter the password!</label>
					</td>
			    </tr>
			    <tr>
			        <td colspan="2" align="right" style="padding-bottom:10px;padding-top:10px;"><input type="submit" name="submitbutton" value="#defaultsObj.trans("button_login")#" class="button" /></td>
			    </tr>
		   	</cfif>
		</table>
		</form>
	<cfelse>
		<table width="100%" border="0" cellpadding="0" cellspacing="0">
		    <tr>
		        <td width="100%">#defaultsObj.trans("share_error_nothing")#</td>
			</tr>
		</table>
	</cfif>
</div>
<div id="login_loading"></div>
<cfif structkeyexists(attributes,"le")>
<div id="alertbox" style="padding-top:10px;" class="alert">#defaultsObj.trans("login_error")#</div>
</cfif>
<cfif structkeyexists(attributes,"se")>
<div id="alertgroupbox" style="padding-top:10px;" class="alert">#defaultsObj.trans("share_error_group")#</div>
</cfif>
</cfoutput>


