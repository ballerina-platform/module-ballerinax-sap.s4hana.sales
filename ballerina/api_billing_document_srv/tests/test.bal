// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org).
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

import sap.s4hana.api_billing_document_srv.mock as _;

import ballerina/log;
import ballerina/os;
import ballerina/test;

configurable boolean isTestOnLiveServer = os:getEnv("IS_TEST_ON_S4HANA_SERVER") == "true";

configurable string hostname = isTestOnLiveServer ? os:getEnv("HOST_NAME") : "localhost";
configurable string username = isTestOnLiveServer ? os:getEnv("USERNAME") : "admin";
configurable string password = isTestOnLiveServer ? os:getEnv("PASSWORD") : "admin";

boolean isBalBuild = os:getEnv("IS_BAL_BUILD") == "true";
string certPathPostFix = isBalBuild ? "../" : "/home/ballerina/ballerina/";

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

// Read test: runs against the mock and against a live tenant (where the list may be empty).
@test:Config {
}
function testListA_BillingDocuments() returns error? {
    CollectionOfA_BillingDocumentWrapper result = check s4HanaClient->listA_BillingDocuments({});
    test:assertTrue(result.d !is (), "Expected a billing document list payload.");
}

// Action test: Cancel is a function import, so the billing document is a quoted OData literal.
@test:Config {
    enable: !isTestOnLiveServer
}
function testCancelBillingDocument() returns error? {
    CancelWrapper result = check s4HanaClient->createCancel(BillingDocument = "'90000001'");
    CancelResult[]? results = result.d?.results;
    if results is () || results.length() == 0 {
        test:assertFail("Expected a cancel result.");
    }
    CancelResult cancelResult = results[0];
    test:assertEquals(cancelResult.BillingDocument, "90000001");
    test:assertEquals(cancelResult.CancellationBillingDocument, "90000101");
    test:assertEquals(cancelResult.SystemMessageType, "S");
}
