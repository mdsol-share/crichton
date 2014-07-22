# @Title Working with subject data

Scenario

> *As an integrating system*
>
> *I want to update my subjects data*
>
> *So that I can manage my clinical data*

[examples \<examples-post-clinical-data\>]

[best practices \<update-subject-data-best-practices\>]

Assumptions
-----------

To succeed, I have satisfied these pre-requisites:

1.  I am a valid Rave User
2.  I can update clinical data in my study
3.  My subject exists in my study and can be updated
4.  The fields pre-conditions for my role have been met
5.  My Request body does not exceed the maximum request size of 1,000,000 bytes

> **note**

> To record a change code for field updates, the first change code associated with a user's role in Rave is used. If the user's role does not have a change code, no change code is used.

My POST Request
---------------

### Header

My header contains the following elements:

1.  My authentication \<authentication\>
2.  A valid Content-type of "text/xml" or "text/xml; charset=UTF-8;"

### URI

    POST https://{host}/RaveWebServices/webservice.aspx?PostODMClinicalData

URI Parameters:

<table>
<colgroup>
<col width="25%" />
<col width="31%" />
<col width="12%" />
<col width="29%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Parameter</th>
<th align="left">Description</th>
<th align="left">Mandatory?</th>
<th align="left">Notes</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">{host}</td>
<td align="left">The host name</td>
<td align="left">Yes</td>
<td align="left">usually &quot;{client}.mdsol.com&quot;</td>
</tr>
</tbody>
</table>

Example:

    POST https://my-organisation.mdsol.com/RaveWebServices/webservice.aspx?PostODMClinicalData

> **note**
>
> PostODMClinicalData is case sensitive.

### Body

My request Body is a valid ODM 1.3 transactional document \<valid-odm-transactional-document\>

My ODM document is constructed as follows [1]:

```
{.sourceCode .xml}
<?xml version="1.0" ?>     <ODM  >        <!-- "Field location Attributes" -->        <ClinicalData StudyOID="{study-oid}" >         <SubjectData SubjectKey="{subject-key}" TransactionType="Update" >           <SiteRef LocationOID="{location-oid}" />           <StudyEventData StudyEventOID="{folder-oid}" StudyEventRepeatKey="{folder-repeat-key}" TransactionType="Update" >             <FormData FormOID="{form-oid}" FormRepeatKey="{form-repeat-key}" TransactionType="Update" >               <ItemGroupData ItemGroupOID="{record-oid}" ItemGroupRepeatKey="{item-group-repeat-key}" TransactionType="Update" >                  <!-- "Field level Attributes (with variations below)" -->                  <ItemData ItemOID="{field-oid}" Value="{data}" />                </ItemGroupData>             </FormData>           </StudyEventData>         </SubjectData>       </ClinicalData>      </ODM>
```

> **note**
>
> I can only update one subject per request

Field location Attributes:

<table>
<colgroup>
<col width="15%" />
<col width="37%" />
<col width="9%" />
<col width="37%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Attribute</th>
<th align="left">Description</th>
<th align="left">Mandatory?</th>
<th align="left">Notes</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">StudyOID</td>
<td align="left">The study identifier</td>
<td align="left">Yes</td>
<td align="left">See Locating my study &lt;locate-a-study&gt;</td>
</tr>
<tr class="even">
<td align="left">SubjectKey</td>
<td align="left">The subject identifier</td>
<td align="left">Yes</td>
<td align="left">See Locating my subject &lt;locate-a-subject&gt;</td>
</tr>
<tr class="odd">
<td align="left">LocationOID</td>
<td align="left">The site identifier</td>
<td align="left">Yes</td>
<td align="left">See Locating my site &lt;locate-a-site&gt;</td>
</tr>
<tr class="even">
<td align="left">StudyEventOID</td>
<td align="left">The folder OID or &quot;SUBJECT&quot; for subject level forms</td>
<td align="left">Yes</td>
<td align="left"></td>
</tr>
<tr class="odd">
<td align="left">StudyEventRepeatKey</td>
<td align="left">The folder repeat key</td>
<td align="left">No</td>
<td align="left">See Locating my folder &lt;locate-a-folder&gt;</td>
</tr>
<tr class="even">
<td align="left">FormOID</td>
<td align="left">The form OID</td>
<td align="left">Yes</td>
<td align="left"></td>
</tr>
<tr class="odd">
<td align="left">FormRepeatKey</td>
<td align="left">The form repeat key</td>
<td align="left">No</td>
<td align="left">See Locating my form &lt;locate-a-form&gt; and Upserting my form &lt;upsert-a-form&gt;</td>
</tr>
<tr class="even">
<td align="left">ItemGroupOID</td>
<td align="left">The form OID or form OID + &quot;_LOGLINE&quot;</td>
<td align="left">Yes</td>
<td align="left"></td>
</tr>
<tr class="odd">
<td align="left">ItemGroupRepeatKey</td>
<td align="left">The log line repeat key or &quot;1&quot;</td>
<td align="left">No</td>
<td align="left">See Locating my log line &lt;locate-a-log-line&gt; and Upserting my log line &lt;upsert-a-log-line&gt;</td>
</tr>
</tbody>
</table>

