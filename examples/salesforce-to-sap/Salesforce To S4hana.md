# Salesforce to S/4 HANA Integration

This example illustrates leveraging the `sap.s4hana.api_sales_order_srv:Client` in Ballerina for S/4HANA
API interactions. It specifically showcases how to respond to a Salesforce Opportunity Close Event by automatically
generating a Sales Order in the S/4HANA SD module.

## Overview

Salesforce, a leading cloud-based CRM platform, empowers organizations to streamline their sales, marketing, and customer service workflows. On the other hand, SAP S/4HANA, an advanced ERP system, enables efficient management of core business processes.

In numerous organizations, the transition of sales orders into SAP often entails cumbersome manual data entry, leading to potential inaccuracies. Moreover, the prompt creation of sales orders following the generation of new opportunities is crucial. This integration aims to automate the generation of SAP sales orders upon the creation of Salesforce opportunities, significantly reducing manual labor and enhancing data precision.

This solution actively monitors for the closing of opportunities within Salesforce. Upon detecting an opportunity closed as won, it automatically initiates the creation of a corresponding SAP sales order via the SAP API, streamlining the process.

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

### 4. Modify Configuration Constants

For ease of demonstration, certain organizational structures within S/4HANA and mappings from Salesforce to S/4HANA Material codes are predefined. To tailor these to your specific requirements, adjustments can be made in the `constants.bal` file.

## Run the Example

Execute the following command to run the example:

```bash
bal run
```

## Testing 

1. **Access an Opportunity**: In Salesforce, locate and open a specific Opportunity record.

2. **Mark as Closed Won**: Update the Opportunity's status to `Closed Won`. This action simulates the successful closure of a sales deal.

3. **Verify in SAP S/4HANA**: Log into the SAP S/4HANA system. Confirm the creation of a corresponding sales order, which should have been automatically generated in response to the Opportunity's closure in Salesforce.
