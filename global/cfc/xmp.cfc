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
<cfcomponent extends="extQueryCaching">

<!--- Read XMP DB --->
<cffunction name="readxmpdb" output="false">
	<cfargument name="thestruct" type="struct">
		<cfquery datasource="#application.razuna.datasource#" name="xmp">
		SELECT 
		subjectcode iptcsubjectcode, 
		creator, 
		title, 
		authorsposition authorstitle, 
		captionwriter descwriter, 
		ciadrextadr iptcaddress, 
		category, 
		supplementalcategories categorysub, 
		urgency, 
		description, 
		ciadrcity iptccity, 
		ciadrctry iptccountry, 
		location iptclocation, 
		ciadrpcode iptczip, 
		ciemailwork iptcemail, 
		ciurlwork iptcwebsite, 
		citelwork iptcphone, 
		intellectualgenre iptcintelgenre, 
		instructions iptcinstructions, 
		source iptcsource, 
		usageterms iptcusageterms, 
		copyrightstatus copystatus, 
		transmissionreference iptcjobidentifier, 
		webstatement copyurl, 
		headline iptcheadline, 
		datecreated iptcdatecreated, 
		city iptcimagecity, 
		ciadrregion iptcimagestate, 
		country iptcimagecountry, 
		countrycode iptcimagecountrycode, 
		scene iptcscene, 
		state iptcstate, 
		credit iptccredit, 
		rights copynotice,
		colorspace,
		xres,
		yres,
		resunit
		FROM #session.hostdbprefix#xmp
		WHERE id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.file_id#">
		AND asset_type = <cfqueryparam cfsqltype="cf_sql_varchar" value="img">
		AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
		</cfquery>
	<cfreturn xmp>
</cffunction>

<!--- For writing the XMP below but in a cfthread --->
<cffunction name="xmpwritethread" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Params --->
	<cfset arguments.thestruct.database = variables.database>
	<cfset arguments.thestruct.dsn = variables.dsn>
	<cfset arguments.thestruct.hostid = session.hostid>
	<cfset arguments.thestruct.theschema = application.razuna.theschema>
	<cfset arguments.thestruct.storage = application.razuna.storage>
	<!--- Loop over the file_id (important when working on more then one image) --->
	<cfloop list="#arguments.thestruct.file_id#" delimiters="," index="i">
		<cfset arguments.thestruct.file_id = i>
		<cfset arguments.thestruct.newid = i>
		<!--- <cfinvoke method="xmpwrite" thestruct="#arguments.thestruct#" /> --->
		<cfthread intstruct="#arguments.thestruct#">
			<cfinvoke method="xmpwrite" thestruct="#attributes.intstruct#" />
		</cfthread>
	</cfloop>
</cffunction>

<!--- Write the XMP XML to the filesystem --->
<cffunction name="xmpwrite" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Param --->
	<cfparam default="F" name="arguments.thestruct.frombatch">
	<!--- The tool paths --->
	<cfinvoke component="settings" method="get_tools" returnVariable="arguments.thestruct.thetools" />
	<!--- Thread --->
	<cfthread name="trwritexmp#arguments.thestruct.file_id#" intstruct="#arguments.thestruct#">
		<!--- Get the original filename --->
		<cfquery datasource="#attributes.intstruct.dsn#" name="qryfilenameorg">
		SELECT img_filename_org, folder_id_r, img_extension, link_kind, link_path_url, lucene_key, path_to_asset
		FROM #session.hostdbprefix#images
		WHERE img_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attributes.intstruct.file_id#">
		AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
		</cfquery>
		<!--- Assign link_kind --->
		<cfset attributes.intstruct.qrydetail = qryfilenameorg>
		<cfset attributes.intstruct.link_kind = qryfilenameorg.link_kind>
		<cfset attributes.intstruct.qryfile.filename = qryfilenameorg.img_filename_org>
		<cfset attributes.intstruct.qrydetail.lucene_key = qryfilenameorg.lucene_key>
		<cfset attributes.intstruct.qrydetail.path_to_asset = qryfilenameorg.path_to_asset>
		<!--- If the extension is JPG OR JPEG --->
		<!--- <cfif qryfilenameorg.img_extension EQ "JPG" OR qryfilenameorg.img_extension EQ "JPEG"> --->
		<cfset attributes.intstruct.filenameorg = qryfilenameorg.img_filename_org>
		<cfset attributes.intstruct.qryfile.folder_id = qryfilenameorg.folder_id_r>
		<cfset attributes.intstruct.qrydetail.folder_id_r = qryfilenameorg.folder_id_r>
		<cfset attributes.intstruct.qrydetail.filenameorg = qryfilenameorg.img_filename_org>
		<cfset attributes.intstruct.qryfile.path = "#attributes.intstruct.assetpath#/#attributes.intstruct.hostid#/#qryfilenameorg.path_to_asset#">
		<cfset attributes.intstruct.path_to_asset = qryfilenameorg.path_to_asset>
		<cfif qryfilenameorg.link_kind EQ "lan">
			<cfset attributes.intstruct.thesource = qryfilenameorg.link_path_url>
		<cfelse>
			<cfset attributes.intstruct.thesource = "#attributes.intstruct.assetpath#/#attributes.intstruct.hostid#/#qryfilenameorg.path_to_asset#/#qryfilenameorg.img_filename_org#">
		</cfif>
		<!--- Start --->
		<cfif attributes.intstruct.frombatch EQ "F">
			<!--- Normal save behaviour --->
			<!--- Declare all variables or else you will get errors in the page --->
			<cfparam default="" name="attributes.intstruct.xmp_document_title">
			<cfparam default="" name="attributes.intstruct.xmp_author">
			<cfparam default="" name="attributes.intstruct.xmp_author_title">
			<cfparam default="" name="attributes.intstruct.xmp_description">
			<cfparam default="" name="attributes.intstruct.xmp_keywords">
			<cfparam default="" name="attributes.intstruct.xmp_description_writer">
			<cfparam default="" name="attributes.intstruct.xmp_copyright_status">
			<cfparam default="" name="attributes.intstruct.xmp_copyright_notice">
			<cfparam default="" name="attributes.intstruct.xmp_copyright_info_url">
			<cfparam default="" name="attributes.intstruct.xmp_category">
			<cfparam default="" name="attributes.intstruct.xmp_supplemental_categories">
			<cfparam default="" name="attributes.intstruct.iptc_contact_address">
			<cfparam default="" name="attributes.intstruct.iptc_contact_city">
			<cfparam default="" name="attributes.intstruct.iptc_contact_state_province">
			<cfparam default="" name="attributes.intstruct.iptc_contact_postal_code">
			<cfparam default="" name="attributes.intstruct.iptc_contact_country">
			<cfparam default="" name="attributes.intstruct.iptc_contact_phones">
			<cfparam default="" name="attributes.intstruct.iptc_contact_emails">
			<cfparam default="" name="attributes.intstruct.iptc_contact_websites">
			<cfparam default="" name="attributes.intstruct.iptc_content_headline">
			<cfparam default="" name="attributes.intstruct.iptc_content_subject_code">
			<cfparam default="" name="attributes.intstruct.iptc_date_created">
			<cfparam default="" name="attributes.intstruct.iptc_intellectual_genre">
			<cfparam default="" name="attributes.intstruct.iptc_scene">
			<cfparam default="" name="attributes.intstruct.iptc_image_location">
			<cfparam default="" name="attributes.intstruct.iptc_image_city">
			<cfparam default="" name="attributes.intstruct.iptc_image_country">
			<cfparam default="" name="attributes.intstruct.iptc_image_state_province">
			<cfparam default="" name="attributes.intstruct.iptc_iso_country_code">
			<cfparam default="" name="attributes.intstruct.iptc_status_job_identifier">
			<cfparam default="" name="attributes.intstruct.iptc_status_instruction">
			<cfparam default="" name="attributes.intstruct.iptc_status_provider">
			<cfparam default="" name="attributes.intstruct.iptc_status_source">
			<cfparam default="" name="attributes.intstruct.iptc_status_rights_usage_terms">
			<cfparam default="" name="attributes.intstruct.xmp_origin_urgency">
			<cfparam default="" name="attributes.intstruct.img_keywords">
			<cfparam default="" name="attributes.intstruct.img_desc">
			<!--- Because we have many languages sometimes we put together the keywords and description here --->
			<cfif structkeyexists(attributes.intstruct,"langcount")>
				<cfloop list="#attributes.intstruct.langcount#" index="langindex">
					<cfset thiskeywords="attributes.intstruct.img_keywords_" & "#langindex#">
					<cfset attributes.intstruct.img_keywords = attributes.intstruct.img_keywords & "#evaluate(thiskeywords)#">
					<cfif #langindex# LT #langcount#>
						<cfset attributes.intstruct.img_keywords = attributes.intstruct.img_keywords & ", ">
					</cfif>
					<cfset thisdesc="attributes.intstruct.img_desc_" & "#langindex#">
					<cfset attributes.intstruct.img_desc = attributes.intstruct.img_desc & "#evaluate(thisdesc)#">
					<cfif #langindex# LT #langcount#>
						<cfset attributes.intstruct.img_desc = attributes.intstruct.img_desc & ", ">
					</cfif>
				</cfloop>
			</cfif>
		<!--- We come from BATCHING --->
		<cfelse>
			<!--- We reset the desc and keywords by each loop or else they get the values from the previous record --->
			<cfset attributes.intstruct.img_desc = "">
			<cfset attributes.intstruct.img_keywords = "">
			<!--- Reset the xmlxmp struct --->
			<cfset xmlxmp = structnew()>
			<!--- call the component to read the XMP --->
			<cfif attributes.intstruct.storage EQ "local">
				<cfinvoke method="xmpparse" returnvariable="xmlxmp" thestruct="#attributes.intstruct#">
			</cfif>
			<!--- Declare all variables or else you will get errors in the page --->
			<cfparam default="#xmlxmp.title#" name="attributes.intstruct.xmp_document_title">
			<cfparam default="#xmlxmp.creator#" name="attributes.intstruct.xmp_author">
			<cfparam default="#xmlxmp.authorstitle#" name="attributes.intstruct.xmp_author_title">
			<cfparam default="#xmlxmp.descwriter#" name="attributes.intstruct.xmp_description_writer">
			<cfparam default="#xmlxmp.copystatus#" name="attributes.intstruct.xmp_copyright_status">
			<cfparam default="#xmlxmp.copynotice#" name="attributes.intstruct.xmp_copyright_notice">
			<cfparam default="#xmlxmp.copyurl#" name="attributes.intstruct.xmp_copyright_info_url">
			<cfparam default="#xmlxmp.category#" name="attributes.intstruct.xmp_category">
			<cfparam default="#xmlxmp.categorysub#" name="attributes.intstruct.xmp_supplemental_categories">
			<cfparam default="#xmlxmp.iptcaddress#" name="attributes.intstruct.iptc_contact_address">
			<cfparam default="#xmlxmp.iptccity#" name="attributes.intstruct.iptc_contact_city">
			<cfparam default="#xmlxmp.iptcstate#" name="attributes.intstruct.iptc_contact_state_province">
			<cfparam default="#xmlxmp.iptczip#" name="attributes.intstruct.iptc_contact_postal_code">
			<cfparam default="#xmlxmp.iptccountry#" name="attributes.intstruct.iptc_contact_country">
			<cfparam default="#xmlxmp.iptcphone#" name="attributes.intstruct.iptc_contact_phones">
			<cfparam default="#xmlxmp.iptcemail#" name="attributes.intstruct.iptc_contact_emails">
			<cfparam default="#xmlxmp.iptcwebsite#" name="attributes.intstruct.iptc_contact_websites">
			<cfparam default="#xmlxmp.iptcheadline#" name="attributes.intstruct.iptc_content_headline">
			<cfparam default="#xmlxmp.iptcsubjectcode#" name="attributes.intstruct.iptc_content_subject_code">
			<cfparam default="#xmlxmp.iptcdatecreated#" name="attributes.intstruct.iptc_date_created">
			<cfparam default="#xmlxmp.iptcintelgenre#" name="attributes.intstruct.iptc_intellectual_genre">
			<cfparam default="#xmlxmp.iptcscene#" name="attributes.intstruct.iptc_scene">
			<cfparam default="#xmlxmp.iptclocation#" name="attributes.intstruct.iptc_image_location">
			<cfparam default="#xmlxmp.iptcimagecity#" name="attributes.intstruct.iptc_image_city">
			<cfparam default="#xmlxmp.iptcimagecountry#" name="attributes.intstruct.iptc_image_country">
			<cfparam default="#xmlxmp.iptcimagestate#" name="attributes.intstruct.iptc_image_state_province">
			<cfparam default="#xmlxmp.iptcimagecountrycode#" name="attributes.intstruct.iptc_iso_country_code">
			<cfparam default="#xmlxmp.iptcjobidentifier#" name="attributes.intstruct.iptc_status_job_identifier">
			<cfparam default="#xmlxmp.iptcinstructions#" name="attributes.intstruct.iptc_status_instruction">
			<cfparam default="#xmlxmp.iptccredit#" name="attributes.intstruct.iptc_status_provider">
			<cfparam default="#xmlxmp.iptcsource#" name="attributes.intstruct.iptc_status_source">
			<cfparam default="#xmlxmp.iptcusageterms#" name="attributes.intstruct.iptc_status_rights_usage_terms">
			<cfparam default="#xmlxmp.urgency#" name="attributes.intstruct.xmp_origin_urgency">
			<cfparam default="#xmlxmp.description#" name="attributes.intstruct.img_desc">
			<cfparam default="#xmlxmp.keywords#" name="attributes.intstruct.img_keywords">
			<!--- Declare these variables or else we get error on Nirvanix and S3 --->
			<cfparam default="" name="xmlxmp.description">
			<cfparam default="" name="xmlxmp.keywords">
			<!--- If there are values in the existing image then set the desc and keywords, thus we ADD the values from batching --->
			<cfset attributes.intstruct.img_desc = xmlxmp.description>
			<cfset attributes.intstruct.img_keywords = xmlxmp.keywords>
			<!--- Because we have many languages sometimes we put together the keywords and description here --->
			<cfif structkeyexists(attributes.intstruct,"langcount")>
				<cfloop list="#attributes.intstruct.langcount#" index="langindex">
					<!--- If we come from all we need to change the desc and keywords arguments name --->
					<cfif attributes.intstruct.what EQ "all">
						<cfset alldesc = "all_desc_" & #langindex#>
						<cfset allkeywords = "all_keywords_" & #langindex#>
						<cfset thisdesc = "attributes.intstruct.img_desc_" & #langindex#>
						<cfset thiskeywords = "attributes.intstruct.img_keywords_" & #langindex#>
						<cfset "#thisdesc#" =  evaluate(alldesc)>
						<cfset "#thiskeywords#" =  evaluate(allkeywords)>
					</cfif>
					<cfset thiskeywords="attributes.intstruct.img_keywords_" & "#langindex#">
					<cfset attributes.intstruct.img_keywords = attributes.intstruct.img_keywords & "#evaluate(thiskeywords)#">
					<cfif langindex LT langcount>
						<cfset attributes.intstruct.img_keywords = attributes.intstruct.img_keywords & ", ">
					</cfif>
					<cfset thisdesc="attributes.intstruct.img_desc_" & "#langindex#">
					<cfset attributes.intstruct.img_desc = attributes.intstruct.img_desc & "#evaluate(thisdesc)#">
					<cfif langindex LT langcount>
						<cfset attributes.intstruct.img_desc = attributes.intstruct.img_desc & ", ">
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
		<!--- Create the XMP XML file --->
		<cfoutput>
		<!--- Create the file content --->
		<cftry>
			<cfsavecontent variable="thexmp">-xmp:all=<!--- Remove all fileds first --->
