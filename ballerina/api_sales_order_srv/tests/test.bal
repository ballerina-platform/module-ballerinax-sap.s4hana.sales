// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import sap.s4hana.api_sales_order_srv.mock as _;

import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerina/test;

configurable boolean isTestOnLiveServer = os:getEnv("IS_TEST_ON_S4HANA_SERVER") == "false";

configurable string hostname = isTestOnLiveServer ? os:getEnv("HOST_NAME") : "localhost";
configurable string username = isTestOnLiveServer ? os:getEnv("USERNAME") : "admin";
configurable string password = isTestOnLiveServer ? os:getEnv("PASSWORD") : "admin";

boolean isBalBuild = os:getEnv("IS_BAL_BUILD") == "true";
string certPathPostFix = isBalBuild ? "../" : "/home/ballerina/ballerina/";

// Organizational constants
const SALES_ORDER_TYPE = "OR";
const SALES_ORGANIZATION = "1710";
const DISTRIBUTION_CHANNEL = "10";
const ORG_DIVISION = "00";

// Master Data Mapping
const SOLD_TO_PARTY = "17100001";

Client s4HanaClient = test:mock(Client);

@test:BeforeSuite
function initializeClientsForS4HanaServer() returns error? {
    if isTestOnLiveServer {
        log:printInfo("Running tests on S4HANA server");
        s4HanaClient = check new (
            {
                auth: {
                    username,
                    password
                }
            },
            hostname
        );
    } else {
        log:printInfo("Running tests on mock server");
        s4HanaClient = check new (
            {
                auth: {
                    username,
                    password
                },
                secureSocket: {
                    cert: certPathPostFix + "resources/public.crt"
                }
            },
            hostname,
            9090
        );
    }
}

@test:Config {
}
function testListA_SalesOrder() returns error? {
    CollectionOfA_SalesOrderWrapper listA_SalesOrders = check s4HanaClient->listA_SalesOrders();
    test:assertTrue(listA_SalesOrders.d?.results !is (), "The sales order is expected to be non-empty.");
}

@test:Config {
}
function testCreateSalesOrder() returns error? {
    string salesOrderId = "5999998";
    A_SalesOrderWrapper salesOrder = check s4HanaClient->createA_SalesOrder({
        SalesOrder: salesOrderId,
        SalesOrderType: SALES_ORDER_TYPE,
        SalesOrganization: SALES_ORGANIZATION,
        DistributionChannel: DISTRIBUTION_CHANNEL,
        OrganizationDivision: ORG_DIVISION,
        SoldToParty: SOLD_TO_PARTY
    });
    test:assertTrue(salesOrder.d?.SalesOrder == salesOrderId, "The sales order is expected to be created successfully.");

    // Resource clean up need to be done only on live server
    if isTestOnLiveServer {
        A_SalesOrderWrapper aSalesOrder = check s4HanaClient->getA_SalesOrder(salesOrderId);
        test:assertTrue(aSalesOrder.d?.SalesOrder == salesOrderId, "The sales order is expected to be retrieved successfully.");

        map<json> metaData = check aSalesOrder.d["__metadata"].cloneWithType();
        string eTag = <string>metaData["etag"];

        http:Response response = check s4HanaClient->deleteA_SalesOrder(salesOrderId, headers = {"If-Match": eTag});
        test:assertTrue(response.statusCode == 204, "Test resource is not cleaned properly.");
    }
}
