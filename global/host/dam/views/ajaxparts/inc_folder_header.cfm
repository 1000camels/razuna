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
<cfif session.theuserid NEQ qry_user.folder_owner>
	<div style="font-weight:normal;font-style:italic;padding-left:2px">The user "#qry_user.user#" shared this folder with you. Your permission is: <cfif session.folderaccess EQ "R">Read only<cfelseif session.folderaccess EQ "W">Read & Write<cfelse>No Restrictions</cfif></div>
	<br />
</cfif>
<div style="float:left;padding-left:2px;padding-top:5px;">#qry_filecount.thetotal# file(s) in here | <cfloop list="#qry_breadcrumb#" delimiters=";" index="i">/<a href="##" onclick="$.tree.focused().open_branch('###ListGetAt(i,3,"|")#');$.tree.focused().select_branch('###ListGetAt(i,2,"|")#');loadcontent('rightside','#myself#c.folder&folder_id=#ListGetAt(i,2,"|")#');">#ListGetAt(i,1,"|")#</a></cfloop></div>
</cfoutput>