<!--- Keywords ---><cfif ltrim(rereplace(attributes.intstruct.img_keywords,"\,","","all")) EQ "">-xmp:subject=
keywords=<cfelse><cfloop delimiters="," index="key" list="#attributes.intstruct.img_keywords#"><cfif ltrim(key) NEQ "">-xmp:subject=#ltrim(key)#
-keywords=#ltrim(key)#</cfif>
</cfloop></cfif><!--- Creator --->
-xmp:creator=#attributes.intstruct.xmp_author#
-IPTC:By-line=#attributes.intstruct.xmp_author#
-xmp:rights=#replacenocase(ParagraphFormat(attributes.intstruct.xmp_copyright_notice),"<p>","","all")#
-IPTC:CopyrightNotice=#replacenocase(ParagraphFormat(attributes.intstruct.xmp_copyright_notice),"<p>","","all")#
-xmp:title=#attributes.intstruct.xmp_document_title#
-IPTC:ObjectName=#attributes.intstruct.xmp_document_title#
-xmp:description=#replacenocase(ParagraphFormat(attributes.intstruct.img_desc),"<p>","","all")#
-IPTC:Caption-Abstract=#replacenocase(ParagraphFormat(attributes.intstruct.img_desc),"<p>","","all")#
-xmp:AuthorsPosition=#attributes.intstruct.xmp_author_title#
-IPTC:By-lineTitle=#attributes.intstruct.xmp_author_title#
-xmp:CaptionWriter=#attributes.intstruct.xmp_description_writer#
-IPTC:Writer-Editor=#attributes.intstruct.xmp_description_writer#
-xmp:Category=#attributes.intstruct.xmp_category#
-iptc:Category=#attributes.intstruct.xmp_category#
-xmp:Headline=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_content_headline),"<p>","","all")#
-iptc:Headline=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_content_headline),"<p>","","all")#
-xmp:DateCreated=#attributes.intstruct.iptc_date_created#
-iptc:DateCreated=#attributes.intstruct.iptc_date_created#
-xmp:City=#attributes.intstruct.iptc_image_city#
-iptc:City=#attributes.intstruct.iptc_image_city#
-xmp:State=#attributes.intstruct.iptc_image_state_province#
-iptc:Province-State=#attributes.intstruct.iptc_image_state_province#
-xmp:Country=#attributes.intstruct.iptc_image_country#
-IPTC:Country-PrimaryLocationName=#attributes.intstruct.iptc_image_country#
-xmp:TransmissionReference=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_status_job_identifier),"<p>","","all")#
-IPTC:OriginalTransmissionReference=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_status_job_identifier),"<p>","","all")#
-xmp:Instructions=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_status_instruction),"<p>","","all")#
-IPTC:SpecialInstructions=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_status_instruction),"<p>","","all")#
-xmp:Credit=#attributes.intstruct.iptc_status_provider#
-iptc:Credit=#attributes.intstruct.iptc_status_provider#
-XMP-xmpPLUS:CreditLineReq=#attributes.intstruct.iptc_status_provider#
-xmp:Source=#attributes.intstruct.iptc_status_source#
-iptc:Source=#attributes.intstruct.iptc_status_source#
-xmp:Urgency=#attributes.intstruct.xmp_origin_urgency#
-iptc:Urgency=#attributes.intstruct.xmp_origin_urgency#<cfloop delimiters="," index="cats" list="#attributes.intstruct.xmp_supplemental_categories#">
-xmp:SupplementalCategories=#ltrim(cats)#
-iptc:SupplementalCategories=#ltrim(cats)#
</cfloop><!--- Iptc4 Core --->
-xmp:Location=#attributes.intstruct.iptc_image_location#
-XMP-iptcCore:Location=#attributes.intstruct.iptc_image_location#
-xmp:CountryCode=#attributes.intstruct.iptc_iso_country_code#
-XMP-iptcCore:CountryCode=#attributes.intstruct.iptc_iso_country_code#
-xmp:IntellectualGenre=#attributes.intstruct.iptc_intellectual_genre#
-XMP-iptcCore:IntellectualGenre=#attributes.intstruct.iptc_intellectual_genre#
-xmp:CiAdrExtadr=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_contact_address),"<p>","","all")#
-XMP-iptcCore:CreatorAddress=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_contact_address),"<p>","","all")#
-xmp:CiAdrCity=#attributes.intstruct.iptc_contact_city#
-XMP-iptcCore:CreatorCity=#attributes.intstruct.iptc_contact_city#
-xmp:CiAdrCtry=#attributes.intstruct.iptc_contact_country#
-XMP-iptcCore:CreatorCountry=#attributes.intstruct.iptc_contact_country#
-xmp:CiTelWork=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_contact_phones),"<p>","","all")#
-XMP-iptcCore:CreatorWorkTelephone=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_contact_phones),"<p>","","all")#
-xmp:CiAdrRegion=#attributes.intstruct.iptc_contact_state_province#
-XMP-iptcCore:CreatorRegion=#attributes.intstruct.iptc_contact_state_province#
-xmp:CiAdrPcode=#attributes.intstruct.iptc_contact_postal_code#
-XMP-iptcCore:CreatorPostalCode=#attributes.intstruct.iptc_contact_postal_code#
-xmp:CiEmailWork=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_contact_emails),"<p>","","all")#
-XMP-iptcCore:CreatorWorkEmail=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_contact_emails),"<p>","","all")#
-xmp:CiUrlWork=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_contact_websites),"<p>","","all")#
-XMP-iptcCore:CreatorWorkURL=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_contact_websites),"<p>","","all")#<!--- Iptc Subject Code ---><cfloop delimiters="," index="subcode" list="#attributes.intstruct.iptc_content_subject_code#">
-xmp:SubjectCode=#ltrim(subcode)#
-XMP-iptcCore:SubjectCode=#ltrim(subcode)#
</cfloop><!--- Iptc Scene ---><cfloop delimiters="," index="scene" list="#attributes.intstruct.iptc_scene#">
-xmp:Scene=#ltrim(scene)# 
-XMP-iptcCore:Scene=#ltrim(scene)#
</cfloop>
-xmp:WebStatement=<cfif attributes.intstruct.xmp_copyright_info_url NEQ "">'#attributes.intstruct.xmp_copyright_info_url#'</cfif>
-XMP-xmpRights:WebStatement=<cfif attributes.intstruct.xmp_copyright_info_url NEQ "">'#attributes.intstruct.xmp_copyright_info_url#'</cfif>
<cfif attributes.intstruct.xmp_copyright_status EQ "true">-xmp:copyrightstatus='true'
-XMP-xmpRights:Marked='true'
<cfelseif attributes.intstruct.xmp_copyright_status EQ "false">-xmp:copyrightstatus='false'
-XMP-xmpRights:Marked='false'
<cfelse>-xmp:copyrightstatus=
-XMP-xmpRights:Marked=
</cfif>
-xmp:UsageTerms=#replacenocase(ParagraphFormat(attributes.intstruct.iptc_status_rights_usage_terms),"<p>","","all")#
			</cfsavecontent>
			<cfcatch type="any"><cfinvoke component="debugme" method="email_dump" emailto="support@razuna.com" emailfrom="server@razuna.com" emailsubject="Error in writing the XML file to savecontent - CFC: XMP Line 320" dump="#cfcatch#"></cfcatch>
		</cftry>
		</cfoutput>
		<!--- Save XMP to DB --->
		<cftransaction>
			<cfquery datasource="#attributes.intstruct.dsn#">
			UPDATE #session.hostdbprefix#xmp
			SET
			subjectcode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_content_subject_code#">,
			creator = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_author#">, 
			title = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_document_title#">, 
			authorsposition = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_author_title#">, 
			captionwriter = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_description_writer#">, 
			ciadrextadr = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_contact_address#">, 
			category = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_category#">, 
			supplementalcategories = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_supplemental_categories#">, 
			urgency = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_origin_urgency#">, 
			description = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.img_desc#">, 
			ciadrcity = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_contact_city#">, 
			ciadrctry = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_contact_country#">, 
			location = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_image_location#">, 
			ciadrpcode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_contact_postal_code#">, 
			ciemailwork = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_contact_emails#">, 
			ciurlwork = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_contact_websites#">, 
			citelwork = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_contact_phones#">, 
			intellectualgenre = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_intellectual_genre#">, 
			instructions = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_status_instruction#">, 
			source = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_status_source#">, 
			usageterms = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_status_rights_usage_terms#">, 
			copyrightstatus = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_copyright_status#">, 
			transmissionreference = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_status_job_identifier#">, 
			webstatement = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_copyright_info_url#">, 
			headline = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_content_headline#">, 
			datecreated = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_date_created#">, 
			city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_image_city#">, 
			ciadrregion = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_contact_state_province#">, 
			country = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_image_country#">, 
			countrycode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_iso_country_code#">, 
			scene = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_scene#">, 
			state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_image_state_province#">, 
			credit = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.iptc_status_provider#">, 
			rights  = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.intstruct.xmp_copyright_notice#">
			WHERE id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attributes.intstruct.file_id#">
			AND asset_type = <cfqueryparam cfsqltype="cf_sql_varchar" value="img">
			AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
			</cfquery>
		</cftransaction>
		<!--- Store XMP to file --->
		<!--- Go grab the platform --->
		<cfinvoke component="assets" method="iswindows" returnvariable="iswindows">
		<!--- Check the platform and then decide on the Exiftool tag --->
		<cfif isWindows>
			<cfset theexe = """#attributes.intstruct.thetools.exiftool#/exiftool.exe""">
		<cfelse>
			<cfset theexe = "#attributes.intstruct.thetools.exiftool#/exiftool">
			<cfset attributes.intstruct.thesource = replacenocase(attributes.intstruct.thesource," ","\ ","all")>
		</cfif>
		<!--- Storage: Local --->
		<cfif attributes.intstruct.storage EQ "local">
			<cftry>
				<cfset attributes.intstruct.qryfile.path = attributes.intstruct.thesource>
				<!--- LOCATION OF XMP FILE --->
				<cfset thexmpfile = "#attributes.intstruct.assetpath#/#attributes.intstruct.hostid#/#attributes.intstruct.path_to_asset#/xmp-#attributes.intstruct.file_id#">
				<!--- On Windows --->
				<cfif iswindows>
					<cfset thexmpfileraw = thexmpfile>
					<cfset thexmpfile = """#thexmpfile#""">
				<cfelse>
					<cfset thexmpfile = replacenocase(thexmpfile," ","\ ","all")>
					<cfset thexmpfile = replacenocase(thexmpfile,"&","\&","all")>
					<cfset thexmpfile = replacenocase(thexmpfile,"'","\'","all")>
					<cfset thexmpfileraw = thexmpfile>
				</cfif>
				<!--- Write XMP file to system --->
				<cffile action="write" file="#thexmpfileraw#" output="#tostring(thexmp)#" charset="utf-8">
				<!--- Write the sh script file --->
				<cfset thescript = createuuid()>
				<cfset attributes.intstruct.thesh = GetTempDirectory() & "/#thescript#.sh">
				<!--- On Windows a .bat --->
				<cfif iswindows>
					<cfset attributes.intstruct.thesh = GetTempDirectory() & "/#thescript#.bat">
				</cfif>
				<!--- Write files --->
				<cffile action="write" file="#attributes.intstruct.thesh#" output="#theexe# -@ #thexmpfile# -overwrite_original #attributes.intstruct.thesource#" mode="777">
				<!--- Execute --->
				<cfexecute name="#attributes.intstruct.thesh#" timeout="60" />
				<!--- Delete scripts --->
				<cffile action="delete" file="#attributes.intstruct.thesh#">
				<!--- Finally remove the XMP file --->
				<cfif FileExists(thexmpfile)>
					<cffile action="delete" file="#thexmpfile#">
				</cfif>
				<!--- Lucene: Delete Records --->
				<cfinvoke component="lucene" method="index_delete" thestruct="#attributes.intstruct#" assetid="#attributes.intstruct.file_id#" category="img">
				<!--- Lucene: Update Records --->
				<cfinvoke component="lucene" method="index_update" dsn="#attributes.intstruct.dsn#" thestruct="#attributes.intstruct#" assetid="#attributes.intstruct.file_id#" category="img">
				<cfcatch type="any">
					<cfinvoke component="debugme" method="email_dump" emailto="nitai@razuna.com" emailfrom="server@razuna.com" emailsubject="error in xmp writing xml file line 400" dump="#cfcatch#">
				</cfcatch>
			</cftry>
		<!--- Storage: Nirvanix --->
		<cfelseif attributes.intstruct.storage EQ "nirvanix">
			<!--- Create temp directory --->
			<cfset attributes.intstruct.tempfolder = createuuid("")>
			<cfdirectory action="create" directory="#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#" mode="775">
			<cfset attributes.intstruct.qryfile.path = "#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#">
			<!--- LOCATION OF XMP FILE --->
			<cfset thexmpfile = "#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#/xmp-#attributes.intstruct.file_id#">
			<cfset attributes.intstruct.thesh = GetTempDirectory() & "/#attributes.intstruct.tempfolder#.sh">
			<!--- On Windows --->
			<cfif iswindows>
				<cfset thexmpfile = """#thexmpfile#""">
				<cfset attributes.intstruct.thesh = GetTempDirectory() & "/#attributes.intstruct.tempfolder#.bat">
			</cfif>
			<!--- Write XMP file --->
			<cffile action="write" file="#thexmpfile#" output="#tostring(thexmp)#" charset="utf-8">
			<!--- Download image --->
			<cfhttp url="http://services.nirvanix.com/#attributes.intstruct.nvxsession#/razuna/#attributes.intstruct.hostid#/#attributes.intstruct.path_to_asset#/#attributes.intstruct.filenameorg#" file="#attributes.intstruct.filenameorg#" path="#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#"></cfhttp>
			<!--- Remove file on Nirvanix or else we get errors during uploading --->
			<cfinvoke component="nirvanix" method="DeleteFiles">
				<cfinvokeargument name="filePath" value="/#attributes.intstruct.path_to_asset#/#attributes.intstruct.filenameorg#">
				<cfinvokeargument name="nvxsession" value="#attributes.intstruct.nvxsession#">
			</cfinvoke>
			<!--- Write XMP to image with Exiftool --->
			<cfexecute name="#theexe#" arguments="-@ #thexmpfile# -overwrite_original #attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#/#attributes.intstruct.filenameorg#" timeout="10" />
			<!--- Upload file again to its original position --->
			<!--- <cfthread name="upload#attributes.intstruct.file_id#" intstruct="#attributes.intstruct#"> --->
				<cfinvoke component="nirvanix" method="Upload">
					<cfinvokeargument name="destFolderPath" value="/#attributes.intstruct.path_to_asset#">
					<cfinvokeargument name="uploadfile" value="#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#/#attributes.intstruct.filenameorg#">
					<cfinvokeargument name="nvxsession" value="#attributes.intstruct.nvxsession#">
				</cfinvoke>
			<!--- </cfthread> --->
			<!--- Lucene: Delete Records --->
			<cfinvoke component="lucene" method="index_delete" thestruct="#attributes.intstruct#" assetid="#attributes.intstruct.file_id#" category="img">
			<!--- Lucene: Update Records --->
			<cfinvoke component="lucene" method="index_update" dsn="#attributes.intstruct.dsn#" thestruct="#attributes.intstruct#" assetid="#attributes.intstruct.file_id#" category="img">
			<!--- Update images db with the new Lucene_Key --->
			<cftransaction>
				<cfquery datasource="#attributes.intstruct.dsn#">
				UPDATE #session.hostdbprefix#images
				SET lucene_key = <cfqueryparam value="#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#/#attributes.intstruct.filenameorg#" cfsqltype="cf_sql_varchar">
				WHERE img_id = <cfqueryparam value="#attributes.intstruct.file_id#" cfsqltype="CF_SQL_VARCHAR">
				AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
				</cfquery>
			</cftransaction>
			<!--- Remove the tempfolder but only if image has been uploaded already --->
			<!--- <cfthread action="join" name="upload#attributes.intstruct.file_id#" /> --->
			<cfif directoryExists("#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#")>
				<cfdirectory action="delete" directory="#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#" recurse="true">
			</cfif>
		</cfif>
	</cfthread>
	<!--- </cfif> --->
