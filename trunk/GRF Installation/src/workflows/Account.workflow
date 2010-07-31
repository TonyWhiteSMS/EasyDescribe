<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <rules>
        <fullName>GRF Account%3AChapter Information</fullName>
        <actions>
            <name>Account_Set_Recordtype_to_Chapter</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.grf01_system_Lead_Type__c</field>
            <operation>equals</operation>
            <value>Chapter</value>
        </criteriaItems>
        <description>When an account for a Chapter is created, set the record type.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
