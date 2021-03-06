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
<cfcomponent output="false" extends="authentication">
	
	<!--- Set Values --->
	<cfset application.razuna.thedatabase = application.razuna.api.thedatabase>
	<cfset application.razuna.datasource = application.razuna.api.dsn>
	<cfset application.razuna.storage = application.razuna.api.storage>
	
	<!--- Get all custom fields --->
	<cffunction name="getall" access="remote" output="false" returntype="query" returnformat="json">
		<cfargument name="api_key" required="true">
		<!--- Check key --->
		<cfset thesession = checkdb(arguments.api_key)>
		<!--- Check to see if session is valid --->
		<cfif thesession>
			<!--- Set values --->
			<cfset session.hostdbprefix = application.razuna.api.prefix["#arguments.api_key#"]>
			<cfset session.hostid = application.razuna.api.hostid["#arguments.api_key#"]>
			<cfset session.theuserid = application.razuna.api.userid["#arguments.api_key#"]>
			<!--- Call internal --->
			<cfinvoke component="global.cfc.custom_fields" method="get" returnVariable="qry">
			<!--- QoQ --->
			<cfquery dbtype="query" name="thexml">
			SELECT cf_id id, cf_type type, cf_enabled enabled, cf_show show, cf_text text
			FROM qry
			</cfquery>
		<!--- No session found --->
		<cfelse>
			<cfinvoke component="authentication" method="timeout" returnvariable="thexml">
		</cfif>
		<!--- Return --->
		<cfreturn thexml>
	</cffunction>
		
	<!--- Add custom field --->
	<cffunction name="setfield" access="remote" output="false" returntype="struct" returnformat="json">
		<cfargument name="api_key" required="true">
		<cfargument name="field_text" required="true">
		<cfargument name="field_type" required="true">
		<cfargument name="field_show" required="false" default="all">
		<cfargument name="field_enabled" required="false" default="t">
		<cfargument name="field_select_list" required="false" default="">
		<!--- Check key --->
		<cfset thesession = checkdb(arguments.api_key)>
		<!--- Check to see if session is valid --->
		<cfif thesession>
			<!--- Set Values --->
			<cfset session.hostdbprefix = application.razuna.api.prefix["#arguments.api_key#"]>
			<cfset session.hostid = application.razuna.api.hostid["#arguments.api_key#"]>
			<cfset session.theuserid = application.razuna.api.userid["#arguments.api_key#"]>
			<!--- Set Arguments --->
			<cfset arguments.thestruct.langcount = 1>
			<cfset arguments.thestruct.cf_text_1 = arguments.field_text>
			<cfset arguments.thestruct.cf_type = arguments.field_type>
			<cfset arguments.thestruct.cf_enabled = arguments.field_enabled>
			<cfset arguments.thestruct.cf_show = arguments.field_show>
			<cfset arguments.thestruct.cf_select_list = arguments.field_select_list>
			<!--- call internal method --->
			<cfinvoke component="global.cfc.custom_fields" method="add" thestruct="#arguments.thestruct#" returnVariable="theid">
			<!--- Return --->
			<cfset thexml.responsecode = 0>
			<cfset thexml.message = "Custom field successfully added">
			<cfset thexml.field_id = theid>
		<!--- No session found --->
		<cfelse>
			<cfinvoke component="authentication" method="timeout" type="s" returnvariable="thexml">
		</cfif>
		<!--- Return --->
		<cfreturn thexml>
	</cffunction>
				
	<!--- get custom fields from asset --->
	<cffunction name="getfieldsofasset" access="remote" output="false" returntype="query" returnformat="json">
		<cfargument name="api_key" required="true">
		<cfargument name="asset_id" required="true">
		<cfargument name="lang_id" required="false" default="1">
		<!--- Check key --->
		<cfset thesession = checkdb(arguments.api_key)>
		<!--- Check to see if session is valid --->
		<cfif thesession>
			<cfquery datasource="#application.razuna.api.dsn#" name="thexml">
			SELECT ct.cf_id_r field_id, ct.cf_text field_text, cv.cf_value field_value
			FROM #application.razuna.api.prefix["#arguments.api_key#"]#custom_fields_text ct, #application.razuna.api.prefix["#arguments.api_key#"]#custom_fields c, #application.razuna.api.prefix["#arguments.api_key#"]#custom_fields_values cv
			WHERE cv.asset_id_r IN (<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.asset_id#" list="Yes">)
			AND ct.cf_id_r = cv.cf_id_r
			AND ct.lang_id_r = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.lang_id#">
			AND c.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#application.razuna.api.hostid["#arguments.api_key#"]#">
			GROUP BY cv.cf_value, ct.cf_text
			ORDER BY c.cf_order
			</cfquery>
		<!--- No session found --->
		<cfelse>
			<cfinvoke component="authentication" method="timeout" returnvariable="thexml">
		</cfif>
		<!--- Return --->
		<cfreturn thexml>
	</cffunction>
	
</cfcomponent>