# Salesforce to S/4 HANA Integration

This example illustrates leveraging the `sap.s4hana.api_sales_order_srv:Client` in Ballerina for S/4HANA
API interactions. It specifically showcases how to respond to a Salesforce Opportunity Close Event by automatically
generating a Sales Order in the S/4HANA SD module.

## Prerequisites

### 1. Setup the S/4HANA API

Refer to the [Setup Guide](https://central.ballerina.io/ballerinax/sap/latest#setup-guide) for necessary credentials (
hostname, username, password).

### 2. Setup the Salesforce Client

Refer to the [Setup Guide](https://central.ballerina.io/ballerinax/salesforce/latest#setup-guide) for necessary
credentials (client ID, secret, tokens).

### 3. Setup the Salesforce Listener

Refer to the [Setup Guide](https://central.ballerina.io/ballerinax/trigger.salesforce/0.10.0#prerequisites) for
necessary credentials (username, password, secret).

### 3. Configuration

Configure Salesforce and S/4HANA API credentials in `Config.toml` in the example directory:

```toml
[salesforceClientConfig]
clientId = "<Client_ID>"
clientSecret = "<Client_Secret>"
refreshToken = "<Refresh_token>"
baseUrl = "<Base_url>"
refreshUrl = "<Refresh_url>"

[salesforceListenerConfig]
username = "<Username>"
password = "<Password + Secret>"
environment = "DEVELOPER"

[s4hanaClientConfig]
hostname = "<Hostname>"
username = "<Username>"
password = "<Password>"
```

### 4. Update Constants

To simplify the examples, some of the organization structure in S/4HANA and mapping from Salesforce to S/4HANA Material
code is hardcoded.
This can be changed in the `constants.bal` file.

## Run the Example

Execute the following command to run the example:

```bash
bal run
```
