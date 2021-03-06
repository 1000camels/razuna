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
	<form name="form0" id="form0" method="post" action="#self#">
	<input type="hidden" name="#theaction#" value="#xfa.batchdo#">
	<input type="hidden" name="langcount" value="#valuelist(qry_langs.lang_id)#">
	<input type="hidden" name="thepath" value="#thisPath#">
	<input type="hidden" name="what" value="#attributes.what#">
	<input type="hidden" name="file_id" value="#attributes.file_id#">
	<input type="hidden" name="file_ids" value="#session.thefileid#">
	<input type="hidden" name="folder_id" value="#attributes.folder_id#">
	<div id="tabs_batch">
		<ul>
			<li tabindex="0"><a href="##batch_desc">#defaultsObj.trans("asset_desc")#</a></li>
			<cfif attributes.what EQ "img" OR session.thefileid CONTAINS "-img">
				<li tabindex="1"><a href="##batch_xmp">XMP Description</a></li>
				<li tabindex="2"><a href="##iptc_contact">IPTC Contact</a></li>
				<li tabindex="3"><a href="##iptc_image">IPTC Image</a></li>
				<li tabindex="4"><a href="##iptc_content">IPTC Content</a></li>
				<li tabindex="5"><a href="##iptc_status">IPTC Status</a></li>
				<li tabindex="6"><a href="##iptc_origin">Origin</a></li>
			</cfif>
			<li tabindex="7"><a href="##batch_labels">#defaultsObj.trans("labels")#</a></li>
			<!--- <li tabindex="8"><a href="##batch_custom">#defaultsObj.trans("custom_fields_header")#</a></li> --->
		</ul>
		<!--- Descriptions & Keywords --->
		<div id="batch_desc">
			<table border="0" cellpadding="0" cellspacing="0" width="100%" class="grid">
				<cfloop query="qry_langs">
					<tr>
						<td class="td2" valign="top" width="1%" nowrap="true"><strong>#lang_name#: #defaultsObj.trans("description")#</strong></td>
						<td class="td2" width="100%"><textarea name="<cfif what EQ "doc">file<cfelseif what EQ "vid">vid<cfelseif what EQ "img">img<cfelseif what EQ "aud">aud<cfelseif what EQ "all">all</cfif>_desc_#lang_id#" class="text" rows="2" cols="50"<cfif attributes.what EQ "img"> onchange="javascript:document.form#attributes.file_id#.iptc_content_description_#lang_id#.value = document.form#attributes.file_id#.img_desc_#lang_id#.value"</cfif>></textarea></td>
					</tr>
					<tr>
						<td class="td2" valign="top" width="1%" nowrap="true"><strong>#lang_name#: #defaultsObj.trans("keywords")#</strong></td>
						<td class="td2" width="100%"><textarea name="<cfif what EQ "doc">file<cfelseif what EQ "vid">vid<cfelseif what EQ "img">img<cfelseif what EQ "aud">aud<cfelseif what EQ "all">all</cfif>_keywords_#lang_id#" class="text" rows="2" cols="50"<cfif attributes.what EQ "img"> onchange="javascript:document.form#attributes.file_id#.iptc_content_keywords_#lang_id#.value = document.form#attributes.file_id#.img_keywords_#lang_id#.value"</cfif>></textarea></td>
					</tr>
				</cfloop>
			</table>
		</div>
		<cfif attributes.what EQ "img" OR session.thefileid CONTAINS "-img">
			<!--- XMP Description --->
			<div id="batch_xmp">
				<cfinclude template="dsp_asset_images_xmp.cfm">
			</div>
			<!--- IPTC Contact --->
			<div id="iptc_contact">
				<cfinclude template="dsp_asset_images_iptc_contact.cfm">
			</div>
			<!--- IPTC Image --->
			<div id="iptc_image">
				<cfinclude template="dsp_asset_images_iptc_image.cfm">
			</div>
			<!--- IPTC Content --->
			<div id="iptc_content">
				<cfinclude template="dsp_asset_images_iptc_content.cfm">
			</div>
			<!--- IPTC Status --->
			<div id="iptc_status">
				<cfinclude template="dsp_asset_images_iptc_status.cfm">
			</div>
			<!--- Origin --->
			<div id="iptc_origin">
				<cfinclude template="dsp_asset_images_origin.cfm">
			</div>
		</cfif>
		<!--- Labels --->
		<div id="batch_labels" style="min-height:200px;">
			<strong>Choose #defaultsObj.trans("labels")#</strong><br />
			<select data-placeholder="Choose a label" class="chzn-select" style="width:311px;" name="labels" id="batch_labels" multiple="multiple">
				<option value=""></option>
				<cfloop query="qry_labels">
					<cfset l = replace(label_path," "," AND ","all")>
					<cfset l = replace(l,"/"," AND ","all")>
					<option value="#label_id#">#label_path#</option>
				</cfloop>
			</select>
		</div>
		<!--- Custom Fields --->
		<!--- <div id="batch_custom"></div> --->
	</div>
	<!--- Submit Button --->
	<div id="updatebatch" style="width:80%;float:left;padding:10px;color:green;font-weight:bold;display:none;"></div><div style="float:right;padding:10px;"><input type="submit" name="submit" value="#defaultsObj.trans("button_save")#" class="button"></div>
	</form>
	<!--- Activate the Tabs --->
	<script language="JavaScript" type="text/javascript">
		// Initialize Tabs
		jqtabs("tabs_batch");
		// Activate Chosen
		$(".chzn-select").chosen();
		// Submit Form
		$("##form0").submit(function(e){
			// Show
			$("##updatebatch").css("display","");
			$("##updatebatch").html('<img src="#dynpath#/global/host/dam/images/loading.gif" border="0" style="padding:10px;" width="16" height="16">');
			// Get values
			var url = formaction("form0");
			var items = formserialize("form0");
			// Submit Form
			$.ajax({
				type: "POST",
				url: url,
			   	data: items,
			   	success: function(){
			   		$("##updatebatch").html('#JSStringFormat(defaultsObj.trans("batch_done"))#');
					$("##updatebatch").animate({opacity: 1.0}, 3000).fadeTo("slow", 0.33);
			   	}
			});
			return false;
		})
	</script>
</cfoutput>