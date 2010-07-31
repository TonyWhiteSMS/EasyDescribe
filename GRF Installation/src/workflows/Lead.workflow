<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>GRF_Lead_Fundraiser_Interest_Source</fullName>
        <field>grf01_system_Lead_Type__c</field>
        <formula>&apos;Chapter&apos;</formula>
        <name>GRF Lead:Fundraiser Interest Lead Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>GRF_Lead_Set_Proposed_Event_Date</fullName>
        <field>grf01_Proposed_Event_Date__c</field>
        <formula>Date( grf01_Proposed_Event_Year__c , grf01_Proposed_Event_Month__c ,grf01_Proposed_Event_Day__c)</formula>
        <name>GRF Lead: Set Proposed Event Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>GRF Lead%3A Fundraiser Interest Creation</fullName>
        <actions>
            <name>GRF_Lead_Fundraiser_Interest_Source</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.RecordTypeId</field>
            <operation>equals</operation>
            <value>Fundraiser Interest</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.grf01_system_Lead_Type__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>On creation of a Fundraiser Interest Lead set RecordType</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>GRF Lead%3A Fundraiser Interest Rejected</fullName>
        <actions>
            <name>GRF_The_Fundraiser_Interest_Lead_has_not_been_approved_please_contact_lead</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Status</field>
            <operation>equals</operation>
            <value>Rejected</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.RecordTypeId</field>
            <operation>equals</operation>
            <value>Fundraiser Interest</value>
        </criteriaItems>
        <description>If an prospective Chapter Fundraiser is rejected or &apos;Closed and Not Converted&apos;  create a Task to remind the owner to send an email indicating as such.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>GRF Lead%3A Set Proposed Event Date</fullName>
        <actions>
            <name>GRF_Lead_Set_Proposed_Event_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workaround for Lead Conversion Shortcoming to Set Event Date</description>
        <formula>isnull(grf01_Proposed_Event_Date__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>GRF_The_Fundraiser_Interest_Lead_has_not_been_approved_please_contact_lead</fullName>
        <assignedToType>owner</assignedToType>
        <description>The Fundraising Interest Lead has been rejected. Please contact the Lead.  If you want this lead to be entered into Salesforce convert the lead without adding an Opportunity.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>true</notifyAssignee>
        <priority>High</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>Contact the Fundraiser Lead to explain rejection</subject>
    </tasks>
</Workflow>
