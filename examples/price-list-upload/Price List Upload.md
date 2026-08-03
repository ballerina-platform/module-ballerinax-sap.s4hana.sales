# Price List Upload to S/4HANA

This example illustrates leveraging the `sap.s4hana.api_slspricingconditionrecord_srv:Client` in Ballerina to publish a
price list into SAP S/4HANA. Each entry of the incoming list becomes a pricing condition record together with its
validity period and its quantity based pricing scales, created in a single request.

## Overview

Prices usually originate outside the ERP system, in a product information management system, a commerce platform or a
supplier feed. Re-entering them by hand into SAP is slow and error prone, and a price that is entered late is a price
that is invoiced wrongly.

This example takes a price list and publishes it as condition records. For every material it sends one request that
creates the condition record, the validity period it applies to, and the quantity scale that grants a lower price to
larger orders.

It demonstrates:

- **Deep insert.** The condition record header carries the rate, while the condition table key -- which material, sales
  organization and distribution channel the price applies to -- lives on the validity entity. Both are sent together
  through `to_SlsPrcgCndnRecdValidity`, so S/4HANA creates the whole condition in one transaction.
- **Quantity scales** through `to_SlsPrcgCndnRecordScale`, one line per break point.
- **Writing OData V2 dates**, which have to be sent as `/Date(<milliseconds since epoch>)/`.

### Things worth knowing before you adapt it

- **The condition type is release dependent.** S/4HANA Cloud uses `PPR0` for a price, whereas on-premise systems use
  `PR00`. Sending a condition type that the system does not define is rejected with `VK/040 Condition type ... is not
  defined`.
- **S/4HANA assigns the condition record number.** `ConditionRecord` is mandatory in the request, but a live system
  replaces it with an internally assigned number, so the number in the response is the authoritative one.
- **The base price has to be a scale line.** For a scaled condition S/4HANA derives the header rate from the first scale
  line, so the example sends the base price as a scale line starting at quantity one. S/4HANA also renumbers the stored
  scale lines, for example to 1, 4 and 7.
- **Condition records are not hard deleted.** A `DELETE` is rejected with `Deletion not allowed. Set the deletion flag by
  using update operations.`, so a record is retired by patching `ConditionIsDeleted` to `true` instead.
- **Each material may hold only one price per key and period.** Creating a second condition record for the same
  material, sales organization, distribution channel and validity period supersedes the validity of the earlier record.

## Prerequisites

### 1. Setup the S/4HANA API

Refer to the [Setup Guide](https://central.ballerina.io/ballerinax/sap/latest#setup-guide) for the necessary credentials
(hostname, username, password). This API is part of the `Pricing Data Integration (SAP_COM_0294)` communication
scenario.

### 2. Adapt the price list and the pricing configuration

`constants.bal` holds the condition type, the organizational data and the price list itself. Replace `PRICE_LIST` with
the feed of your upstream system, and make sure every material already exists in the configured sales organization and
distribution channel.

### 3. Configuration

Create a `Config.toml` file in the example directory and provide your S/4HANA credentials:

```toml
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

Each published price is logged:

```
level=INFO message="Published HW0001 at 249.00 USD per PC as condition record 0000007535 with 3 scale line(s)"
level=INFO message="Published LI0001 at 89.50 USD per PC as condition record 0000007536 with 0 scale line(s)"
level=INFO message="Published 2 of 2 price list entries."
```
