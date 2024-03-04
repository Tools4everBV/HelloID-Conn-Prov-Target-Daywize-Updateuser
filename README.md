
# HelloID-Conn-Prov-Target-Daywize-Updateuser

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Daywize-Updateuser](#helloid-conn-prov-target-Daywize-Updateuser)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Provisioning PowerShell V2 connector](#provisioning-powershell-v2-connector)
      - [Correlation configuration](#correlation-configuration)
      - [Field mapping](#field-mapping)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Daywize-Updateuser_ is a _target_ connector. _Daywize-Updateuser_ utilizes a set of REST API's that allow you to programmatically interact with its data.

This particular connector is _not_ a general connector for DayWize. It implementes only the specific functionality of  _updating_ Contact properties of existing Daywize accounts.
It performs no correlation . The unique user identifier (DaywizeAccountName) MUST be provided by HelloID as an input value for this connector.

 The HelloID connector uses the API endpoints listed in the table below.

| Endpoint | Description |
| -------- | ----------- |
| /employeeContact_update      |  updates conntact information for a existing account|
| /        |             |

The following lifecycle actions are available:

| Action                 | Description                                      |
| ---------------------- | ------------------------------------------------ |
| create.ps1             | Does NOT create an account in Daywize. Only generates an account reference required for HelloId |
| delete.ps1             | Not available                                    |
| disable.ps1            | Not available                                    |
| enable.ps1             | Not available                                    |
| update.ps1             | PowerShell _update_ action                       |
| configuration.json     | Configuration settings template                  |
| fieldMapping.json      | _fieldMapping.json_                              |

## Getting started

### Provisioning PowerShell V2 connector

#### Correlation configuration

This connector does _not_ use the correlation settings in helloId. It expects to get an unique DayWizeAccountName value as input from a mapped field (for the create lifecycle action)

#### Field mapping

An  default field mapping can be imported by using the _fieldMapping.json_ file.

Note, The input source for the field mapping
|FieldName| Description |
|---------|-------------|
|_DaywizeAccountName_ |  The unique name of the daywize account to update  (create) |
|_EmailAddress_   |  The new value emailaddress to update  (update, store in countdata) |
|_SSOLoginName_   |  The new value of the SSOLoginName to update (update, store in accountdata) |
|_SystemName_  | The name of the HelloId target system. Required for lookup purposes (create, update store in accountdata)|


### Connection settings

The following settings are required to connect to the API.

| Setting  | Description                        | Mandatory |
| -------- | ---------------------------------- | --------- |
| UserName | The UserName to connect to the API | Yes       |
| Password | The Password to connect to the API | Yes       |
| BaseUrl  | The URL to the API                 | Yes       |

### Prerequisites
The unique _DaywizeAccountName_ must be available on the HelloId Person

### Remarks

This connector updates only the EmailAddress and the SSOLoginName properties of the user.
The mapped field  _SystemName_ is an arbitrairy unique value required to be able to retrieve(lookup) the stored accountdata info in helloid, needed for the compare function in the update.  A good value for this field would be displayname of the created target system in HelloID.
>
## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