</cffunction>

<!--- READ THE KEYWORDS AND DESCRIPION AND WRITE IT TO THE DB --->
<cffunction name="xmpwritekeydesc" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Declare Function Variables --->
	<cfset var keywords = "">
	<cfset var description = "">
	<cfset var thexmlcode = "">
	<cfset var themeta = "">
	<cftry>
		<!--- Create empty records in the table because we sometimes have images without XMP --->
		<cfloop list="#arguments.thestruct.langcount#" index="langindex">
			<!--- Define params if we come from upload where there are not textareas --->
			<cfparam name="arguments.thestruct.file_keywords_#langindex#" default="">
			<cfparam name="arguments.thestruct.file_desc_#langindex#" default="">
			<!--- Insert --->
			<cftransaction>
				<cfquery datasource="#arguments.thestruct.dsn#">
				INSERT INTO #session.hostdbprefix#images_text
				(id_inc, img_id_r, lang_id_r, host_id)
				VALUES(
				<cfqueryparam value="#createuuid()#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#arguments.thestruct.newid#" cfsqltype="CF_SQL_VARCHAR">, 
				<cfqueryparam value="#langindex#" cfsqltype="cf_sql_numeric">,
				<cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
				)
				</cfquery>
			</cftransaction>
		</cfloop>
		<!--- FILESYSTEM --->
		<!--- Go grab the platform --->
		<cfinvoke component="assets" method="iswindows" returnvariable="iswindows">
		<!--- Check the platform and then decide on the Exiftool tag --->
		<cfif isWindows>
			<cfset theexe = """#arguments.thestruct.thetools.exiftool#/exiftool.exe""">
		<cfelse>
			<cfset theexe = "#arguments.thestruct.thetools.exiftool#/exiftool">
		</cfif>
		<cfset theasset = arguments.thestruct.thesource>
		<!--- On Windows a bat --->
		<cfif isWindows>
			<cfexecute name="#theexe#" arguments="-X #theasset#" timeout="60" variable="themeta" />
		<cfelse>
			<!--- The script --->
			<cfset var thescript = createuuid()>
			<!--- Set script --->
			<cfset thesh = gettempdirectory() & "/#thescript#.sh">
			<!--- Write files --->
			<cffile action="write" file="#thesh#" output="#theexe# -X #theasset#" mode="777">
			<!--- Execute --->
			<cfexecute name="#thesh#" timeout="60" variable="themeta" />
			<!--- Delete scripts --->
			<cffile action="delete" file="#thesh#">
		</cfif>
		<cfif themeta NEQ "">
			<!--- Parse Metadata which is now XML --->
			<cfset var thexml = xmlparse(ToString(themeta.getBytes(),'utf-8'))>
			<!--- Description from XMP --->
			<cfset x = xmlSearch(thexml, "//*/*/*[name()='XMP-dc:Description']")>
			<cfset y = xmlSearch(thexml, "//*/*/*[name()='IPTC:Caption-Abstract']")>
			<cfif arraylen(x) GT 0>
				<cfset description = trim(#x[1].xmlText#)>
			</cfif>
			<cfif arraylen(y) GT 0>
				<cfset description = trim(#y[1].xmlText#)>
			</cfif>
			<!--- Keywords from XMP (they are in the subject param) --->
			<cfset x = xmlSearch(thexml, "//*/*/*[name()='XMP-dc:Subject']/*/*")>
			<cfset y = xmlSearch(thexml, "//*/*/*[name()='IPTC:Keywords']/*/*")>
			<!--- If Keywords is empty because there is only ONE keyword then --->
			<cfif arraylen(x) EQ 0>
				<cfset x = xmlSearch(thexml, "//*/*/*[name()='XMP-dc:Subject']")>
			</cfif>
			<cfif arraylen(y) EQ 0>
				<cfset y = xmlSearch(thexml, "//*/*/*[name()='IPTC:Keywords']")>
			</cfif>
			<cfif arraylen(x) GT 0>
				<cfloop from="1" to="#arraylen(x)#" index="i">
					<cfset keywords = keywords & x[i].xmlText>
					<cfif arraylen(x) NEQ i>
						<cfset keywords = keywords & ",">
					</cfif>
				</cfloop>
			</cfif>
			<cfif arraylen(y) GT 0>
				<cfset keywords = "">
				<cfloop from="1" to="#arraylen(y)#" index="i">
					<cfset keywords = keywords & y[i].xmlText>
					<cfif arraylen(y) NEQ i>
						<cfset keywords = keywords & ",">
					</cfif>
				</cfloop>
			</cfif>	
			<!--- 
			Append the keywords and description to the images_text table. Since XMP is not multilingual we just insert it into 
			every language there is 
			--->
			<cfloop list="#arguments.thestruct.langcount#" index="langindex">
				<cfset newkeywords = "">
				<cfset newdescription = "">
				<!--- Grab the user input --->
				<cfif arguments.thestruct.uploadkind EQ "many">
					<cfset userdesc="file_desc_" & "#countnr#" & "_" & "#langindex#">
					<cfset userkeywords="file_keywords_" & "#countnr#" & "_" & "#langindex#">
				<cfelse>
					<cfset userdesc="arguments.thestruct.file_desc_" & "#langindex#">
					<cfset userkeywords="arguments.thestruct.file_keywords_" & "#langindex#">
				</cfif>
				<cfif userdesc CONTAINS #langindex#>
					<!--- Now put xmp values and user values together  --->
					<cfif evaluate(userkeywords) EQ "">
						<cfset newkeywords = keywords>
					<cfelse>
						<cfset newkeywords = evaluate(userkeywords) & "," & keywords>
					</cfif>
					<cfif evaluate(userdesc) EQ "">
						<cfset newdescription = description>
					<cfelse>
						<cfset newdescription = evaluate(userdesc) & " " & description>
					</cfif>
					<cftry>
						<!--- Append to DB --->
						<cftransaction>
							<cfquery datasource="#arguments.thestruct.dsn#">
							UPDATE #session.hostdbprefix#images_text
							SET 
							<cfif newkeywords EQ ",">
								img_keywords = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
							<cfelse>
								img_keywords = <cfqueryparam value="#ltrim(newkeywords)#" cfsqltype="cf_sql_varchar">
							</cfif>,
							img_description = <cfqueryparam value="#ltrim(newdescription)#" cfsqltype="cf_sql_varchar">
							WHERE img_id_r = <cfqueryparam value="#arguments.thestruct.newid#" cfsqltype="CF_SQL_VARCHAR">
							AND lang_id_r = <cfqueryparam value="#langindex#" cfsqltype="cf_sql_numeric">
							</cfquery>
						</cftransaction>
						<cfcatch type="any">
							<cfmail type="html" to="support@razuna.com" from="server@razuna.com" subject="error in image upload keywords">
								<cfdump var="#cfcatch#" />
							</cfmail>
						</cfcatch>
					</cftry>
				</cfif>
			</cfloop>
		</cfif>
		<cfcatch type="any">
			<cfmail type="html" to="support@razuna.com" from="server@razuna.com" subject="error in xmpwritekeydesc">
				<cfdump var="#cfcatch#" />
			</cfmail>
		</cfcatch>
	</cftry>
</cffunction>

<!--- Read the XMP parse it --->
<cffunction name="xmpparse" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Declare all variables or else you will get errors in the page --->
	<cfset xmp = structnew()>
	<cfset xmp.keywords = "">
	<cfset xmp.description = "">
	<cfset xmp.iptcsubjectcode = "">
	<cfset xmp.iptcscene = "">
	<cfset xmp.creator = "">
	<cfset xmp.title = "">
	<cfset xmp.authorstitle = "">
	<cfset xmp.descwriter = "">
	<cfset xmp.iptcaddress = "">
	<cfset xmp.iptccity = "">
	<cfset xmp.iptcstate = "">
	<cfset xmp.iptczip = "">
	<cfset xmp.iptccountry = "">
	<cfset xmp.iptcphone = "">
	<cfset xmp.iptcemail = "">
	<cfset xmp.iptcwebsite = "">
	<cfset xmp.iptcheadline = "">
	<cfset xmp.iptcdatecreated = "">
	<cfset xmp.iptcintelgenre = "">
	<cfset xmp.iptclocation = "">
	<cfset xmp.iptcimagecity = "">
	<cfset xmp.iptcimagestate = "">
	<cfset xmp.iptcimagecountry = "">
	<cfset xmp.iptcimagecountrycode = "">
	<cfset xmp.iptcjobidentifier = "">
	<cfset xmp.iptcinstructions = "">
	<cfset xmp.iptccredit = "">
	<cfset xmp.iptcsource = "">
	<cfset xmp.iptcusageterms = "">
	<cfset xmp.urgency = "">
	<cfset xmp.description = "">
	<cfset xmp.copynotice = "">
	<cfset xmp.copystatus = "">
	<cfset xmp.copyurl = "">
	<cfset xmp.category = "">
	<cfset xmp.categorysub = "">
	<cfset xmp.orgwidth = "">
	<cfset xmp.orgheight = "">
	<cfset xmp.colorspace = "">
	<cfset xmp.xres = "">
	<cfset xmp.yres = "">
	<cfset xmp.resunit = "">
	<cfset xmp.filetype = "">
	<cfset var thecoma = "">
	<cfset var themeta = "">
	<cftry>
		<!--- Go grab the platform --->
		<cfinvoke component="assets" method="iswindows" returnvariable="iswindows">
		<!--- Check the platform and then decide on the Exiftool tag --->
		<cfif isWindows>
			<cfset theexe = """#arguments.thestruct.thetools.exiftool#/exiftool.exe""">
		<cfelse>
			<cfset theexe = "#arguments.thestruct.thetools.exiftool#/exiftool">
		</cfif>
		<cfset theasset = arguments.thestruct.thesource>
		<!--- On Windows a bat --->
		<cfif isWindows>
			<cfexecute name="#theexe#" arguments="-X #theasset#" timeout="60" variable="themeta" />
		<cfelse>
			<!--- New parsing code --->
			<cfset var thescript = createuuid()>
			<!--- Set script --->
			<cfset var thesh = gettempdirectory() & "/#thescript#.sh">
				<!--- Write files --->
			<cffile action="write" file="#thesh#" output="#theexe# -X #theasset#" mode="777">
			<!--- Execute --->
			<cfexecute name="#thesh#" timeout="60" variable="themeta" />
			<!--- Delete scripts --->
			<cffile action="delete" file="#thesh#">
		</cfif>
		<!--- Parse Metadata which is now XML --->
		<cfset var thexml = xmlparse(ToString(themeta.getBytes(),'utf-8'))>
		<cfset thexml = xmlSearch(thexml, "//rdf:Description/")>
		<!--- iptcsubjectcode --->
		<cftry>
			<cfset xmp.iptcsubjectcode = trim(#thexml[1]["XMP-iptcCore:SubjectCode"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- scene --->
		<cftry>
			<cfset xmp.iptcscene = trim(#thexml[1]["XMP-iptcCore:Scene"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- creator or IPTC:By-line --->
		<cftry>
			<cfset xmp.creator = trim(#thexml[1]["XMP-dc:Creator"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.creator EQ "">
			<cftry>
				<cfset xmp.creator = trim(#thexml[1]["IPTC:By-line"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- document title --->
		<cftry>
			<cfset xmp.title = trim(#thexml[1]["XMP-dc:Title"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.title EQ "">
			<cftry>
				<cfset xmp.title = trim(#thexml[1]["IPTC:ObjectName"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- AuthorsPosition --->
		<cftry>
			<cfset xmp.authorstitle = trim(#thexml[1]["XMP-photoshop:AuthorsPosition"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.authorstitle EQ "">
			<cftry>
				<cfset xmp.authorstitle = trim(#thexml[1]["IPTC:By-lineTitle"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- CaptionWriter --->
		<cftry>
			<cfset xmp.descwriter = trim(#thexml[1]["XMP-photoshop:CaptionWriter"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.descwriter EQ "">
			<cftry>
				<cfset xmp.descwriter = trim(#thexml[1]["IPTC:Writer-Editor"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- iptcaddress --->
		<cftry>
			<cfset xmp.iptcaddress = trim(#thexml[1]["XMP-iptcCore:CreatorAddress"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- Category --->
		<cftry>
			<cfset xmp.category = trim(#thexml[1]["XMP-photoshop:Category"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.category EQ "">
			<cftry>
				<cfset xmp.category = trim(#thexml[1]["IPTC:Category"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- Supplementalcategories --->
		<cftry>
			<cfset xmp.categorysub = trim(#thexml[1]["XMP-photoshop:SupplementalCategories"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.categorysub EQ "">
			<cftry>
				<cfset xmp.categorysub = trim(#thexml[1]["IPTC:SupplementalCategories"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- Urgency --->
		<cftry>
			<cfset xmp.urgency = trim(#thexml[1]["XMP-photoshop:Urgency"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.urgency EQ "">
			<cftry>
				<cfset xmp.urgency = trim(#thexml[1]["IPTC:Urgency"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- Description from XMP --->
		<cftry>
			<cfset xmp.description = trim(#thexml[1]["XMP-dc:Description"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.description EQ "">
			<cftry>
				<cfset xmp.description = trim(#thexml[1]["IPTC:Caption-Abstract"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- Keywords from XMP (they are in the subject param) --->
		<cftry>
			<cfset x = thexml[1]["XMP-dc:Subject"]["rdf:Bag"]["rdf:li"]>
			<cfcatch type="any">
				<cfset x = newarray(1)>
			</cfcatch>
		</cftry>
		<cftry>
			<cfset y = thexml[1]["IPTC:Keywords"]["rdf:Bag"]["rdf:li"]>
			<cfcatch type="any">
				<cfset y = newarray(1)>
			</cfcatch>
		</cftry>
		<!--- If subject XML is empty then check for single keyword --->
		<cfif arraylen(x) EQ 0>
			<cftry>
				<cfset xmp.keywords = thexml[1]["XMP-dc:Subject"].xmltext>
				<cfcatch type="any"></cfcatch>
			</cftry>
		<cfelse>
			<cfloop from="1" to="#arraylen(x)#" index="i">
				<cfset xmp.keywords = xmp.keywords & x[i].xmlText>
				<cfif arraylen(x) NEQ i>
					<cfset xmp.keywords = xmp.keywords & ",">
				</cfif>
			</cfloop>
		</cfif>
		<cfif arraylen(y) EQ 0>
			<cftry>
				<cfset xmp.keywords = thexml[1]["IPTC:Keywords"].xmltext>
				<cfcatch type="any"></cfcatch>
			</cftry>
		<cfelse>
			<cfset xmp.keywords = "">
			<cfloop from="1" to="#arraylen(y)#" index="i">
				<cfset xmp.keywords = xmp.keywords & y[i].xmlText>
				<cfif arraylen(y) NEQ i>
					<cfset xmp.keywords = xmp.keywords & ",">
				</cfif>
			</cfloop>
		</cfif>
		<!--- city --->
		<cftry>
			<cfset xmp.iptccity = trim(#thexml[1]["XMP-iptcCore:CreatorCity"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- state --->
		<cftry>
			<cfset xmp.iptcstate = trim(#thexml[1]["XMP-iptcCore:CreatorRegion"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- country --->
		<cftry>
			<cfset xmp.iptccountry = trim(#thexml[1]["XMP-iptcCore:CreatorCountry"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- location --->
		<cftry>
			<cfset xmp.iptclocation = trim(#thexml[1]["XMP-iptcCore:Location"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- zip --->
		<cftry>
			<cfset xmp.iptczip = trim(#thexml[1]["XMP-iptcCore:CreatorPostalCode"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- email --->
		<cftry>
			<cfset xmp.iptcemail = trim(#thexml[1]["XMP-iptcCore:CreatorWorkEmail"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- web --->
		<cftry>
			<cfset xmp.iptcwebsite = trim(#thexml[1]["XMP-iptcCore:CreatorWorkURL"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- phone --->
		<cftry>
			<cfset xmp.iptcphone = trim(#thexml[1]["XMP-iptcCore:CreatorWorkTelephone"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- IntellectualGenre --->
		<cftry>
			<cfset xmp.iptcintelgenre = trim(#thexml[1]["XMP-iptcCore:IntellectualGenre"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- Instructions --->
		<cftry>
			<cfset xmp.iptcinstructions = trim(#thexml[1]["XMP-photoshop:Instructions"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptcinstructions EQ "">
			<cftry>
				<cfset xmp.iptcinstructions = trim(#thexml[1]["IPTC:SpecialInstructions"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- Credit --->
		<cftry>
			<cfset xmp.iptccredit = trim(#thexml[1]["XMP-photoshop:Credit"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptccredit EQ "">
			<cftry>
				<cfset xmp.iptccredit = trim(#thexml[1]["IPTC:Credit"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- Source --->
		<cftry>
			<cfset xmp.iptcsource = trim(#thexml[1]["XMP-photoshop:Source"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptcsource EQ "">
			<cftry>
				<cfset xmp.iptcsource = trim(#thexml[1]["IPTC:Source"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- UsageTerms --->
		<cftry>
			<cfset xmp.iptcusageterms = trim(#thexml[1]["XMP-xmpRights:UsageTerms"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- Rights --->
		<cftry>
			<cfset xmp.copynotice = trim(#thexml[1]["XMP-dc:Rights"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.copynotice EQ "">
			<cftry>
				<cfset xmp.copynotice = trim(#thexml[1]["IPTC:CopyrightNotice"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- copyrightstatus --->
		<cftry>
			<cfset xmp.copystatus = trim(#thexml[1]["Photoshop:CopyrightFlag"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- TransmissionReference --->
		<cftry>
			<cfset xmp.iptcjobidentifier = trim(#thexml[1]["XMP-photoshop:TransmissionReference"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptcjobidentifier EQ "">
			<cftry>
				<cfset xmp.iptcjobidentifier = trim(#thexml[1]["IPTC:OriginalTransmissionReference"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- WebStatement --->
		<cftry>
			<cfset xmp.copyurl = trim(#thexml[1]["XMP-xmpRights:WebStatement"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.copyurl EQ "">
			<cftry>
				<cfset xmp.copyurl = trim(#thexml[1]["Photoshop:URL"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- headline --->
		<cftry>
			<cfset xmp.iptcheadline = trim(#thexml[1]["XMP-photoshop:Headline"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptcheadline EQ "">
			<cftry>
				<cfset xmp.iptcheadline = trim(#thexml[1]["IPTC:Headline"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- datecreated --->
		<cftry>
			<cfset xmp.iptcdatecreated = trim(#thexml[1]["XMP-photoshop:DateCreated"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptcdatecreated EQ "">
			<cftry>
				<cfset xmp.iptcdatecreated = trim(#thexml[1]["IPTC:DateCreated"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- city --->
		<cftry>
			<cfset xmp.iptcimagecity = trim(#thexml[1]["XMP-photoshop:City"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptcimagecity EQ "">
			<cftry>
				<cfset xmp.iptcimagecity = trim(#thexml[1]["IPTC:City"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- state --->
		<cftry>
			<cfset xmp.iptcimagestate = trim(#thexml[1]["XMP-photoshop:State"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptcimagestate EQ "">
			<cftry>
				<cfset xmp.iptcimagestate = trim(#thexml[1]["IPTC:Province-State"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- country --->
		<cftry>
			<cfset xmp.iptcimagecountry = trim(#thexml[1]["XMP-photoshop:Country"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<cfif xmp.iptcimagecountry EQ "">
			<cftry>
				<cfset xmp.iptcimagecountry = trim(#thexml[1]["IPTC:Country-PrimaryLocationName"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<!--- countrycode --->
		<cftry>
			<cfset xmp.iptcimagecountrycode = trim(#thexml[1]["XMP-iptcCore:CountryCode"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		
		<!--- Get fileType --->
		<cftry>
			<cfset xmp.filetype = trim(#thexml[1]["File:FileType"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
		<!--- Get information according to filetype --->
		<cfif xmp.filetype EQ "psd">
			<cftry>
				<cfset xmp.orgwidth = trim(#thexml[1]["Photoshop:ImageWidth"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.orgheight = trim(#thexml[1]["Photoshop:ImageHeight"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.colorspace = trim(#thexml[1]["Photoshop:ColorMode"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.xres = trim(#thexml[1]["Photoshop:XResolution"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.yres = trim(#thexml[1]["Photoshop:YResolution"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.resunit = trim(#thexml[1]["Photoshop:DisplayedUnitsX"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		<cfelseif xmp.filetype EQ "png">
			<cftry>
				<cfset xmp.orgwidth = trim(#thexml[1]["PNG:ImageWidth"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.orgheight = trim(#thexml[1]["PNG:ImageHeight"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.colorspace = trim(#thexml[1]["PNG:ColorType"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.xres = trim(#thexml[1]["PNG:PixelsPerUnitX"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.yres = trim(#thexml[1]["PNG:PixelsPerUnitY"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cftry>
				<cfset xmp.resunit = trim(#thexml[1]["PNG:PixelUnits"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		<cfelse>
			<!--- Width --->
			<cftry>
				<cfset xmp.orgwidth = trim(#thexml[1]["File:ImageWidth"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cfif xmp.orgwidth EQ "">
				<cftry>
					<cfset xmp.orgwidth = trim(#thexml[1]["IFD0:ImageWidth"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<cfif xmp.orgwidth EQ "">
				<cftry>
					<cfset xmp.orgwidth = trim(#thexml[1]["ExifIFD:ExifImageWidth"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<cfif xmp.orgwidth EQ "">
				<cftry>
					<cfset xmp.orgwidth = trim(#thexml[1]["SubIFD1:ImageWidth"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<!--- Height --->
			<cftry>
				<cfset xmp.orgheight = trim(#thexml[1]["File:ImageHeight"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cfif xmp.orgheight EQ "">
				<cftry>
					<cfset xmp.orgheight = trim(#thexml[1]["IFD0:ImageHeight"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<cfif xmp.orgheight EQ "">
				<cftry>
					<cfset xmp.orgheight = trim(#thexml[1]["ExifIFD:ExifImageHeight"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<cfif xmp.orgheight EQ "">
				<cftry>
					<cfset xmp.orgheight = trim(#thexml[1]["SubIFD1:ImageHeight"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<!--- ColorSpace --->
			<cftry>
				<cfset xmp.colorspace = trim(#thexml[1]["ICC-header:ColorSpaceData"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cfif xmp.colorspace EQ "">
				<cftry>
					<cfset xmp.colorspace = trim(#thexml[1]["ExifIFD:ColorSpace"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<!--- Xresolution --->
			<cftry>
				<cfset xmp.xres = trim(#thexml[1]["IFD0:XResolution"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cfif xmp.xres EQ "">
				<cftry>
					<cfset xmp.xres = trim(#thexml[1]["JFIF:XResolution"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<!--- Yresolution --->
			<cftry>
				<cfset xmp.yres = trim(#thexml[1]["IFD0:YResolution"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cfif xmp.yres EQ "">
				<cftry>
					<cfset xmp.yres = trim(#thexml[1]["JFIF:YResolution"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
			<!--- Resolution Unit --->
			<cftry>
				<cfset xmp.resunit = trim(#thexml[1]["IFD0:ResolutionUnit"].xmltext#)>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<cfif xmp.resunit EQ "">
				<cftry>
					<cfset xmp.resunit = trim(#thexml[1]["JFIF:ResolutionUnit"].xmltext#)>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
		</cfif>
		<!--- Catch the error --->
		<cfcatch type="any">
			<cfmail type="html" to="support@razuna.com" from="server@razuna.com" subject="error in xmpparse">
				<cfdump var="#cfcatch#" />
				<cfdump var="#arguments.thestruct#">
			</cfmail>
		</cfcatch>
	</cftry>
<!--- Return variable --->
	<cfreturn xmp>
</cffunction>

<!--- WRITE METADATA IN THREAD --->
<cffunction name="metatofile" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Set arguments --->
	<cfset arguments.thestruct.dsn = variables.dsn>
	<cfset arguments.thestruct.setid = variables.setid>
	<!--- The tool paths --->
	<cfinvoke component="settings" method="get_tools" returnVariable="arguments.thestruct.thetools" />
	<!--- Start the thread for updating --->
	<cfset tt = CreateUUid()>
	<cfthread name="meta#tt#" intstruct="#arguments.thestruct#">
		<cfinvoke method="metatofilethread" thestruct="#attributes.intstruct#" />
	</cfthread>
</cffunction>

<!--- Write Metadata to files --->
<cffunction name="metatofilethread" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Param --->
	<cfparam default="F" name="arguments.thestruct.frombatch">
	<cfparam default="" name="arguments.thestruct.file_keywords">
	<cfparam default="" name="arguments.thestruct.file_desc">
	<cfparam default="" name="arguments.thestruct.author">
	<cfparam default="" name="arguments.thestruct.rights">
	<cfparam default="" name="arguments.thestruct.authorsposition">
	<cfparam default="" name="arguments.thestruct.captionwriter">
	<cfparam default="" name="arguments.thestruct.webstatement">
	<cfparam default="" name="arguments.thestruct.rightsmarked">
	<cfparam default="#session.hostid#" name="arguments.thestruct.hostid">
	<!--- Query the record --->
	<cfquery datasource="#variables.dsn#" name="arguments.thestruct.qrydetail">
	SELECT  f.file_id, f.folder_id_r, f.file_extension, f.file_type, f.file_name, f.file_name_org filenameorg, f.link_path_url, 
	f.link_kind, f.lucene_key, f.path_to_asset, f.cloud_url_org
	FROM #session.hostdbprefix#files f
	WHERE f.file_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.file_id#">
	AND f.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.hostid#">
	</cfquery>
	<!--- Set the source --->
	<cfif arguments.thestruct.qrydetail.link_kind EQ "lan">
		<cfset arguments.thestruct.thesource = arguments.thestruct.qrydetail.link_path_url>
	<cfelse>
		<cfset arguments.thestruct.thesource = "#arguments.thestruct.assetpath#/#arguments.thestruct.hostid#/#arguments.thestruct.qrydetail.path_to_asset#/#arguments.thestruct.qrydetail.filenameorg#">
	</cfif>
	<!--- We are NOT coming from batching --->
	<cfif arguments.thestruct.frombatch EQ "F">
		<!--- Because we have many languages we put together the keywords and description here --->
		<cfif structkeyexists(arguments.thestruct,"langcount")>
			<cfloop list="#arguments.thestruct.langcount#" index="langindex">
				<cfset thiskeywords="arguments.thestruct.file_keywords_" & "#langindex#">
				<cfif evaluate(thiskeywords) NEQ "">
					<cfset arguments.thestruct.file_keywords = arguments.thestruct.file_keywords & "#evaluate(thiskeywords)#">
					<cfif langindex LT langcount>
						<cfset arguments.thestruct.file_keywords = arguments.thestruct.file_keywords & ", ">
					</cfif>
					<cfset thisdesc="arguments.thestruct.file_desc_" & "#langindex#">
					<cfset arguments.thestruct.file_desc = arguments.thestruct.file_desc & "#evaluate(thisdesc)#">
					<cfif langindex LT langcount>
						<cfset arguments.thestruct.file_desc = arguments.thestruct.file_desc & ", ">
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
	<!--- We come from BATCHING --->
	<cfelse>
		<!--- We reset the desc and keywords by each loop or else they get the values from the previous record --->
		<cfset arguments.thestruct.img_desc = "">
		<cfset arguments.thestruct.img_keywords = "">
		<!--- Reset the xmlxmp struct --->
		<cfset xmlxmp = structnew()>
		<!--- call the compontent to read the XMP --->
		<cfinvoke method="xmpparse" returnvariable="xmlxmp" thestruct="#arguments.thestruct#">
		<!--- If there are values in the existing image then set the desc and keywords, thus we ADD the values from batching --->
		<cfset arguments.thestruct.img_desc = xmlxmp.description>
		<cfset arguments.thestruct.img_keywords = xmlxmp.keywords>
		<!--- Because we have many languages sometimes we put together the keywords and description here --->
		<cfif structkeyexists(arguments.thestruct,"langcount")>
			<cfloop list="#arguments.thestruct.langcount#" index="langindex">
				<!--- If we come from all we need to change the desc and keywords arguments name --->
				<cfif arguments.thestruct.what EQ "all">
					<cfset alldesc = "all_desc_" & #langindex#>
					<cfset allkeywords = "all_keywords_" & #langindex#>
					<cfset thisdesc = "arguments.thestruct.img_desc_" & #langindex#>
					<cfset thiskeywords = "arguments.thestruct.img_keywords_" & #langindex#>
					<cfset "#thisdesc#" =  evaluate(alldesc)>
					<cfset "#thiskeywords#" =  evaluate(allkeywords)>
				</cfif>
				<cfset thiskeywords="arguments.thestruct.img_keywords_" & "#langindex#">
				<cfset arguments.thestruct.img_keywords = arguments.thestruct.img_keywords & "#evaluate(thiskeywords)#">
				<cfif #langindex# LT #langcount#>
					<cfset arguments.thestruct.img_keywords = arguments.thestruct.img_keywords & ", ">
				</cfif>
				<cfset thisdesc="arguments.thestruct.img_desc_" & "#langindex#">
				<cfset arguments.thestruct.img_desc = arguments.thestruct.img_desc & "#evaluate(thisdesc)#">
				<cfif #langindex# LT #langcount#>
					<cfset arguments.thestruct.img_desc = arguments.thestruct.img_desc & ", ">
				</cfif>
			</cfloop>
		</cfif>
	</cfif>
	<!--- Remove the last comma of the keyword string --->
	<cfset theright = trim(right(arguments.thestruct.file_keywords,2))>
	<!--- If the last char is a comma remove it --->
	<cfif theright EQ ",">
		<cfset thelen = len(arguments.thestruct.file_keywords)>
		<cfset thelen = thelen - 2>
		<cfset arguments.thestruct.file_keywords = mid(arguments.thestruct.file_keywords,1,thelen)>
	</cfif>
	<!--- Go grab the platform --->
	<cfinvoke component="assets" method="iswindows" returnvariable="iswindows">
	<!--- Check the platform and then decide on the Exiftool tag --->
	<cfif isWindows>
		<cfset theexe = """#arguments.thestruct.thetools.exiftool#/exiftool.exe""">
	<cfelse>
		<cfset theexe = "#arguments.thestruct.thetools.exiftool#/exiftool">
		<cfset arguments.thestruct.thesource = replacenocase(arguments.thestruct.thesource," ","\ ","all")>
	</cfif>
	<!--- Storage: Local --->
	<cfif application.razuna.storage EQ "local">
		<cftry>
			<!--- On Windows a .bat --->
			<cfif iswindows>
				<cfexecute name="#theexe#" arguments="-subject='#arguments.thestruct.file_desc#' -keywords='#arguments.thestruct.file_keywords#' -XMP-dc:Rights='#arguments.thestruct.rights#' -XMP-xmpRights:Marked='#arguments.thestruct.rightsmarked#' -XMP-xmpRights:WebStatement='#arguments.thestruct.webstatement#' -XMP-photoshop:AuthorsPosition='#arguments.thestruct.authorsposition#' -XMP-photoshop:CaptionWriter='#arguments.thestruct.captionwriter#' -XMP-dc:Creator='#arguments.thestruct.author#' -PDF:Author='#arguments.thestruct.author#' -overwrite_original #arguments.thestruct.thesource#" timeout="60" />
			<cfelse>
				<!--- Write the sh script file --->
				<cfset thescript = createuuid()>
				<cfset arguments.thestruct.thesh = GetTempDirectory() & "/#thescript#.sh">
				<!--- Write files --->
				<cffile action="write" file="#arguments.thestruct.thesh#" output="#theexe# -subject='#arguments.thestruct.file_desc#' -keywords='#arguments.thestruct.file_keywords#' -XMP-dc:Rights='#arguments.thestruct.rights#' -XMP-xmpRights:Marked='#arguments.thestruct.rightsmarked#' -XMP-xmpRights:WebStatement='#arguments.thestruct.webstatement#' -XMP-photoshop:AuthorsPosition='#arguments.thestruct.authorsposition#' -XMP-photoshop:CaptionWriter='#arguments.thestruct.captionwriter#' -XMP-dc:Creator='#arguments.thestruct.author#' -PDF:Author='#arguments.thestruct.author#' -overwrite_original #arguments.thestruct.thesource#" mode="777">
				<!--- Execute --->
				<cfexecute name="#arguments.thestruct.thesh#" timeout="60" />
				<!--- Delete scripts --->
				<cffile action="delete" file="#arguments.thestruct.thesh#">	
			</cfif>
			<!--- Lucene: Delete Records --->
			<cfinvoke component="lucene" method="index_delete" thestruct="#arguments.thestruct#" assetid="#arguments.thestruct.file_id#" category="doc">
			<!--- Lucene: Update Records --->
			<cfinvoke component="lucene" method="index_update" dsn="#variables.dsn#" thestruct="#arguments.thestruct#" assetid="#arguments.thestruct.file_id#" category="doc">
			<cfcatch type="any">
				<cfinvoke component="debugme" method="email_dump" emailto="nitai@razuna.com" emailfrom="server@razuna.com" emailsubject="error in metadata writing for files" dump="#cfcatch#">
			</cfcatch>
		</cftry>
	<!--- Storage: Nirvanix --->
	<cfelseif application.razuna.storage EQ "nirvanix" OR application.razuna.storage EQ "amazon">
		<!--- Create temp directory --->
		<cfset arguments.thestruct.tempfolder = createuuid("")>
		<cfdirectory action="create" directory="#arguments.thestruct.thepath#/incoming/#arguments.thestruct.tempfolder#" mode="775">
		<cfset arguments.thestruct.qryfile.path = "#arguments.thestruct.thepath#/incoming/#arguments.thestruct.tempfolder#">
		<!--- Download file --->
		<cfif application.razuna.storage EQ "nirvanix">
			<!--- Finally download --->
			<cfhttp url="#arguments.thestruct.qrydetail.cloud_url_org#" file="#arguments.thestruct.qrydetail.filenameorg#" path="#arguments.thestruct.thepath#/incoming/#arguments.thestruct.tempfolder#"></cfhttp>
			<cfthread name="download#arguments.thestruct.file_id#" />
		<cfelseif application.razuna.storage EQ "amazon">
			<cfthread name="download#arguments.thestruct.file_id#" intstruct="#arguments.thestruct#">
				<cfinvoke component="amazon" method="Download">
					<cfinvokeargument name="key" value="/#attributes.intstruct.qrydetail.path_to_asset#/#attributes.intstruct.qrydetail.filenameorg#">
					<cfinvokeargument name="theasset" value="#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#/#attributes.intstruct.qrydetail.filenameorg#">
					<cfinvokeargument name="awsbucket" value="#attributes.intstruct.awsbucket#">
				</cfinvoke>
			</cfthread>
		</cfif>	
		<!--- Wait for the thread above until the file is downloaded fully --->
		<cfthread action="join" name="download#arguments.thestruct.file_id#" />
		<!--- Write XMP to image with Exiftool --->
		<cfexecute name="#theexe#" arguments="-subject='#arguments.thestruct.file_desc#' -keywords='#arguments.thestruct.file_keywords#' -XMP-dc:Rights='#arguments.thestruct.rights#' -XMP-xmpRights:Marked='#arguments.thestruct.rightsmarked#' -XMP-xmpRights:WebStatement='#arguments.thestruct.webstatement#' -XMP-photoshop:AuthorsPosition='#arguments.thestruct.authorsposition#' -XMP-photoshop:CaptionWriter='#arguments.thestruct.captionwriter#' -XMP-dc:Creator='#arguments.thestruct.author#' -PDF:Author='#arguments.thestruct.author#' -overwrite_original #arguments.thestruct.thepath#/incoming/#arguments.thestruct.tempfolder#/#arguments.thestruct.qrydetail.filenameorg#" timeout="10" />
		<!--- Upload file again to its original position --->
		<!--- NIRVANIX --->
		<cfif application.razuna.storage EQ "nirvanix">
			<!--- <cfthread name="upload#arguments.thestruct.file_id#" intstruct="#arguments.thestruct#"> --->
				<!--- Remove file on Nirvanix or else we get errors during uploading --->
				<cfinvoke component="nirvanix" method="DeleteFiles">
					<cfinvokeargument name="filePath" value="/#arguments.thestruct.qrydetail.path_to_asset#/#arguments.thestruct.qrydetail.filenameorg#">
					<cfinvokeargument name="nvxsession" value="#arguments.thestruct.nvxsession#">
				</cfinvoke>
				<cfinvoke component="nirvanix" method="Upload">
					<cfinvokeargument name="destFolderPath" value="/#arguments.thestruct.qrydetail.path_to_asset#">
					<cfinvokeargument name="uploadfile" value="#arguments.thestruct.thepath#/incoming/#arguments.thestruct.tempfolder#/#arguments.thestruct.qrydetail.filenameorg#">
					<cfinvokeargument name="nvxsession" value="#arguments.thestruct.nvxsession#">
				</cfinvoke>
			<!--- </cfthread> --->
		<!--- AMAZON --->
		<cfelseif application.razuna.storage EQ "amazon">
			<cfthread name="upload#arguments.thestruct.file_id#" intstruct="#arguments.thestruct#">
				<cfinvoke component="amazon" method="Upload">
					<cfinvokeargument name="key" value="/#attributes.intstruct.qrydetail.path_to_asset#/#attributes.intstruct.qrydetail.filenameorg#">
					<cfinvokeargument name="theasset" value="#attributes.intstruct.thepath#/incoming/#attributes.intstruct.tempfolder#/#attributes.intstruct.qrydetail.filenameorg#">
					<cfinvokeargument name="awsbucket" value="#attributes.intstruct.awsbucket#">
				</cfinvoke>
			</cfthread>
		</cfif>
		<!--- Lucene: Delete Records --->
		<cfinvoke component="lucene" method="index_delete" thestruct="#arguments.thestruct#" assetid="#arguments.thestruct.file_id#" category="doc">
		<!--- Lucene: Update Records --->
		<cfinvoke component="lucene" method="index_update" dsn="#variables.dsn#" thestruct="#arguments.thestruct#" assetid="#arguments.thestruct.file_id#" category="doc">
		<!--- Update images db with the new Lucene_Key --->
		<cftransaction>
			<cfquery datasource="#variables.dsn#">
			UPDATE #session.hostdbprefix#files
			SET lucene_key = <cfqueryparam value="#arguments.thestruct.thepath#/incoming/#arguments.thestruct.tempfolder#/#arguments.thestruct.qrydetail.filenameorg#" cfsqltype="cf_sql_varchar">
			WHERE file_id = <cfqueryparam value="#arguments.thestruct.file_id#" cfsqltype="CF_SQL_VARCHAR">
			AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.hostid#">
			</cfquery>
		</cftransaction>
		<!--- Remove the tempfolder but only if image has been uploaded already --->
		<!--- <cfthread action="join" name="upload#arguments.thestruct.file_id#" /> --->
		<cfdirectory action="delete" directory="#arguments.thestruct.thepath#/incoming/#arguments.thestruct.tempfolder#" recurse="true">
	</cfif>
</cffunction>

<!--- Get metadata for PDF --->
<cffunction name="getpdfxmp" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Parse Metadata which is now XML --->
	<cfset var thexml = xmlparse(ToString(arguments.thestruct.pdf_xmp.getBytes(),'utf-8'))>
	<cfset thexml = xmlSearch(thexml, "//rdf:Description/")>
	<!--- Params --->
	<cfset var thexmp = structnew()>
	<cfset thexmp.author = "">
	<cfset thexmp.rights = "">
	<cfset thexmp.AuthorsPosition = "">
	<cfset thexmp.CaptionWriter = "">
	<cfset thexmp.WebStatement = "">
	<cfset thexmp.rightsmarked = "">
	<!--- Parse the XMP --->
	<cftry>
		<cfset thexmp.author = trim(#thexml[1]["PDF:Author"].xmltext#)>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfif thexmp.author EQ "">
		<cftry>
			<cfset thexmp.author = trim(#thexml[1]["XMP-dc:Creator"].xmltext#)>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>
	<cftry>
		<cfset thexmp.rights = trim(#thexml[1]["XMP-dc:Rights"].xmltext#)>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cftry>
		<cfset thexmp.AuthorsPosition = trim(#thexml[1]["XMP-photoshop:AuthorsPosition"].xmltext#)>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cftry>
		<cfset thexmp.CaptionWriter = trim(#thexml[1]["XMP-photoshop:CaptionWriter"].xmltext#)>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cftry>
		<cfset thexmp.WebStatement = trim(#thexml[1]["XMP-xmpRights:WebStatement"].xmltext#)>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cftry>
		<cfset thexmp.rightsmarked = trim(#thexml[1]["XMP-xmpRights:Marked"].xmltext#)>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<!--- Write to DB --->
	<cfquery datasource="#application.razuna.datasource#">
	INSERT INTO #session.hostdbprefix#files_xmp
	(asset_id_r, author, rights, authorsposition, captionwriter, webstatement, rightsmarked, host_id)
	VALUES(
		<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.newid#">,
		<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#thexmp.author#">,
		<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#thexmp.rights#">,
		<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#thexmp.AuthorsPosition#">,
		<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#thexmp.CaptionWriter#">,
		<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#thexmp.WebStatement#">,
		<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#thexmp.rightsmarked#">,
		<cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
	)
	</cfquery>
	<!--- Return --->
	<cfreturn />
</cffunction>

<!--- Export metadata --->
<cffunction name="meta_export" output="true">
	<cfargument name="thestruct" type="struct">
	<!--- Feedback --->
	<cfoutput><strong>We are starting to export your data. Please wait. Once done, you can find the file to download at the bottom of this page!</strong><br /></cfoutput>
	<cfflush>
	<!--- Param --->
	<cfset arguments.thestruct.meta_fields = "id,type,filename,labels,keywords,description,iptcsubjectcode,creator,title,authorstitle,descwriter,iptcaddress,category,categorysub,urgency,iptccity,iptccountry,iptclocation,iptczip,iptcemail,iptcwebsite,iptcphone,iptcintelgenre,iptcinstructions,iptcsource,iptcusageterms,copystatus,iptcjobidentifier,copyurl,iptcheadline,iptcdatecreated,iptcimagecity,iptcimagestate,iptcimagecountry,iptcimagecountrycode,iptcscene,iptcstate,iptccredit,copynotice,pdf_author,pdf_rights,pdf_authorsposition,pdf_captionwriter,pdf_webstatement,pdf_rightsmarked">
	<!--- Set for custom fields --->
	<cfset arguments.thestruct.cf_show = "all">
	<!--- Add another query structure for gettext --->
	<cfset arguments.thestruct.qry = querynew("id")>
	<!--- Create query object to store results --->
	<cfset arguments.thestruct.tq = querynew(arguments.thestruct.meta_fields)>
	<!--- If this is from basket --->
	<cfif arguments.thestruct.what EQ "basket">
		<!--- Read Basket --->
		<cfinvoke component="basket" method="readbasket" returnvariable="thebasket">
		<!--- Loop over items in basket --->
		<cfloop query="thebasket">
			<!--- Set query --->
			<cfset QueryAddRow(arguments.thestruct.qry,1)>
			<cfset QuerySetCell(arguments.thestruct.qry, "id", cart_product_id)>
			<cfset arguments.thestruct.file_id = cart_product_id>
			<cfset arguments.thestruct.filetype = cart_file_type>
			<!--- Get the files --->
			<cfinvoke method="loopfiles" thestruct="#arguments.thestruct#" />
		</cfloop>
	<!--- If we export all assets from folder --->
	<cfelseif arguments.thestruct.what EQ "folder">
		<!--- Set local var --->
		<cfset var qry = "">
		<!--- Get id from folder with type --->
		<cfquery datasource="#application.razuna.datasource#" name="qry">
		SELECT img_id AS theid, 'img' AS thetype
		FROM #session.hostdbprefix#images
		WHERE (img_group IS NULL OR img_group = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="">) 
		<cfif arguments.thestruct.expwhat NEQ "all">
			AND folder_id_r = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.folder_id#">
		</cfif>
		AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
		UNION ALL
		SELECT vid_id AS theid, 'vid' AS thetype
		FROM #session.hostdbprefix#videos
		WHERE (vid_group IS NULL OR vid_group = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="">) 
		<cfif arguments.thestruct.expwhat NEQ "all">
			AND folder_id_r = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.folder_id#">
		</cfif>
		AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
		UNION ALL
		SELECT aud_id AS theid, 'aud' AS thetype
		FROM #session.hostdbprefix#audios
		WHERE (aud_group IS NULL OR aud_group = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="">) 
		<cfif arguments.thestruct.expwhat NEQ "all">
			AND folder_id_r = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.folder_id#">
		</cfif>
		AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
		UNION ALL
		SELECT file_id AS theid, 'doc' AS thetype
		FROM #session.hostdbprefix#files
		WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#session.hostid#">
		<cfif arguments.thestruct.expwhat NEQ "all">
			AND folder_id_r = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.folder_id#">
		</cfif>
		</cfquery>
		<!--- Loop over items in basket --->
		<cfloop query="qry">
			<!--- Set query --->
			<cfset QueryAddRow(arguments.thestruct.qry,1)>
			<cfset QuerySetCell(arguments.thestruct.qry, "id", theid)>
			<cfset arguments.thestruct.file_id = theid>
			<cfset arguments.thestruct.filetype = thetype>
			<!--- Get the files --->
			<cfinvoke method="loopfiles" thestruct="#arguments.thestruct#" />
		</cfloop>
	<!--- This is coming from a file list --->
	<cfelse>
		<!--- Loop over filelist --->
		<cfloop list="#session.file_id#" delimiters="," index="i">
			<!--- The first part is the ID the last the type --->
			<cfset arguments.thestruct.file_id = listfirst(i, "-")>
			<cfset arguments.thestruct.filetype = listlast(i, "-")>
			<!--- Set query --->
			<cfset QueryAddRow(arguments.thestruct.qry,1)>
			<cfset QuerySetCell(arguments.thestruct.qry, "id", arguments.thestruct.file_id)>
			<!--- Get the files --->
			<cfinvoke method="loopfiles" thestruct="#arguments.thestruct#" />
		</cfloop>
	</cfif>
	<!--- We got the query ready, continue export --->
	<!--- CVS --->
	<cfif arguments.thestruct.format EQ "csv">
		<cfinvoke method="export_csv" thestruct="#arguments.thestruct#" />
	<!--- XLS --->
	<cfelse>
		<!--- Add custom fields to meta fields --->
		<cfinvoke method="export_xls" thestruct="#arguments.thestruct#" />
	</cfif>
	<!--- Return --->
	<cfreturn />
</cffunction>

<!--- Loop to get files --->
<cffunction name="loopfiles" output="true">
	<cfargument name="thestruct" type="struct">
	<!--- Get the files according to the extension --->
	<cfswitch expression="#arguments.thestruct.filetype#">
		<!--- Images --->
		<cfcase value="img">
			<!--- Get asset detail --->
			<cfinvoke component="images" method="filedetail" theid="#arguments.thestruct.file_id#" thecolumn="img_filename" returnVariable="qry_image" />
			<cfset arguments.thestruct.filename = qry_image.img_filename>
			<!--- Get Lables --->
			<cfinvoke component="labels" method="getlabels" theid="#arguments.thestruct.file_id#" thetype="#arguments.thestruct.filetype#" returnVariable="arguments.thestruct.qry_labels" />
			<!--- Get Custom Fields --->
			<cfinvoke component="custom_fields" method="gettextvalues" thestruct="#arguments.thestruct#" returnVariable="arguments.thestruct.qry_cf" />
			<!--- Get keywords and description --->
			<cfinvoke component="images" method="gettext" qry="#arguments.thestruct.qry#" returnVariable="arguments.thestruct.qry_text" />
			<!--- Get XMP values --->
			<cfinvoke method="readxmpdb" thestruct="#arguments.thestruct#" returnVariable="arguments.thestruct.qry_xmp" />
			<!--- Add Values to total query --->
			<cfinvoke method="add_to_query" thestruct="#arguments.thestruct#" />
		</cfcase>
		<!--- Videos --->
		<cfcase value="vid">
			<!--- Get asset detail --->
			<cfinvoke component="videos" method="getdetails" vid_id="#arguments.thestruct.file_id#" ColumnList="v.vid_filename" returnVariable="qry_video" />
			<cfset arguments.thestruct.filename = qry_video.vid_filename>
			<!--- Get Lables --->
			<cfinvoke component="labels" method="getlabels" theid="#arguments.thestruct.file_id#" thetype="#arguments.thestruct.filetype#" returnVariable="arguments.thestruct.qry_labels" />
			<!--- Get Custom Fields --->
			<cfinvoke component="custom_fields" method="gettextvalues" thestruct="#arguments.thestruct#" returnVariable="arguments.thestruct.qry_cf" />
			<!--- Get keywords and description --->
			<cfinvoke component="videos" method="gettext" qry="#arguments.thestruct.qry#" returnVariable="arguments.thestruct.qry_text" />
			<!--- Add Values to total query --->
			<cfinvoke method="add_to_query" thestruct="#arguments.thestruct#" />
		</cfcase>
		<!--- Audios --->
		<cfcase value="aud">
			<!--- Get asset detail --->
			<cfinvoke component="audios" method="detail" thestruct="#arguments.thestruct#" returnVariable="qry_audio" />
			<cfset arguments.thestruct.filename = qry_audio.detail.aud_name>
			<cftry>
				<cfset var audarray = ArrayNew(1)>
				<cfset audarray[1] = qry_audio.desc.aud_keywords>
				<cfset QueryAddcolumn(qry_audio.desc, "keywords", "varchar", audarray)>
				<cfset audarray[1] = qry_audio.desc.aud_description>
				<cfset QueryAddcolumn(qry_audio.desc, "description", "varchar", audarray)>
				<cfcatch type="any">
					<cfset QuerySetCell(qry_audio.desc, "keywords", qry_audio.desc.aud_keywords)>
					<cfset QuerySetCell(qry_audio.desc, "description", qry_audio.desc.aud_description)>
				</cfcatch>
			</cftry>
			<cfset arguments.thestruct.qry_text = qry_audio.desc>
			<!--- Get Lables --->
			<cfinvoke component="labels" method="getlabels" theid="#arguments.thestruct.file_id#" thetype="#arguments.thestruct.filetype#" returnVariable="arguments.thestruct.qry_labels" />
			<!--- Get Custom Fields --->
			<cfinvoke component="custom_fields" method="gettextvalues" thestruct="#arguments.thestruct#" returnVariable="arguments.thestruct.qry_cf" />
			<!--- Add Values to total query --->
			<cfinvoke method="add_to_query" thestruct="#arguments.thestruct#" />
		</cfcase>
		<!--- All other files --->
		<cfdefaultcase>
			<!--- Get asset detail --->
			<cfinvoke component="files" method="filedetail" theid="#arguments.thestruct.file_id#" thecolumn="file_name" returnVariable="qry_doc" />
			<cfset arguments.thestruct.filename = qry_doc.file_name>
			<!--- Get Lables --->
			<cfinvoke component="labels" method="getlabels" theid="#arguments.thestruct.file_id#" thetype="#arguments.thestruct.filetype#" returnVariable="arguments.thestruct.qry_labels" />
			<!--- Get Custom Fields --->
			<cfinvoke component="custom_fields" method="gettextvalues" thestruct="#arguments.thestruct#" returnVariable="arguments.thestruct.qry_cf" />
			<!--- Get keywords and description --->
			<cfinvoke component="files" method="gettext" qry="#arguments.thestruct.qry#" returnVariable="arguments.thestruct.qry_text" />
			<!--- Get PDF XMP --->
			<cfinvoke component="files" method="getpdfxmp" thestruct="#arguments.thestruct#" returnVariable="arguments.thestruct.qry_pdfxmp" />
			<!--- Add Values to total query --->
			<cfinvoke method="add_to_query" thestruct="#arguments.thestruct#" />
		</cfdefaultcase>
	</cfswitch>
	<!--- Feedback --->
	<cfoutput><strong> .</strong></cfoutput>
	<cfflush>
	<!--- Return --->
	<cfreturn />
</cffunction>

<!--- Export CSV --->
<cffunction name="export_csv" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Create CSV --->
	<cfset var csv = csvwrite(arguments.thestruct.tq)>
	<!--- Write file to file system --->
	<cffile action="write" file="#arguments.thestruct.thepath#/outgoing/razuna-metadata-export-#session.hostid#-#session.theuserid#.csv" output="#csv#" charset="utf-8" nameConflict="MakeUnique">
	<!--- Serve the file --->
	<!--- <cfcontent type="application/force-download" variable="#csv#"> --->
	<!--- Feedback --->
	<cfoutput><p><a href="outgoing/razuna-metadata-export-#session.hostid#-#session.theuserid#.csv"><strong style="color:green;">Here is your downloadable file</strong></a></p></cfoutput>
	<cfflush>
	<!--- Call function to remove older files --->
	<cfinvoke method="remove_files" thestruct="#arguments.thestruct#" />
	<!--- Return --->
	<cfreturn />
</cffunction>

<!--- Export CLS --->
<cffunction name="export_xls" output="true">
	<cfargument name="thestruct" type="struct">
	<!--- Create Spreadsheet --->
	<cfif arguments.thestruct.format EQ "xls">
		<cfset var sxls = spreadsheetnew()>
	<cfelseif arguments.thestruct.format EQ "xlsx">
		<cfset var sxls = spreadsheetnew(true)>
	</cfif>
	<!--- Create header row --->
	<cfset SpreadsheetAddrow(sxls, arguments.thestruct.meta_fields, 1)>
	<cfset SpreadsheetFormatRow(sxls, {bold=TRUE, alignment="left"}, 1)>
	<cfset SpreadsheetColumnfittosize(sxls, "1-#len(arguments.thestruct.meta_fields)#")>
	<cfset SpreadsheetSetcolumnwidth(sxls, 1, 10000)>
	<!--- Add orders from query --->
	<cfset SpreadsheetAddRows(sxls, arguments.thestruct.tq, 2)> 
	<cfset SpreadsheetFormatrow(sxls, {textwrap=false, alignment="vertical_top"}, 2)>
	<!--- Write file to file system --->
	<cfset SpreadsheetWrite(sxls,"#arguments.thestruct.thepath#/outgoing/razuna-metadata-export-#session.hostid#-#session.theuserid#.#arguments.thestruct.format#",true)>
	<!--- Serve the file --->
    <!--- <cfcontent type="application/force-download" variable="#SpreadsheetReadbinary(sxls)#"> --->
	<!--- Feedback --->
	<cfoutput><p><a href="outgoing/razuna-metadata-export-#session.hostid#-#session.theuserid#.#arguments.thestruct.format#"><strong style="color:green;">Here is your downloadable file</strong></a></p></cfoutput>
	<cfflush>
	<!--- Call function to remove older files --->
	<cfinvoke method="remove_files" thestruct="#arguments.thestruct#" />
	<!--- Return --->
	<cfreturn />
</cffunction>

<!--- Remove old export files --->
<cffunction name="remove_files" output="no">
	<cfargument name="thestruct" type="struct">
	<cftry>
		<!--- Set time for remove --->
		<cfset removetime = DateAdd("h", -6, "#now()#")>
		<!--- Now check directory on the hard drive. This will fix issue with files that were not successfully uploaded thus missing in the temp db --->
		<cfdirectory action="list" directory="#arguments.thestruct.thepath#/outgoing" name="thefiles" type="file">
		<!--- Loop over dirs --->
		<cfloop query="thefiles">
			<cfif datelastmodified LT removetime AND FileExists("#arguments.thestruct.thepath#/outgoing/#name#")>
				<cffile action="delete" file="#arguments.thestruct.thepath#/outgoing/#name#">
			</cfif>
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cffunction>

<!--- Add to query --->
<cffunction name="add_to_query" output="false">
	<cfargument name="thestruct" type="struct">
	<!--- Add row local query --->
	<cfset QueryAddRow(arguments.thestruct.tq,1)>
	<!--- Add id --->
	<cfset QuerySetCell(arguments.thestruct.tq, "id", arguments.thestruct.file_id)>
	<!--- Add type --->
	<cfset QuerySetCell(arguments.thestruct.tq, "type", arguments.thestruct.filetype)>
	<!--- Add filename --->
	<cfset QuerySetCell(arguments.thestruct.tq, "filename", arguments.thestruct.filename)>
	<!--- Add Labels --->
	<cfif arguments.thestruct.qry_labels NEQ "">
		<cfset QuerySetCell(arguments.thestruct.tq, "labels", arguments.thestruct.qry_labels)>
	</cfif>
	<!--- Add custom fields --->
	<cfloop query="arguments.thestruct.qry_cf">
		<!--- Replace foreign chars in column names --->
		<cfset cfcolumn = REReplace(cf_text, "([^[:word:]^-]+)", "_", "ALL")>
		<!--- Query the query first to see if there is already a column with this custom field there. If not then add column else set cell --->
		<cfquery name="qcf" dbtype="query">
		SELECT *
		FROM arguments.thestruct.tq
		WHERE id = '#arguments.thestruct.file_id#'
		</cfquery>
		<!--- Check if the above query returns the custom text column in the columnlist --->
		<cfset qhas = ListContainsNoCase(qcf.columnlist, cfcolumn)>
		<!--- This will either return a 0 (for not found) --->
		<cfif qhas EQ 0>
			<!--- Add new column with value --->
			<cfset MyArray = ArrayNew(1)>
			<cfset MyArray[1] = "">
			<cfset QueryAddcolumn(arguments.thestruct.tq, cfcolumn, "varchar", MyArray)>
			<cfset arguments.thestruct.meta_fields = arguments.thestruct.meta_fields & "," & cfcolumn>
		</cfif>
		<!--- Set Cell --->
		<cfset QuerySetCell(arguments.thestruct.tq, cfcolumn, cf_value)>
	</cfloop>
	<!--- Add keywords and description --->
	<cfif arguments.thestruct.qry_text.recordcount NEQ 0>
		<cfloop query="arguments.thestruct.qry_text">
			<cfset QuerySetCell(arguments.thestruct.tq, "keywords", keywords)>
			<cfset QuerySetCell(arguments.thestruct.tq, "description", description)>
		</cfloop>
	</cfif>
	<!--- Add XMP --->
	<cfif structkeyexists(arguments.thestruct,"qry_xmp") AND arguments.thestruct.qry_xmp.recordcount NEQ 0 AND arguments.thestruct.filetype EQ "img">
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcsubjectcode", arguments.thestruct.qry_xmp.iptcsubjectcode)>
		<cfset QuerySetCell(arguments.thestruct.tq, "creator", arguments.thestruct.qry_xmp.creator)>
		<cfset QuerySetCell(arguments.thestruct.tq, "title", arguments.thestruct.qry_xmp.title)>
		<cfset QuerySetCell(arguments.thestruct.tq, "authorstitle", arguments.thestruct.qry_xmp.authorstitle)>
		<cfset QuerySetCell(arguments.thestruct.tq, "descwriter", arguments.thestruct.qry_xmp.descwriter)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcaddress", arguments.thestruct.qry_xmp.iptcaddress)>
		<cfset QuerySetCell(arguments.thestruct.tq, "category", arguments.thestruct.qry_xmp.category)>
		<cfset QuerySetCell(arguments.thestruct.tq, "categorysub", arguments.thestruct.qry_xmp.categorysub)>
		<cfset QuerySetCell(arguments.thestruct.tq, "urgency", arguments.thestruct.qry_xmp.urgency)>
		<!--- <cfset QuerySetCell(arguments.thestruct.tq, "description", arguments.thestruct.qry_xmp.description)> --->
		<cfset QuerySetCell(arguments.thestruct.tq, "iptccity", arguments.thestruct.qry_xmp.iptccity)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptccountry", arguments.thestruct.qry_xmp.iptccountry)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptclocation", arguments.thestruct.qry_xmp.iptclocation)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptczip", arguments.thestruct.qry_xmp.iptczip)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcemail", arguments.thestruct.qry_xmp.iptcemail)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcwebsite", arguments.thestruct.qry_xmp.iptcwebsite)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcphone", arguments.thestruct.qry_xmp.iptcphone)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcintelgenre", arguments.thestruct.qry_xmp.iptcintelgenre)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcinstructions", arguments.thestruct.qry_xmp.iptcinstructions)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcsource", arguments.thestruct.qry_xmp.iptcsource)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcusageterms", arguments.thestruct.qry_xmp.iptcusageterms)>
		<cfset QuerySetCell(arguments.thestruct.tq, "copystatus", arguments.thestruct.qry_xmp.copystatus)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcjobidentifier", arguments.thestruct.qry_xmp.iptcjobidentifier)>
		<cfset QuerySetCell(arguments.thestruct.tq, "copyurl", arguments.thestruct.qry_xmp.copyurl)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcheadline", arguments.thestruct.qry_xmp.iptcheadline)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcdatecreated", arguments.thestruct.qry_xmp.iptcdatecreated)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcimagecity", arguments.thestruct.qry_xmp.iptcimagecity)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcimagestate", arguments.thestruct.qry_xmp.iptcimagestate)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcimagecountry", arguments.thestruct.qry_xmp.iptcimagecountry)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcimagecountrycode", arguments.thestruct.qry_xmp.iptcimagecountrycode)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcscene", arguments.thestruct.qry_xmp.iptcscene)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptcstate", arguments.thestruct.qry_xmp.iptcstate)>
		<cfset QuerySetCell(arguments.thestruct.tq, "iptccredit", arguments.thestruct.qry_xmp.iptccredit)>
		<cfset QuerySetCell(arguments.thestruct.tq, "copynotice", arguments.thestruct.qry_xmp.copynotice)>
	<!--- For PDF XMP --->
	<cfelseif structkeyexists(arguments.thestruct,"qry_pdfxmp") AND arguments.thestruct.qry_pdfxmp.recordcount NEQ 0 AND arguments.thestruct.filetype EQ "doc">
		<cfset QuerySetCell(arguments.thestruct.tq, "pdf_author", arguments.thestruct.qry_pdfxmp.author)>
		<cfset QuerySetCell(arguments.thestruct.tq, "pdf_rights", arguments.thestruct.qry_pdfxmp.rights)>
		<cfset QuerySetCell(arguments.thestruct.tq, "pdf_authorsposition", arguments.thestruct.qry_pdfxmp.authorsposition)>
		<cfset QuerySetCell(arguments.thestruct.tq, "pdf_captionwriter", arguments.thestruct.qry_pdfxmp.captionwriter)>
		<cfset QuerySetCell(arguments.thestruct.tq, "pdf_webstatement", arguments.thestruct.qry_pdfxmp.webstatement)>
		<cfset QuerySetCell(arguments.thestruct.tq, "pdf_rightsmarked", arguments.thestruct.qry_pdfxmp.rightsmarked)>
	</cfif>
	<!--- Return --->
	<cfreturn />
</cffunction>

</cfcomponent>
