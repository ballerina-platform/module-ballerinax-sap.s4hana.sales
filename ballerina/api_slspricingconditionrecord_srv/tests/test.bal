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

import sap.s4hana.api_slspricingconditionrecord_srv.mock as _;

import ballerina/log;
import ballerina/os;
import ballerina/test;

configurable boolean isTestOnLiveServer = os:getEnv("IS_TEST_ON_S4HANA_SERVER") == "false";

configurable string hostname = isTestOnLiveServer ? os:getEnv("HOST_NAME") : "localhost";
configurable string username = isTestOnLiveServer ? os:getEnv("USERNAME") : "admin";
configurable string password = isTestOnLiveServer ? os:getEnv("PASSWORD") : "admin";

boolean isBalBuild = os:getEnv("IS_BAL_BUILD") == "true";
string certPathPostFix = isBalBuild ? "../" : "/home/ballerina/ballerina/";

// Condition record constants
const CONDITION_TYPE = "PR00";
const CONDITION_SEQUENTIAL_NUMBER = "01";
const CONDITION_TABLE = "304";
const CONDITION_APPLICATION = "V";

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
function testListA_SlsPrcgConditionRecords() returns error? {
    CollectionOfA_SlsPrcgConditionRecordWrapper listA_SlsPrcgConditionRecords =
        check s4HanaClient->listA_SlsPrcgConditionRecords();
    test:assertTrue(listA_SlsPrcgConditionRecords.d?.results !is (),
            "The condition records are expected to be non-empty.");
}

@test:Config {
}
function testCreateA_SlsPrcgConditionRecord() returns error? {
    string conditionRecord = "0000000123";
    A_SlsPrcgConditionRecordWrapper conditionRecordWrapper = check s4HanaClient->createA_SlsPrcgConditionRecord({
        ConditionRecord: conditionRecord,
        ConditionSequentialNumber: CONDITION_SEQUENTIAL_NUMBER,
        ConditionTable: CONDITION_TABLE,
        ConditionApplication: CONDITION_APPLICATION,
        ConditionType: CONDITION_TYPE
    });
    test:assertTrue(conditionRecordWrapper.d?.ConditionRecord == conditionRecord,
            "The condition record is expected to be created successfully.");

    // Resource clean up need to be done only on live server
    if isTestOnLiveServer {
        A_SlsPrcgConditionRecordWrapper aSlsPrcgConditionRecord =
            check s4HanaClient->getA_SlsPrcgConditionRecord(conditionRecord);
        test:assertTrue(aSlsPrcgConditionRecord.d?.ConditionRecord == conditionRecord,
                "The condition record is expected to be retrieved successfully.");

        map<json> metaData = check aSlsPrcgConditionRecord.d["__metadata"].cloneWithType();
        string eTag = <string>metaData["etag"];

        check s4HanaClient->deleteA_SlsPrcgConditionRecord(conditionRecord, headers = {"If-Match": eTag});
    }
}
