![Logo](./Assets/Images/VWAG_Group_Services_CO_M.png =233x48)

Tenant Management Framework <!-- omit in toc -->
===========================
*by [Volkswagen Group Services GmbH](https://volkswagen-groupservices.com)*

# 1. Introduction 
The Tenant Management Framework is a Powershell module that is able to create, update and
delete resources or settings via the Microsoft Graph API. The module provides simple
Powershell cmdlets to deploy and manage a set of predefined configuration files. The basic idea is
based on the [Active Directory Management Framework](https://admf.one>).

## 1.1. Goals
- Deliver a PowershellModule with standardized
commands to deploy Tenant configurations
- Provide a default configuration file format that is easy
to read and to manage
- Give the administrators pre-build configurations with
best practices
- Enable administrators to create a reusable tenant
configurations

## 1.2. Benefits
- Reproducable configuration
- Easy readable, storable and shareable configurations
- Enforced change documentation and versioning by
adding a source control
- Enables staging concept
- Less prone to human error
- Increased efficiency

# 2. Table of contents
- [1. Introduction](#1-introduction)
  - [1.1. Goals](#11-goals)
  - [1.2. Benefits](#12-benefits)
- [2. Table of contents](#2-table-of-contents)
- [3. Getting started](#3-getting-started)
  - [3.1. Installation](#31-installation)
  - [3.2. Importing](#32-importing)
  - [3.3. Authentication](#33-authentication)
  - [3.4. Configurations](#34-configurations)
    - [3.4.1. configuration.json](#341-configurationjson)
    - [3.4.2. Folder structure](#342-folder-structure)
    - [3.4.3. How can I create a configuration?](#343-how-can-i-create-a-configuration)
    - [3.4.4. How can I activate or deactivate a configuration?](#344-how-can-i-activate-or-deactivate-a-configuration)
    - [3.4.5. Storing configurations](#345-storing-configurations)
  - [3.5. General functions](#35-general-functions)
    - [3.5.1. Load-TmfConfiguration - Load definition files from configurations](#351-load-tmfconfiguration---load-definition-files-from-configurations)
    - [3.5.2. Get-TmfDesiredConfiguration - Show the current desired configuration](#352-get-tmfdesiredconfiguration---show-the-current-desired-configuration)
    - [3.5.3. Test-Tmf* - Test definitions against Graph](#353-test-tmf---test-definitions-against-graph)
    - [3.5.4. Invoke-Tmf* - Perform actions against Graph](#354-invoke-tmf---perform-actions-against-graph)
    - [3.5.5. Register-Tmf* - Add definitions temporarily](#355-register-tmf---add-definitions-temporarily)
  - [3.6. Resources types](#36-resources-types)
    - [3.6.1. Groups](#361-groups)
    - [3.6.2. Conditional Access Policies](#362-conditional-access-policies)
    - [3.6.3. Named Locations](#363-named-locations)
    - [3.6.4. Agreements (Terms of Use)](#364-agreements-terms-of-use)
    - [3.6.5. Entitlement Management](#365-entitlement-management)
      - [3.6.5.1. Access Package Catalogs](#3651-access-package-catalogs)
      - [3.6.5.2. Access Packages](#3652-access-packages)
    - [3.6.6. String mapping](#366-string-mapping)
  - [3.7. Examples](#37-examples)
    - [3.7.1. Example: A Conditional Access policy set and the required groups](#371-example-a-conditional-access-policy-set-and-the-required-groups)

# 3. Getting started
## 3.1. Installation
Currently we only deliver the module as a *.zip* file. Just unpack everything into one of your module directories. (eg. C:\Users\$env:USERNAME\Documents\WindowsPowerShell\Modules)
The module folder must be called TMF, otherwise the Powershell function "Import-Module" will not work.

It is also possible to just clone the repository.
```bash
git clone https://VWADO@dev.azure.com/VWADO/Tenant%20Management%20as%20Code/_git/Tenant%20Management%20Framework "Tenant Management Framework"
```

Checkout <https://docs.microsoft.com/de-de/powershell/scripting/developer/module/installing-a-powershell-module?view=powershell-7.1> for further information.

## 3.2. Importing
You can simply import the module using *Import-Module TMF* if the module has been placed in one of your module directory. (Checkout $env:PSModulePath)
It is also possible to directly import the module using *Import-Module <PATH_TO_MODULE>/TMF/TMF.psd1*

## 3.3. Authentication
We are using the Microsoft.Graph module to make changes in the targeted Azure AD Tenant. This module also has a sub-module for authentication against Microsoft Graph. You can connect using the following command.
```powershell
PS> Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"
```
https://github.com/microsoftgraph/msgraph-sdk-powershell

Please make sure you are connected to the correct Tenant before invoking configurations! 

The required scopes depend on what components (resources) you want to configure.
| Resource                                                          | Required scopes                                                                                                              
|-------------------------------------------------------------------|----------------------------------------------------------------------------------------
| Groups                                                            | Group.ReadWrite.All, GroupMember.ReadWrite.All
| Users                                                             | User.ReadWrite.All
| Named Locations                                                   | Policy.ReadWrite.ConditionalAccess
| Agreements (Terms of Use)                                         | Agreement.ReadWrite.All
| Conditional Access Policies                                       | Policy.ReadWrite.ConditionalAccess, Policy.Read.All, RoleManagement.Read.Directory, Application.Read.All, Agreement.Read.All
| Enitlement Management (Access Packages, Access Package Catalogs)  | EntitlementManagement.ReadWrite.All

You can also use *Get-TmfRequiredScope* to get the required scopes and combine it with *Connect-MgGraph*.
```powershell
PS> Connect-MgGraph -Scopes (Get-TmfRequiredScope -All)
```

## 3.4. Configurations
A Tenant Management Framework configuration is a collection of resource definition files in a predefined folder structure. The definition files describe instances of different resource types (eg. Groups, Conditional Access Policies, Named Locations) in the [JavaScript Object Notation (.json)](https://de.wikipedia.org/wiki/JavaScript_Object_Notation). 

### 3.4.1. configuration.json
Configurations always contain a *configuration.json* file at the root level. This file contains the properties that describe a configuration and is automatically created when using [*New-TmfConfiguration*](#323-how-can-i-create-a-configuration).

```json
{
    "Name":  "Example Configuration",
    "Description":  "This is a example configuration.",
    "Author":  "Mustermann, Max",
    "Weight":  50,
    "Prerequisite":  [
                        "Default Configuration"
                     ]
}
```

| Property     | Description                                                                      
|--------------|----------------------------------------------------------------------------------
| Name         | The name of the configuration. Must be uniqe when using multiple configurations.
| Description  | Description of the configuration. Here you can discribe, for which tenants this configurations should be used.
| Author       | The responsible team or person for this configuration.
| Weight       | When activating multiple configurations, the configuration with the highest weight is loaded last. This means that a resource definition will be overwriten, if the last configuration contains a definition with the same displayName.
| Prerequisite | With this setting you can define a relationship to an another configuration. For example when a configurations requires a baseline configuration. **Currently not implemented!**

### 3.4.2. Folder structure
For each supported resource type there is a subfolder. These subfolders always contain an empty .json file and example.md. 

The empty *.json* file is used to define resource instances. As an example a resource instance can be the definition of an Azure AD Security group or a Conditional Access policy. You can place multiple *.json* in a single resource type subfolder. By creating multiple *.json* files it is possible to structure resource definitions in a understandable way.

 **The folder names are mandatory for the functionality of the framework! Folders that do not represent a supported resource type will be ignored!**

The *example.md* file contains example resource instances and further information.


```markdown
# Folder structure of a newly created configuration
├───agreements
│   │   agreements.json
│   │   example.md
│   │
│   └───files
│           Example Terms of Use.pdf
│
├───conditionalAccessPolicies
│       example.md
│       policies.json
│
├───entitlementManagement
│   ├───accessPackageCatalogs
│   │       accessPackageCatalogs.json
│   │       example.md
│   │
│   └───accessPackages
│           accessPackages.json
│           example.md
│
├───groups
│       example.md
│       groups.json
│
├───namedLocations
│       example.md
│       namedLocations.json
│
└────stringMappings
        stringMappings.json
```

### 3.4.3. How can I create a configuration?
You can create new configuration by simple using the function *New-TmfConfiguration*. This function will create the required folder structure and the *configuration.json* file in the given location.
```powershell
PS> New-TmfConfiguration -Name "Example Configuration" -Description "This is an example configuration for the Tenant Management Framework!" -Author "Mustermann, Max" -Weight 50 -OutPath "$env:USERPROFILE\Desktop\Example_Configuration" -Force

[16:02:04][New-TmfConfiguration] Creating configuration directory C:\Users\***REMOVED***\Desktop\Example_Configuration. [DONE]
[16:02:04][New-TmfConfiguration] Copying template structure to C:\Users\***REMOVED***\Desktop\Example_Configuration. [DONE]
[16:02:05][Activate-TmfConfiguration] Activating Example Configuration (C:\Users\***REMOVED***\Desktop\Example_Configuration\configuration.json). This configuration will be considered when applying Tenant configuration. [DONE]
[16:02:05][Activate-TmfConfiguration] Sorting all activated configurations by weight. [DONE]
[16:02:05][New-TmfConfiguration] Creation has finished! Have fun! [DONE]
```

The *-Force* paramter tells the functions to automatically create the target directory or overwrite a configuration at the target directory. In the example it would create the folder "Example_Configuration".

A newly created configuration will be automatically activated. This means when using *Load-TmfConfiguration* the defined resources are loaded from the *.json* files and can be directly invoked or tested against the connected tenant.

### 3.4.4. How can I activate or deactivate a configuration?
To invoke or test defined resources against a tenant, you need to activate the containing configuration at the beginning. This means that you have to tell the TMF which configurations you want it to consider in the next steps.

This activation can simply be done using *Activate-TmfConfiguration*.
```powershell
PS> Activate-TmfConfiguration "$env:USERPROFILE\Desktop\Example_Configuration" -Force

[16:10:46][Activate-TmfConfiguration] Activating Example Configuration (C:\Users\***REMOVED***\Desktop\Example_Configuration\configuration.json). This configuration will be considered when applying Tenant configuration. [DONE]
[16:10:46][Activate-TmfConfiguration] Sorting all activated configurations by weight. [DONE]
```

You can use *Get-TmfActiveConfiguration* to checkout all already activated configurations.
```powershell
PS> Get-TmfActiveConfiguration

Name         : Example Configuration
Path         : C:\Users\***REMOVED***\Desktop\Example_Configuration
Description  : This is an example configuration for the Tenant Management Framework!
Author       : Mustermann, Max
Weight       : 50
Prerequisite : {}
```

To deactivate a configuration use *Deactivate-TmfConfiguration*. After deactivating a configuration the TMF won't considere it in further steps.
```powershell
Deactivate-TmfConfiguration -Name "Example Configuration" # By name
Deactivate-TmfConfiguration -Path "$env:USERPROFILE\Desktop\Example_Configuration" # By path
Deactivate-TmfConfiguration -All # Or all activated configurations!


[16:18:08][Deactivate-TmfConfiguration] Deactivating Example Configuration. This configuration will not be considered when applying Tenant configuration. [DONE]
```

### 3.4.5. Storing configurations
We recommend you to store configurations in a git repository. By adding a source control system you get enforced documentation and versioning.
In our case we store multiple configurations (Default configuration, DEV configuration, QA configuration and so on) in a single Azure DevOps repository.

## 3.5. General functions
### 3.5.1. Load-TmfConfiguration - Load definition files from configurations
The *Load-TmfConfiguration* function checks all *.json* files from the activated configurations and registers them into a runtime store. Technically this is the same process as if you use a register function for a single resource type (eg. *Register-TmfGroup*). All loaded resource definitions are considered when using test or invoke functions.

```powershell
PS> Load-TmfConfiguration
```

### 3.5.2. Get-TmfDesiredConfiguration - Show the current desired configuration

You can check the currently loaded desired configuration with *Get-TmfDesiredConfiguration*. This returns the desired configuration as a hashtable.

```powershell
PS> Get-TmfConfiguration

Name                           Value
----                           -----
accessPackages                 {}
groups                         {@{displayName=Some group; description=This is a security group; groupTypes=System.String[]; securityEnabled=True; mailEnabled=False; mailNickname=someGroupForMembers; present=True... 
namedLocations                 {}
accessPackageCatalogs          {}
conditionalAccessPolicies      {}
agreements                     {}
stringMappings                 {}

# You can also checkout single resource definitions
PS> (Get-TmfDesiredConfiguration)["groups"]

displayName     : Some group
description     : This is a security group
groupTypes      : {}
securityEnabled : True
mailEnabled     : False
mailNickname    : someGroupForMembers
present         : True
sourceConfig    : Example Configuration
owners          : {group.owner@volkswagen.de}
members         : {max.mustermann@volkswagen.de}

# Filtering is also possible with Where-Object
(Get-TmfDesiredConfiguration)["groups"] | Where-Object {$_.displayName -eq "Some group"}

displayName     : Some group
description     : This is a security group
groupTypes      : {}
securityEnabled : True
mailEnabled     : False
mailNickname    : someGroupForMembers
present         : True
sourceConfig    : Example Configuration
owners          : {group.owner@volkswagen.de}
members         : {max.mustermann@volkswagen.de}
```

### 3.5.3. Test-Tmf* - Test definitions against Graph
It is possible to run tests for a single resource type, for an resouce type group (eg. Entitlement Management) or for a whole tenant.

If you want to only test your configured groups, you can use *Test-TmfGroup*. This will only consider all definitions of the resource type "groups".

```powershell
PS> Test-TmfGroup

ActionType           : Create
ResourceType         : Group
ResourceName         : Example group
Changes              :
Tenant               : TENANT_NAME
TenantId             : d369908f-8803-46bc-90cb-3c82854ddf93
DesiredConfiguration : @{displayName=Example group; description=This is an example security group; groupTypes=System.String[]; securityEnabled=True; mailEnabled=False; mailNickname=someGroupForMembers;
                       present=True; sourceConfig=Example Configuration}
GraphResource        :
```

The resource type specific test functions always return test result objects. These objects show you, which actions are required in your tenant, to achive the desired configuration.

You can test all available resource types using *Test-TmfTenant*. The *Test-TmfTenant* function and also all resource type group (eg. *Test-TmfEntitlementManagement*) functions automatically beautify the test results.

```powershell
PS> Test-TmfTenant

[20:35:51][Test-TmfTenant] Currently connected to <TENANT_NAME> (d369908f-XXXX-XXXX-90cb-3c82854ddf93)
[20:35:52][Test-TmfTenant] Starting tests for groups
[20:35:52][TMF] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (Create)
```

With *Beautify-TmfTestResult* you are able to beautify the results of any resouce type specific test command.

```powershell
PS> Test-TmfGroup | Beautify-TmfTestResult

[20:37:34][TMF] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (Create)
```

### 3.5.4. Invoke-Tmf* - Perform actions against Graph
The invoke functions are available for a single resource type, for a resouce type group (eg. Entitlement Management) or for the whole tenant. These functions are capable of creating, updating or deleting resources using Microsoft Graph. The executed actions depend on the results the test functions return.

Example based on Access Packages:
- *Invoke-TmfAccessPackage:* Only invokes actions for the defined Access Packages
- *Invoke-TmfEntitlementManagement:* Invokes the required actions for Access Packages and also for all other resource types required for Entitlement Management.
- *Invoke-TmfTenant*: Invokes the required actions for each resource type defined in your configurations.

```powershell
PS> Invoke-TmfGroup

[20:44:17][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (Create)
[20:44:17][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Completed.

PS> Invoke-TmfTenant

[20:49:46][Invoke-TmfTenant] Currently connected to TENANT_NAME (d369908f-8803-46bc-90cb-3c82854ddf93)
Is this the correct tenant? [y/n]: y
[20:49:48][Invoke-TmfTenant] Invoking groups
[20:49:49][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Required Action (NoActionRequired)
[20:49:49][Invoke-TmfGroup] [Tenant: TENANT_NAME][Group Resource: Example group] Completed.
```

### 3.5.5. Register-Tmf* - Add definitions temporarily
You can use the register functions to manually register a resource definition. When registering a resource definition it will be added to the desired configuration. 

A resource must be registered before the Tenant Management Framework can test it's configuration against the Tenant.

*The displayName property must be uniqe in the desired configuration!* Resources are searched by the displayName.


## 3.6. Resources types
The supported resources are based on the endpoints and resource types provided by [Microsoft Graph](https://developer.microsoft.com/en-us/graph).
Most of the definition files use the json syntax that the API endpoint also uses.

### 3.6.1. Groups
An example definition for a simple Azure AD security group with a predefined member and a predefined owner.

```json
{   
    "displayName": "Some group",
    "description": "This is a security group",
    "groupTypes": [],        
    "securityEnabled": true,
    "mailEnabled": false,
    "mailNickname": "someGroupForMembers",
    "members": ["max.mustermann@volkswagen.de"],
    "owners": ["group.owner@volkswagen.de"],
    "present": true
}
```

Please check the [Groups example.md](./TMF/internal/data/configuration/groups/example.md) for further information.

### 3.6.2. Conditional Access Policies
An example policy definition that would affect all members of a group to accept ToU and and provide MFA.

```json
{
    "displayName" : "Require MFA and ToU for all members of Some group",
    "excludeGroups": ["Some group for CA"],
    "excludeUsers": ["johannes.seitle@TENANT_NAME.onmicrosoft.com"],        
    "includeApplications": ["All"],        
    "includeLocations": ["All"],
    "clientAppTypes": ["browser", "mobileAppsAndDesktopClients"],
    "includePlatforms": ["All"],
    "builtInControls": ["mfa"],
    "operator": "AND",
    "termsOfUse": ["ToU for Some group"],        
    "state" : "enabledForReportingButNotEnforced",
    "present" : true
}
```

Please check the [Conditional Access Policy example.md](./TMF/internal/data/configuration/conditionalAccessPolicies/example.md) for further information.

### 3.6.3. Named Locations
An example IP Named Location definition.

```json
{
    "type": "ipNamedLocation",
    "displayName": "Untrusted IP named location",
    "isTrusted": false,
    "ipRanges": [
        {
            "@odata.type": "#microsoft.graph.iPv4CidrRange",
            "cidrAddress": "12.34.221.11/22"
        },
        {
            "@odata.type": "#microsoft.graph.iPv6CidrRange",
            "cidrAddress": "2001:0:9d38:90d6:0:0:0:0/63"
        }
    ],
    "present": true
}
```

Please check the [Named Location example.md](./TMF/internal/data/configuration/namedLocations/example.md) for further information.

### 3.6.4. Agreements (Terms of Use)

An example Agreement definition with a single PDF file added.

```json
{
  "displayName": "An example agreement with a single files",
  "isViewingBeforeAcceptanceRequired": true,
  "isPerDeviceAcceptanceRequired": false,
  "userReacceptRequiredFrequency": "P90D",
  "termsExpiration": {
    "startDateTime": "05.03.2021 00:00:00",
    "frequency": "PT1M"
  },
  "files": [
    {
      "fileName": "Example Terms of Use.pdf",
      "language": "en",
      "isDefault": true,
      "filePath": "files/Example Terms of Use.pdf"
    }
  ],
  "present": true
}
```

Please check the [Agreements example.md](./TMF/internal/data/configuration/agreements/example.md) for further information.

### 3.6.5. Entitlement Management
Entitlement Management can be done by the following resource types. For further information about Azure AD Entitlement Management you can read the official documentation: https://docs.microsoft.com/en-us/azure/active-directory/governance/entitlement-management-overview.

#### 3.6.5.1. Access Package Catalogs
A simple Access Package Catalog definition.

```json
{    
    "displayName": "Access package catalog for testing",
    "description": "Sample access package catalog",
    "isExternallyVisible": false,
    "present": true
}
```

Please check the [Access Package Catalogs example.md](./TMF/internal/data/configuration/entitlementManagement/accessPackageCatalogs/example.md) for further information.

#### 3.6.5.2. Access Packages

```json
{
    "displayName":"Access Package",
    "description":"Access Package description",
    "isHidden":true,
    "isRoleScopesVisible":true,
    "catalog":"General",
    "present":true,
    "accessPackageResources":[
        {
            "resourceIdentifier":"Some group",
            "resourceRole":"Member",
            "originSystem":"AadGroup"
        }
    ],
    "assignementPolicies":[
        {
            "displayName":"Initial policy",
            "canExtend":false,
            "durationInDays":8,
            "accessReviewSettings":{
                "isEnabled":false,
                "recurrenceType":"monthly",
                "reviewerType":"Reviewers",
                "durationInDays":14,
                "reviewers":[
                    {
                        "type":"singleUser",
                        "reference":"max.mustermann@tmacdev.onmicrosoft.com",
                        "isBackup":false
                    },
                    {
                        "type":"requestorManager",
                        "managerLevel":1,
                        "isBackup":false
                    }
                ]
            },
            "requestApprovalSettings":{
                "isApprovalRequired":true,
                "isApprovalRequiredForExtension":false,
                "isRequestorJustificationRequired":true,
                "approvalMode":"SingleStage",
                "approvalStages":[
                    {
                        "approvalStageTimeOutInDays":14,
                        "isApproverJustificationRequired":true,
                        "isEscalationEnabled":false,
                        "escalationTimeInMinutes":11520,
                        "primaryApprovers":[
                            {
                                "type":"singleUser",
                                "reference":"johannes.seitle@tmacdev.onmicrosoft.com",
                                "isBackup":false
                            }
                        ]
                    }
                ]
            },
            "requestorSettings":{
                "scopeType":"SpecificDirectorySubjects",
                "acceptRequests":true,
                "allowedRequestors":[
                    {
                        "type":"singleUser",
                        "reference":"max.mustermann@tmacdev.onmicrosoft.com",
                        "isBackup":false
                    }
                ]
            }
        }
    ]
}
```

Please check the [Access Packages example.md](./TMF/internal/data/configuration/entitlementManagement/accessPackages/example.md) for further information.

##### Access Package Resources <!-- omit in toc --> 
Access Package Resources are directly defined in the depending Access Package definition.

##### Access Package Assignement Policies <!-- omit in toc -->
Access Package Assignement Policies are directly defined the depending Access Package definition.

### 3.6.6. String mapping
String mappings can help you with parameterization of your TMF configurations.

You can create mappings between strings and the values they should be replaced with. Place the mappings in the *stringMappings.json* file in the *stringMappings* folder of your configuration.


| Property    | Description                                                                                |
|-------------|--------------------------------------------------------------------------------------------|
| name        | The name of the replacement string. Only digits (0-9) and letters (a-z A-Z) are allowed.   |
| replace     | The future value after replacing.                                                          |

```json
{
    "name": "GroupManagerName",
    "replace": "group.manager@volkswagen.de"
}
```

Currently not all resource properties are considered. All string properties on the first level are replaced. String mappings also work when resolving users (eg. group owners or members), groups (in CA policies), applications (in CA Policies), namedLocations (in CA policies), agreements (in CA policies), accessPackages, accessPackageCatalogs, accessPackageResources, accessPackageAssignementPolicies.

| Resource       | Supported properties                                                                       |
|----------------|--------------------------------------------------------------------------------------------|
| agreements     | displayName, userReacceptRequiredFrequency                                                 |
| groups         | description, mailNickname, members, owners                                                 |
| namedLocations | displayName                                                                                |


To use the string mapping in a configuration file, you need to mention it by the name you provided in curly braces. Example: *{{ GroupManagerName }}*

```json
{   
    "displayName": "Some group",
    "description": "This is a security group. The group manager is {{ GroupManagerName }}",
    "groupTypes": [],        
    "securityEnabled": true,
    "mailEnabled": false,
    "mailNickname": "someGroupForMembers",
    "members": ["max.mustermann@volkswagen.de"],
    "owners": ["group.owner@volkswagen.de"],
    "present": true
}
```

## 3.7. Examples
### 3.7.1. Example: A Conditional Access policy set and the required groups
First of all you need to create a new configuration using *New-TmfConfiguration*
```powershell
New-TmfConfiguration -Name "Simple Group Example" -Author "Mustermann, Max" -Weight 50 -OutPath "$env:USERPROFILE\Desktop\Simple_Group_Example" -Force
```
After that you need to add the definition for the include group into your configuration. We will include this group into our Conditional Access Policy. Just place the definition it into the *groups/groups.json* file in your newly created configuration.

The *groups.json* should now look like that.
```json
[
  {   
      "displayName": "Some group to include into Conditional Access",
      "description": "This is a simple security group", 
      "securityEnabled": true,
      "mailEnabled": false,
      "mailNickname": "someGroupForConditionalAccess",
      "present": true
  }
]
```
The same is possible for the exclude group. Just add an additional group definition.
```json
[
  {   
      "displayName": "Some group to include into Conditional Access",
      "description": "This is a simple security group", 
      "securityEnabled": true,
      "mailEnabled": false,
      "mailNickname": "someGroupIncludeConditionalAccess",
      "present": true
  },
  {   
      "displayName": "Some group to exclude from Conditional Access",
      "description": "This is a simple security group", 
      "securityEnabled": true,
      "mailEnabled": false,
      "mailNickname": "someGroupExcludeConditionalAccess",
      "present": true
  }
]
```
The required groups are now defined. Finally we can define our Conditional Access Policy. For this example we just want MFA required for all members of the group *Some group to include into Conditional Access*.

You can add the following example Conditional Access Policy definition to *conditionalAccessPolicies/policies.json*.

```json
{
    "displayName" : "An example Conditional Access Policy",
    "excludeGroups": ["Some group to include into Conditional Access"],
    "excludeGroups": ["Some group to exclude from Conditional Access"],        
    "includeApplications": ["All"],        
    "includeLocations": ["All"],
    "clientAppTypes": ["browser", "mobileAppsAndDesktopClients"],
    "includePlatforms": ["All"],
    "builtInControls": ["mfa"],
    "operator": "AND",
    "state" : "enabled",
    "present" : true
}
```

Now that all required resource are defined, we can invoke the required actions. Simply use *Invoke-TmfTenant* to do the actions directly or use *Test-TmfTenant* to only test the configuration without changing anything.

```powershell
Invoke-TmfTenant
```