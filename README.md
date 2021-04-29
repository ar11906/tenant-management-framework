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
  - [3.1. Authentication](#31-authentication)
  - [3.2. Configurations](#32-configurations)
    - [3.2.1. configuration.json](#321-configurationjson)
    - [3.2.2. Folder structure](#322-folder-structure)
    - [3.2.3. How can I create a configuration?](#323-how-can-i-create-a-configuration)
    - [3.2.4. How can I activate or deactivate a configuration?](#324-how-can-i-activate-or-deactivate-a-configuration)
  - [3.3. Resources types](#33-resources-types)
    - [3.3.1. Groups](#331-groups)
    - [3.3.2. Conditional Access Policies](#332-conditional-access-policies)
    - [3.3.3. Named Locations](#333-named-locations)
    - [3.3.4. Agreements (Terms of Use)](#334-agreements-terms-of-use)
    - [3.3.5. Entitlement Management](#335-entitlement-management)
    - [3.3.6. String mapping](#336-string-mapping)
  - [3.4. General functions](#34-general-functions)
    - [3.4.1. Getting activated configurations](#341-getting-activated-configurations)
    - [3.4.2. Show the loaded desired configuration](#342-show-the-loaded-desired-configuration)
    - [3.4.3. Test functions](#343-test-functions)
    - [3.4.4. Invoke functions](#344-invoke-functions)
  - [3.5. Examples](#35-examples)
    - [3.5.1. Invoking a simple group](#351-invoking-a-simple-group)
    - [3.5.2. Invoking a Conditional Access policy set](#352-invoking-a-conditional-access-policy-set)

# 3. Getting started
## 3.1. Authentication
We are using the Microsoft.Graph module to make changes in the targeted Azure AD Tenant. This module also has a sub-module for authentication against Microsoft Graph. You can connect using the following command.
```powershell
Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All"
```
https://github.com/microsoftgraph/msgraph-sdk-powershell

Please make sure you are connected to the correct Tenant before invoking configurations! 

The required scopes depend on what components (resources) you want to configure.
| Resource                                                          | Required scopes                                                                                                              |
|-------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| Groups                                                            | Group.ReadWrite.All, GroupMember.ReadWrite.All                                                                               |
| Users                                                             | User.ReadWrite.All                                                                                                           |
| Named Locations                                                   | Policy.ReadWrite.ConditionalAccess                                                                                           |
| Agreements (Terms of Use)                                         | Agreement.ReadWrite.All                                                                                                      |
| Conditional Access Policies                                       | Policy.ReadWrite.ConditionalAccess, Policy.Read.All, RoleManagement.Read.Directory, Application.Read.All, Agreement.Read.All |
| Enitlement Management (Access Packages, Access Package Catalogs)  | EntitlementManagement.ReadWrite.All                                                                                          |

You can also use *Get-TmfRequiredScope* to get the required scopes and combine it with *Connect-MgGraph*.
```powershell
Connect-MgGraph -Scopes (Get-TmfRequiredScope -All)
```

## 3.2. Configurations
A Tenant Management Framework configuration is a collection of resource definition files in a predefined folder structure. The definition files describe instances of different resource types (eg. Groups, Conditional Access Policies, Named Locations) in the [JavaScript Object Notation (.json)](https://de.wikipedia.org/wiki/JavaScript_Object_Notation). 

### 3.2.1. configuration.json
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

### 3.2.2. Folder structure
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

### 3.2.3. How can I create a configuration?
You can create new configuration by simple using the function *New-TmfConfiguration*. This function will create the required folder structure and the *configuration.json* file in the given location.
```powershell
New-TmfConfiguration -Name "Example Configuration" -Description "This is an example configuration for the Tenant Management Framework!" -Author "Mustermann, Max" -Weight 50 -OutPath "$env:USERPROFILE\Desktop\Example_Configuration" -Force
```

The *-Force* paramter tells the functions to automatically create the target directory or overwrite a configuration at the target directory. In the example it would create the folder "Example_Configuration".

A newly created configuration will be automatically activated. This means when using *Load-TmfConfiguration* the defined resources are loaded from the *.json* files and can be directly invoked or tested against the connected tenant.

### 3.2.4. How can I activate or deactivate a configuration?

## 3.3. Resources types


### 3.3.1. Groups

### 3.3.2. Conditional Access Policies

### 3.3.3. Named Locations

### 3.3.4. Agreements (Terms of Use)

### 3.3.5. Entitlement Management

### 3.3.6. String mapping

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

Currently not all resource properties are considered. All string properties on the first level are replaced.
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

## 3.4. General functions
### 3.4.1. Getting activated configurations
### 3.4.2. Show the loaded desired configuration
### 3.4.3. Test functions
### 3.4.4. Invoke functions

## 3.5. Examples
### 3.5.1. Invoking a simple group
### 3.5.2. Invoking a Conditional Access policy set