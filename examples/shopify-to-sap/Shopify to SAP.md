# Automated SAP Sales Order Creation from Shopify Orders

This example details the integration process between [Shopify](https://admin.shopify.com/), a leading e-commerce
platform, and [SAP S/4HANA](https://www.sap.com/products/erp/s4hana.html), a comprehensive ERP system. The objective is
to automate SAP sales order creation for new orders placed on Shopify, enhancing efficiency and accuracy in order
management.

## Overview

Shopify excels in facilitating online sales and customer interactions, while SAP S/4HANA streamlines core business
operations. This integration bridges the gap between e-commerce sales and enterprise resource planning, ensuring that
new orders on Shopify automatically generate corresponding sales orders in SAP S/4HANA.

The process is initiated by a Shopify webhook, which notifies a designated HTTP service endpoint whenever a new order is
placed. This triggers the automated creation of a sales order in SAP S/4HANA via its API, seamlessly connecting online
sales with the ERP system.

## Prerequisites

### 1. Setup the S/4HANA API

Refer to the [Setup Guide](https://central.ballerina.io/ballerinax/sap/latest#setup-guide) for necessary credentials (
hostname, username, password).

### 2. Setup the Shopify Store

1. Create a new Shopify partner account from https://www.shopify.com/partners.

2. Create a Shopify development
   store (https://help.shopify.com/en/partners/dashboard/managing-stores/development-stores)

3. In the development store, navigate to `Settings -> Notifications -> Webhooks`

4. Create webhooks for Order creation event. Provide the URL http://<host>:<port>/sap-bridge/order for both webhooks.

### 3. Configuration

Configure S/4HANA API credentials in `Config.toml` in the example directory:

```toml
[s4hanaClientConfig]
hostname = "<Hostname>"
username = "<Username>"
password = "<Password>"
```

### 4. Modify Configuration Constants

For ease of demonstration, certain organizational structures within S/4HANA and mappings from Shopify to S/4HANA
Material codes are predefined. To tailor these to your specific requirements, adjustments can be made in
the `constants.bal` file.

## Run the Example

Execute the following command to run the example:

```bash
bal run
```

## Testing

1. **Customer and Product Registration**: Access the development store's online view. Register a new customer and add a
   product.

2. **Order Creation**: Using the newly registered customer and product, place a new order.

3. **Verification in SAP S/4HANA**: Log into the SAP S/4HANA system and verify the presence of the sales order that was
   just created.
