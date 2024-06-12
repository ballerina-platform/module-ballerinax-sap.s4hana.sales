## Package Overview

[S/4HANA](https://www.sap.com/india/products/erp/s4hana.html) is a robust enterprise resource planning (ERP) solution,
designed for large-scale enterprises by SAP SE.

@description@

## Setup guide

1. Sign in to your S/4HANA dashboard.

2. Under the `Communication Management` section, click on the `Display Communications Scenario` title.

   ![Display Scenarios](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sap/main/docs/setup/3-1-display-scenarios.png)

3. In the search bar, type `@communication-scenario@` and select the corresponding scenario from the results.

   ![Search Sales Order](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sap/main/docs/setup/3-2-search-sales-order.png)

4. In the top right corner of the screen, click on `Create Communication Arrangement`.

   ![Click Create Arrangement](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sap/main/docs/setup/3-3-click-create-arrangement.png)

5. Enter a unique name for the arrangement.

   ![Give Arrangement Name](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sap/main/docs/setup/3-4-give-arrangement-name.png)

6. Choose an existing `Communication System` from the dropdown menu and save your arrangement.

   ![Select Existing Communication Arrangement](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sap/main/docs/setup/3-5-select-communication-system.png)

7. The hostname (`<unique id>-api.s4hana.cloud.sap`) will be displayed in the top right corner of the screen.

   ![View Hostname](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sap/main/docs/setup/3-6-view-hostname.png)

## Quickstart

To use the `@package-name@` connector in your Ballerina application, modify the `.bal` file as follows:

### Step 1: Import the module

Import the `@package-name@` module.

```ballerina
@import-statement@
```

### Step 2: Instantiate a new connector

Use the hostname and credentials to initiate a client

```ballerina
configurable string hostname = ?;
configurable string username = ?;
configurable string password = ?;

@client-init@
    hostname = hostname,
    config = {
        auth: {
            username,
            password
        }
    }
);
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

```ballerina
@api-invocation@
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Report Issues

To report bugs, request new features, start new discussions, view project boards, etc., go to
the [Ballerina library parent repository](https://github.com/ballerina-platform/ballerina-library).

## Useful Links

- Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
- Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.