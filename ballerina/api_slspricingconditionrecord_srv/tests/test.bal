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
import sap.s4hana.api_slspricingconditionrecord_srv.oas;

import ballerina/log;
import ballerina/os;
import ballerina/test;

configurable boolean isTestOnLiveServer = os:getEnv("IS_TEST_ON_S4HANA_SERVER") == "true";

configurable string hostname = isTestOnLiveServer ? os:getEnv("HOST_NAME") : "localhost";
configurable string username = isTestOnLiveServer ? os:getEnv("USERNAME") : "admin";
configurable string password = isTestOnLiveServer ? os:getEnv("PASSWORD") : "admin";

boolean isBalBuild = os:getEnv("IS_BAL_BUILD") == "true";
string certPathPostFix = isBalBuild ? "../" : "/home/ballerina/ballerina/";

// Condition record constants. `PPR0` is the price condition type of S/4HANA Cloud, and condition
// table `304` keys it by material, sales organization and distribution channel.
const CONDITION_TYPE = "PPR0";
const CONDITION_SEQUENTIAL_NUMBER = "1";
const CONDITION_TABLE = "304";
const CONDITION_APPLICATION = "V";

// Master data of the SAP model company, only used when testing against a live server. The material
// must not already carry a `PPR0` price for this key, otherwise the condition record cannot be created.
const MATERIAL = "HW0001";
const SALES_ORGANIZATION = "1710";
const DISTRIBUTION_CHANNEL = "10";

// SAP writes 9999-12-31 as "valid until further notice". OData V2 expects an `Edm.DateTime` to be
// written as `/Date(<milliseconds since epoch>)/`.
const NO_END_DATE = "/Date(253402214400000)/";

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
    oas:CollectionOfA_SlsPrcgConditionRecordWrapper listA_SlsPrcgConditionRecords =
        check s4HanaClient->listA_SlsPrcgConditionRecords();
    test:assertTrue(listA_SlsPrcgConditionRecords.d?.results !is (),
            "The condition records are expected to be non-empty.");
}

@test:Config {
}
function testCreateA_SlsPrcgConditionRecord() returns error? {
    string conditionRecord = "0000000123";
    oas:A_SlsPrcgConditionRecordWrapper conditionRecordWrapper = check s4HanaClient->createA_SlsPrcgConditionRecord({
        ConditionRecord: conditionRecord,
        ConditionSequentialNumber: CONDITION_SEQUENTIAL_NUMBER,
        ConditionTable: CONDITION_TABLE,
        ConditionApplication: CONDITION_APPLICATION,
        ConditionType: CONDITION_TYPE,
        // The condition table key lives on the validity entity, so it is deep inserted here.
        to_SlsPrcgCndnRecdValidity: {
            results: [
                {
                    ConditionRecord: conditionRecord,
                    ConditionValidityEndDate: NO_END_DATE,
                    ConditionType: CONDITION_TYPE,
                    ConditionApplication: CONDITION_APPLICATION,
                    Material: MATERIAL,
                    SalesOrganization: SALES_ORGANIZATION,
                    DistributionChannel: DISTRIBUTION_CHANNEL
                }
            ]
        }
    });

    // A live server assigns the condition record number internally, so only the mock echoes back the
    // number that was sent.
    string createdConditionRecord = conditionRecordWrapper.d?.ConditionRecord ?: "";
    test:assertTrue(createdConditionRecord != "",
            "The condition record is expected to be created successfully.");
    if !isTestOnLiveServer {
        test:assertEquals(createdConditionRecord, conditionRecord,
                "The mock server is expected to echo back the condition record number.");
        return;
    }

    // Resource clean up need to be done only on live server
    oas:A_SlsPrcgConditionRecordWrapper aSlsPrcgConditionRecord =
        check s4HanaClient->getA_SlsPrcgConditionRecord(createdConditionRecord);
    test:assertTrue(aSlsPrcgConditionRecord.d?.ConditionRecord == createdConditionRecord,
            "The condition record is expected to be retrieved successfully.");

    map<json> metaData = check aSlsPrcgConditionRecord.d["__metadata"].cloneWithType();
    string eTag = check metaData["etag"].ensureType();

    // The service rejects a hard delete with "Deletion not allowed. Set the deletion flag by using
    // update operations.", so the record is retired by flagging it instead.
    check s4HanaClient->patchA_SlsPrcgConditionRecord(createdConditionRecord,
            {d: {ConditionIsDeleted: true}}, headers = {"If-Match": eTag});
}
