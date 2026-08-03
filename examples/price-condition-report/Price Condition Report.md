# Pricing Condition Record Report

This example illustrates leveraging the `sap.s4hana.api_slspricingconditionrecord_srv:Client` in Ballerina to report on
the pricing condition records of an S/4HANA system. It reads condition records with OData query options and prints a
review of the prices that are currently on file.

## Overview

Sales pricing in SAP S/4HANA is driven by condition records: each record carries a rate for a condition type, such as a
price or a tax, and is valid for a period of time. Over the years a productive system accumulates thousands of them,
which makes it hard to answer basic questions such as which prices are on file, which of them never expire, and which
carry a zero rate.

This example pulls a page of condition records and turns them into a short report. It is read only, so it is safe to run
against a productive tenant.

It demonstrates:

- **Server side paging** with `$top`, so only the requested number of records crosses the wire.
- **Total counts** with `$inlinecount`, which returns how many records match the filter, not just how many are on the
  current page.
- **Projection** with `$select`, so the service returns only the fields the report prints.
- **Sorting** with `$orderby` and **filtering** with `$filter`, for example to report on a single condition type.
- **Decoding OData V2 dates.** The service serialises `Edm.DateTime` as `/Date(<milliseconds since epoch>)/`, which the
  example converts into a readable date. SAP writes `9999-12-31` to mean "valid until further notice".

## Prerequisites

### 1. Setup the S/4HANA API

Refer to the [Setup Guide](https://central.ballerina.io/ballerinax/sap/latest#setup-guide) for the necessary credentials
(hostname, username, password). This API is part of the `Pricing Data Integration (SAP_COM_0294)` communication
scenario.

### 2. Configuration

Create a `Config.toml` file in the example directory and provide your S/4HANA credentials:

```toml
# Optional. An OData filter expression, leave it out to report on every condition record.
conditionFilter = "ConditionType eq 'PPR0'"
# Optional. Number of condition records to pull into the report, 20 by default.
reportSize = 20

[s4hanaClientConfig]
hostname = "<unique-id>-api.s4hana.cloud.sap"
username = "<communication-user>"
password = "<communication-user-password>"
```

The `port` and `certPath` fields of `s4hanaClientConfig` only need to be set when the service is not reachable on the
default HTTPS port with a certificate the JVM already trusts, for example when running against the mock server of this
connector.

## Run the example

Execute the following command to run the example:

```bash
bal run
```

The report is printed to the console:

```
Condition record | Type | Rate            | Valid from | Valid to
-----------------+------+-----------------+------------+-----------
0000007176       | UTXJ | 100.00 %        | 2023-09-10 | 9999-12-31
0000007180       | UTXJ | 0.00 %          | 2023-09-10 | 9999-12-31

Reported on 20 condition record(s) out of 299 matching the filter.

By condition type:
  UTXJ : 20

Condition records with a zero rate: 16
```