Field level Attributes (with variations below):

<table>
<colgroup>
<col width="15%" />
<col width="37%" />
<col width="9%" />
<col width="37%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Attribute</th>
<th align="left">Description</th>
<th align="left">Mandatory?</th>
<th align="left">Notes</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">ItemOID</td>
<td align="left">The field OID</td>
<td align="left">Yes</td>
<td align="left">See below</td>
</tr>
<tr class="even">
<td align="left">Value</td>
<td align="left">The data</td>
<td align="left">Yes</td>
<td align="left">See below</td>
</tr>
</tbody>
</table>

### Inserting a new subject

I can create a subject, and add data to it:

-   Creating my subject in a study and site \<create-a-subject\>

### Updating Field data:

I can update fields of these data types, control types and properties:

-   Text field \<text-field\>
-   Date field \<date-field\>
-   Unit dictionary field \<unit-dictionary-field\>
-   Data dictionary drop down list \<data-dictionary-drop-down-field\>
-   Data dictionary search list \<data-dictionary-search-list-field\>
-   Data dictionary dynamic search list \<dynamic-search-list-field\>

I can update these properties on a field:

-   Workflow properties \<workflow-for-fields\> - Lock, Freeze, Verify

I can not update:

-   Other workflow properties - Sign
-   Derived fields, such as "Age".

### Updating items belonging to a field:

I can update these field items:

-   Review \<field-review\>
-   Queries \<field-queries\> - Open, Forward, Answer, Cancel, Close
-   Translations \<field-translations\>
-   Coding decisions \<field-coding-decisions\>
-   External audits \<field-external-audits\>

I cannot update:

-   Comments
-   Stickies
-   Protocol Deviations

[examples \<examples-post-clinical-data\>]

[best practices \<update-subject-data-best-practices\>]

The Response
------------

My whole transaction will either:

1.  Succeed with a HTTP Response code of 200 OK;
2.  Fail and roll back, with a 4xx or 5xx HTTP Response code and RWS error code in the response body.

<table>
<colgroup>
<col width="8%" />
<col width="21%" />
<col width="41%" />
<col width="28%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Header</th>
<th align="left">Reason</th>
<th align="left">Body</th>
<th align="left">Notes</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">200</td>
<td align="left">The transaction was successful</td>
<td align="left">XML representation of the items touched</td>
<td align="left">See Response Notes for more information on the returned XML.</td>
</tr>
<tr class="even">
<td align="left">X Y Z</td>
<td align="left">Failure reason for X Failure reason for Y Failure reason for Z</td>
<td align="left">response message</td>
<td align="left">See The Error Responses
Listing &lt;error-responses&gt;</td>
</tr>
</tbody>
</table>

### Example success response

Header:

    HTTP Response code : 200 OK

Body:

``` {.sourceCode .xml}     <Response ReferenceNumber="fa63d085-629a-419e-a19d-21d6fb2bc93b"     InboundODMFileOID="InputODM.xml"     IsTransactionSuccessful="1"     SuccessStatistics="Rave objects touched: Subjects=1; Folders=0; Forms=0; Fields=1; LogLines=0"     NewRecords=""     SubjectNumberInStudy="1"     SubjectNumberInStudySite="1">    </Response> ``\`

### Example error response

Header:

    403 HTTP Response code

Body:

``` {.sourceCode .xml}
<Response ReferenceNumber="fa63d085-629a-419e-a19d-21d6fb2bc93b"
 InboundODMFileOID="InputODM.xml"
 IsTransactionSuccessful="0"
 ReasonCode="RWS00042"
 ErrorOriginLocation="/ODM/ClinicalData[1]/SubjectData[1]/StudyEventData[1]/FormData[1]/ItemGroupData[1]/ItemData[1]"
 SuccessStatistics="Rave objects touched: Subjects=0; Folders=0; Forms=0; Fields=0; LogLines=0"
 ErrorClientResponseMessage="Field not authorised.">
</Response>
```

**Footnotes**

[1] Some attributes are omitted from the ODM document for clarity. See ODM Schema \<odm-schema\> for more details

