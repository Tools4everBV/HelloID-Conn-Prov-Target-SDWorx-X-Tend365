# HelloID-Conn-Prov-Target-X-Trend

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-X-Trend](#helloid-conn-prov-target-X-Trend)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Available lifecycle actions](#available-lifecycle-actions)
    - [Field mapping](#field-mapping)
  - [Remarks](#remarks)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-X-Trend_ is a _target_ connector. _X-Trend_ provides a set of REST API's that allow you to programmatically interact with its data.

## Getting started

### Prerequisites

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                             | Mandatory |
| ------------ | ----------------------------------------| --------- |
| ClientId     | The client id to connect to the API     | Yes       |
| ClientSecret | The client secret to connect to the API | Yes       |
| TenantId     | The tenant id to connect to the API     | Yes       |
| BaseUrl      | The URL to the API                      | Yes       |
| TokenBaseUrl | The URL to retrieve an access token     | Yes       |

### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _X-Trend_ to a person in _HelloID_.

| Setting                   | Value                             |
| ------------------------- | --------------------------------- |
| Enable correlation        | `True`                            |
| Person correlation field  | `PersonContext.Person.ExternalId` |
| Account correlation field | `PersonnelNumber`                 |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

### Available lifecycle actions

The following lifecycle actions are available:

| Action                                  | Description                                                                     |
| --------------------------------------- | --------------------------------------------------------------------------------|
| create.ps1                              | Correlates an account.                                                          |
| update.ps1                              | Updates / Sets the UPN and email fields                                         |
| configuration.json                      | Contains the connection settings and general configuration for the connector.   |
| fieldMapping.json                       | Defines mappings between person fields and target system person account fields. |

### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

## Remarks

### Only correlates and updates
- This connector is not a fully fletched connector with an create, enable and disable. This connector only correlates the user based on personnelNumber and then populates the email and UPN field in X-Trend.

- Because this connector only correlated and updates, enabling correlation in the correlation configuration is necessary for this connector. 

## Development resources

### API endpoints

The following endpoints are used by the connector 

| Endpoints                    |
| ---------------------------- |
| /{tenant_id}/oauth2/token    |
| /data/SDWorkers              |

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com/forum/helloid-connectors/provisioning/5341-helloid-conn-prov-target-x-trend)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
