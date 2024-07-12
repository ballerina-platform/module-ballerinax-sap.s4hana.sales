# Ballerina S/4HANA Sales Connectors

[![Build](https://github.com/ballerina-platform/module-ballerinax-sap.s4hana.sales/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sap.s4hana.sales/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/ballerina-platform/module-ballerinax-sap.s4hana.sales/branch/main/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerinax-sap.s4hana.sales)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-sap.s4hana.sales/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sap.s4hana.sales/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-sap.s4hana.sales/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sap.s4hana.sales/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-sap.s4hana.sales.svg)](https://github.com/ballerina-platform/module-ballerinax-sap.s4hana.sales/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/s4hana.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fs4hana)

[S/4HANA](https://www.sap.com/india/products/erp/s4hana.html) is a robust enterprise resource planning (ERP) solution,
designed for large-scale enterprises by SAP SE.

This repository encompasses all Ballerina packages pertaining to the S/4HANA sales submodule. Notably:

1. The `ballerinax/sap.s4hana.api_salesdistrict_srv` package provides APIs that enable seamless integration with
   the [Sales District - Read API v1.0.0](https://api.sap.com/api/API_SALESDISTRICT_SRV/overview). The service contains
   sales district and sales district text nodes.

2. The `ballerinax/sap.s4hana.api_salesorganization_srv` package provides APIs that enable seamless integration with
   the [Sales Organization - Read API v1.0.0](https://api.sap.com/api/API_SALESDISTRICT_SRV/overview). The service
   allows users to read sales organization master data.

3. The `ballerinax/sap.s4hana.api_sales_order_srv` package provides APIs that enable seamless integration with
   the [Sales Order (A2X) API v1.0.0](https://api.sap.com/api/API_SALES_ORDER_SRV/overview). The service allows to
   create, read, update, and delete sales orders.

4. The `ballerinax/sap.s4hana.api_sd_sa_soldtopartydetn` package provides APIs that enable seamless integration with
   the [Sold-to Party Assignment of Sales Scheduling Agreement - Read (A2X) v1.0.0](https://api.sap.com/api/API_SD_SA_SOLDTOPARTYDETN/overview).
   The service allows users to read sold-to party assignment of sales scheduling agreement master data.

5. The `ballerinax/sap.s4hana.salesarea_0001` package provides APIs that enable seamless integration with
   the [Sales Area - Read (A2X) v1.0.0](https://api.sap.com/api/SALESAREA_0001/overview). The service allows users to
   read sales areas.

6. The `ballerinax/sap.s4hana.api_sd_incoterms_srv` package provides APIs that enable seamless integration with
   the [Incoterm - Read (A2X) v1.0.0](https://api.sap.com/api/API_SD_INCOTERMS_SRV/overview). The service allows users
   to read incoterms defined in the system.

7. The `ballerinax/sap.s4hana.api_sales_inquiry_srv` package provides APIs that enable seamless integration with
   the [Sales Inquiry - Read (A2X) API v1.0.0](https://api.sap.com/api/API_SALES_INQUIRY_SRV/overview). The service
   allows to read Sales Inquiries.

8. The `ballerinax/sap.s4hana.api_sales_quotation_srv` package provides APIs that enable seamless integration with
   the [Sales Quotation (A2X) API v1.0.0](https://api.sap.com/api/API_SALES_QUOTATION_SRV/overview). The service allows
   to create, read, update, and delete sales quotation.

9. The `ballerinax/sap.s4hana.api_sales_order_simulation_srv` package provides APIs that enable seamless integration
   with the [Sales Order - Simulate (A2X) API v1.0.0](https://api.sap.com/api/API_SALES_ORDER_SIMULATE_SRV/overview).
   The service gives you information about pricing, material availability, and the customer's credit limit. The
   simulated sales order is not saved.

10. The `ballerinax/sap.s4hana.ce_salesorder_0001` package provides APIs that enable seamless integration with
    the [Sales Order (A2X) API (ODatav4) v1.0.0](https://api.sap.com/api/CE_SALESORDER_0001/overview). The service
    allows to create, read, update, and delete sales orders.

## Issues and projects

The **Issues** and **Projects** tabs are disabled for this repository as this is part of the Ballerina library. To
report bugs, request new features, start new discussions, view project boards, etc., visit the Ballerina
library [parent repository](https://github.com/ballerina-platform/ballerina-library).

This repository only contains the source code for the package.

## Build from the source

### Prerequisites

1. Download and install Java SE Development Kit (JDK) version 17. You can download it from either of the following
   sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was
   installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

### Build options

Execute the commands below to build from the source.

1. To build all packages:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests in all packages:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To build only one specific package

   ```bash
   ./gradlew clean :sales-ballerina:<api_name>:build
   ```

   | API Name                       | Connector                                            |
   |--------------------------------|------------------------------------------------------|
   | api_salesdistrict_srv          | ballerinax/sap.s4hana.api_salesdistrict_srv          |
   | api_salesorganization_srv      | ballerinax/sap.s4hana.api_salesorganization_srv      |
   | api_sales_order_srv            | ballerinax/sap.s4hana.api_sales_order_srv            |
   | api_sd_sa_soldtopartydetn      | ballerinax/sap.s4hana.api_sd_sa_soldtopartydetn      |
   | salesarea_0001                 | ballerinax/sap.s4hana.salesarea_0001                 |
   | api_sd_incoterms_srv           | ballerinax/sap.s4hana.api_sd_incoterms_srv           |
   | api_sales_inquiry_srv          | ballerinax/sap.s4hana.api_sales_inquiry_srv          |
   | api_sales_quotation_srv        | ballerinax/sap.s4hana.api_sales_quotation_srv        |
   | api_sales_order_simulation_srv | ballerinax/sap.s4hana.api_sales_order_simulation_srv |
   | ce_salesorder_0001             | ballerinax/sap.s4hana.ce_salesorder_0001             |

5. To run tests against different environment:

   ```bash
   isTestOnLiveServer=true ./gradlew clean test 
   ```
   **Note**: `isTestOnLiveServer` is false by default, tests are run against mock server.

6. To debug packages with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

7. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

8. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

9. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`sap` package](https://lib.ballerina.io/ballerinax/sap/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
