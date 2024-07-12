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

import sap.s4hana.api_sales_quotation_srv.mock as _;

import ballerina/log;
import ballerina/os;
import ballerina/test;

configurable boolean isTestOnLiveServer = os:getEnv("IS_TEST_ON_S4HANA_SERVER") == "false";

configurable string hostname = isTestOnLiveServer ? os:getEnv("HOST_NAME") : "localhost";
configurable string username = isTestOnLiveServer ? os:getEnv("USERNAME") : "admin";
configurable string password = isTestOnLiveServer ? os:getEnv("PASSWORD") : "admin";

boolean isBalBuild = os:getEnv("IS_BAL_BUILD") == "true";
string certPathPostFix = isBalBuild ? "../" : "/home/ballerina/ballerina/";

// Master Data Mapping
const SALES_QUOTATION_TYPE = "QT";

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
function testListA_SalesQuotation() returns error? {
    CollectionOfA_SalesQuotationWrapper listA_SalesQuotations = check s4HanaClient->listA_SalesQuotations();
    test:assertTrue(listA_SalesQuotations.d?.results !is (), "The sales quotation is expected to be non-empty.");
}

@test:Config {
}
function testCreateSalesQuotation() returns error? {
    // Verify why only this request passes, even with correct master data
    A_SalesQuotationWrapper salesQuotation = check s4HanaClient->createA_SalesQuotation({
        SalesQuotation: "",
        SalesQuotationType: SALES_QUOTATION_TYPE
    });
    test:assertTrue(salesQuotation.d?.SalesQuotation == "", "The sales quotation is expected to be created successfully.");
}
