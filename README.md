# HelloID-Conn-Prov-Target-X-Tend

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-X-Tend](#helloid-conn-prov-target-x-tend)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Available lifecycle actions](#available-lifecycle-actions)
    - [Field mapping](#field-mapping)
  - [Remarks](#remarks)
    - [Only correlates and updates](#only-correlates-and-updates)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-X-Tend_ is a _target_ connector. _X-Tend_ provides a set of REST API's that allow you to programmatically interact with its data.

## Getting started

### Prerequisites

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                             | Mandatory |
| ------------ | ----------------------------------------| --------- |
| ClientId     | The Client Id to connect to the API     | Yes       |
| ClientSecret | The Client Secret to connect to the API | Yes       |
| TenantId     | The Tenant Id to connect to the API     | Yes       |
| BaseUrl      | The URL to the API                      | Yes       |

### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _X-Tend_ to a person in _HelloID_.

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
- This connector is not a fully-fledged connector with a complete user lifecycle. It only correlates users based on the personnelNumber and populates the email and UPN fields in X-Tend.

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
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com/forum/helloid-connectors/provisioning/5348-helloid-conn-prov-target-x-tend)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
