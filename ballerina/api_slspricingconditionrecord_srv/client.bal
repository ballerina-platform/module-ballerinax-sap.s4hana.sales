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

import ballerina/http;

import ballerinax/sap.s4hana.api_slspricingconditionrecord_srv.oas;

# The `sap.s4hana.api_slspricingconditionrecord_srv` client.
#
# Wraps the generated `oas` client, which is kept as pristine, regeneratable code in the `oas`
# submodule, and adds the one thing a generated client cannot provide: a usable `$batch` operation.
# A batch body is a `multipart/mixed` envelope whose parts are complete HTTP requests, which is a
# transport encoding rather than a data shape, so the OpenAPI contract cannot describe it and the
# generated operation would otherwise hand back a raw `http:Request`.
#
# Every other operation is forwarded to the `oas` client unchanged.
public isolated client class Client {
    private final oas:Client oasClient;

    # Gets invoked to initialize the `connector`.
    #
    # + config - The configurations to be used when initializing the `connector`
    # + hostname - Hostname of the S/4HANA system, without the scheme
    # + port - Port the service is reachable on
    # + return - An error if connector initialization failed
    public isolated function init(oas:ConnectionConfig config, string hostname, int port = 443)
            returns error? {
        self.oasClient = check new (config, hostname, port);
    }

    # Send a group of requests in a single round trip.
    #
    # Entities may be passed directly, in which case each one is created in `entitySet`. Pass
    # `BatchRequest` values instead to control the method, the target and the headers per request,
    # which is what updates, deletes and reads need.
    #
    # + requests - Entities to create, or requests to send. Reads are sent as standalone parts,
    # since OData does not allow them inside a change set
    # + entitySet - Entity set the entities are created in. Ignored when `BatchRequest` values are
    # passed
    # + headers - Headers to be sent with the request
    # + atomic - Whether every write belongs to a single transaction. By default each write gets its
    # own change set, so that a rejected request does not roll back the others
    # + return - The outcome of each request, in the order they were sent, or an error if the batch
    # itself was rejected. When `atomic` is set a failed change set answers with a single error result
    # for the whole transaction, so fewer results than requests can come back
    remote isolated function performBatchOperation(BatchRequest[]|BatchEntity[] requests,
            string entitySet = "A_SlsPrcgConditionRecord", map<string|string[]> headers = {},
            boolean atomic = false) returns BatchResult[]|error {
        // `BatchRequest` is a closed record requiring `uri`, which no entity type declares, so the
        // two forms cannot be confused for one another. The cast is needed because an empty array
        // belongs to both members of the union, which stops the else branch from narrowing.
        BatchRequest[] batch;
        if requests is BatchRequest[] {
            batch = requests;
        } else {
            batch = batchCreate(entitySet, <BatchEntity[]>requests);
        }
        http:Response response =
            check self.oasClient->performBatchOperation(check buildBatchRequest(batch, atomic), headers);
        return parseBatchResults(response);
    }


    # Reads all condition supplements in the system.
    #
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listA_SlsPrcgCndnRecdSuplmnts(map<string|string[]> headers = {}, *oas:ListA_SlsPrcgCndnRecdSuplmntsQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->listA_SlsPrcgCndnRecdSuplmnts(headers, queries = queries);
    }

    # Creates one or more condition supplements.
    #
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createA_SlsPrcgCndnRecdSuplmnt(oas:CreateA_SlsPrcgCndnRecdSuplmnt payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->createA_SlsPrcgCndnRecdSuplmnt(payload, headers);
    }

    # Reads a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, map<string|string[]> headers = {}, *oas:GetA_SlsPrcgCndnRecdSuplmntQueries queries) returns oas:A_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->getA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, headers, queries = queries);
    }

    # Deletes a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + return - Success 
    remote isolated function deleteA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->deleteA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, headers);
    }

    # Updates a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + payload - New property values 
    # + return - Success 
    remote isolated function patchA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, oas:Modified\ A_SlsPrcgCndnRecdSuplmntType payload, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->patchA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, payload, headers);
    }

    # Reads validity of the condition record for a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listSlsPrcgCndnRecdValiditiesOfA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, map<string|string[]> headers = {}, *oas:ListSlsPrcgCndnRecdValiditiesOfA_SlsPrcgCndnRecdSuplmntQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecdValidityWrapper|error {
        return self.oasClient->listSlsPrcgCndnRecdValiditiesOfA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, headers, queries = queries);
    }

    # Reads the pricing scales of a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listSlsPrcgCndnRecordScalesOfA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, map<string|string[]> headers = {}, *oas:ListSlsPrcgCndnRecordScalesOfA_SlsPrcgCndnRecdSuplmntQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecordScaleWrapper|error {
        return self.oasClient->listSlsPrcgCndnRecordScalesOfA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, headers, queries = queries);
    }

    # Creates one or more pricing scales for a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createSlsPrcgCndnRecordScaleOfA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, oas:CreateA_SlsPrcgCndnRecordScale payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgCndnRecordScaleWrapper|error {
        return self.oasClient->createSlsPrcgCndnRecordScaleOfA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, payload, headers);
    }

    # Reads the pricing supplement texts of a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listSlsPrcgCndnSupplementTextsOfA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, map<string|string[]> headers = {}, *oas:ListSlsPrcgCndnSupplementTextsOfA_SlsPrcgCndnRecdSuplmntQueries queries) returns oas:CollectionOfA_SlsPrcgCndnSupplementTextWrapper|error {
        return self.oasClient->listSlsPrcgCndnSupplementTextsOfA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, headers, queries = queries);
    }

    # Creates one or more pricing supplement texts for a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createSlsPrcgCndnSupplementTextOfA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, oas:CreateA_SlsPrcgCndnSupplementText payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgCndnSupplementTextWrapper|error {
        return self.oasClient->createSlsPrcgCndnSupplementTextOfA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, payload, headers);
    }

    # Reads the condition record for a specific condition supplement.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getSlsPrcgConditionRecordOfA_SlsPrcgCndnRecdSuplmnt(string ConditionRecord, string ConditionSequentialNumber, map<string|string[]> headers = {}, *oas:GetSlsPrcgConditionRecordOfA_SlsPrcgCndnRecdSuplmntQueries queries) returns oas:A_SlsPrcgConditionRecordWrapper|error {
        return self.oasClient->getSlsPrcgConditionRecordOfA_SlsPrcgCndnRecdSuplmnt(ConditionRecord, ConditionSequentialNumber, headers, queries = queries);
    }

    # Reads validity of all condition records in the system.
    #
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listA_SlsPrcgCndnRecdValidities(map<string|string[]> headers = {}, *oas:ListA_SlsPrcgCndnRecdValiditiesQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecdValidityWrapper|error {
        return self.oasClient->listA_SlsPrcgCndnRecdValidities(headers, queries = queries);
    }

    # Reads the validity of a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionValidityEndDate - Validity end date of the condition record
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getA_SlsPrcgCndnRecdValidity(string ConditionRecord, string ConditionValidityEndDate, map<string|string[]> headers = {}, *oas:GetA_SlsPrcgCndnRecdValidityQueries queries) returns oas:A_SlsPrcgCndnRecdValidityWrapper|error {
        return self.oasClient->getA_SlsPrcgCndnRecdValidity(ConditionRecord, ConditionValidityEndDate, headers, queries = queries);
    }

    # Updates the validity period of a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionValidityEndDate - Validity end date of the condition record
    # + headers - Headers to be sent with the request 
    # + payload - New property values 
    # + return - Success 
    remote isolated function patchA_SlsPrcgCndnRecdValidity(string ConditionRecord, string ConditionValidityEndDate, oas:Modified\ A_SlsPrcgCndnRecdValidityType payload, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->patchA_SlsPrcgCndnRecdValidity(ConditionRecord, ConditionValidityEndDate, payload, headers);
    }

    # Reads the condition supplements for a specific condition record validity period.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionValidityEndDate - Validity end date of the condition record
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listSlsPrcgCndnRecdSuplmntsOfA_SlsPrcgCndnRecdValidity(string ConditionRecord, string ConditionValidityEndDate, map<string|string[]> headers = {}, *oas:ListSlsPrcgCndnRecdSuplmntsOfA_SlsPrcgCndnRecdValidityQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->listSlsPrcgCndnRecdSuplmntsOfA_SlsPrcgCndnRecdValidity(ConditionRecord, ConditionValidityEndDate, headers, queries = queries);
    }

    # Creates one or more condition supplements for a specific condition record validity period.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionValidityEndDate - Validity end date of the condition record
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createSlsPrcgCndnRecdSuplmntOfA_SlsPrcgCndnRecdValidity(string ConditionRecord, string ConditionValidityEndDate, oas:CreateA_SlsPrcgCndnRecdSuplmnt payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->createSlsPrcgCndnRecdSuplmntOfA_SlsPrcgCndnRecdValidity(ConditionRecord, ConditionValidityEndDate, payload, headers);
    }

    # Reads the condition record for a specific condition record validity period.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionValidityEndDate - Validity end date of the condition record
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getSlsPrcgConditionRecordOfA_SlsPrcgCndnRecdValidity(string ConditionRecord, string ConditionValidityEndDate, map<string|string[]> headers = {}, *oas:GetSlsPrcgConditionRecordOfA_SlsPrcgCndnRecdValidityQueries queries) returns oas:A_SlsPrcgConditionRecordWrapper|error {
        return self.oasClient->getSlsPrcgConditionRecordOfA_SlsPrcgCndnRecdValidity(ConditionRecord, ConditionValidityEndDate, headers, queries = queries);
    }

    # Reads all pricing scales in the system.
    #
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listA_SlsPrcgCndnRecordScales(map<string|string[]> headers = {}, *oas:ListA_SlsPrcgCndnRecordScalesQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecordScaleWrapper|error {
        return self.oasClient->listA_SlsPrcgCndnRecordScales(headers, queries = queries);
    }

    # Creates one or more pricing scales.
    #
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createA_SlsPrcgCndnRecordScale(oas:CreateA_SlsPrcgCndnRecordScale payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgCndnRecordScaleWrapper|error {
        return self.oasClient->createA_SlsPrcgCndnRecordScale(payload, headers);
    }

    # Reads a specific pricing scale.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + ConditionScaleLine - Current number of the line scale
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getA_SlsPrcgCndnRecordScale(string ConditionRecord, string ConditionSequentialNumber, string ConditionScaleLine, map<string|string[]> headers = {}, *oas:GetA_SlsPrcgCndnRecordScaleQueries queries) returns oas:A_SlsPrcgCndnRecordScaleWrapper|error {
        return self.oasClient->getA_SlsPrcgCndnRecordScale(ConditionRecord, ConditionSequentialNumber, ConditionScaleLine, headers, queries = queries);
    }

    # Deletes a specific pricing scale.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + ConditionScaleLine - Current number of the line scale
    # + headers - Headers to be sent with the request 
    # + return - Success 
    remote isolated function deleteA_SlsPrcgCndnRecordScale(string ConditionRecord, string ConditionSequentialNumber, string ConditionScaleLine, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->deleteA_SlsPrcgCndnRecordScale(ConditionRecord, ConditionSequentialNumber, ConditionScaleLine, headers);
    }

    # Updates a specific pricing scale.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + ConditionScaleLine - Current number of the line scale
    # + headers - Headers to be sent with the request 
    # + payload - New property values 
    # + return - Success 
    remote isolated function patchA_SlsPrcgCndnRecordScale(string ConditionRecord, string ConditionSequentialNumber, string ConditionScaleLine, oas:Modified\ A_SlsPrcgCndnRecordScaleType payload, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->patchA_SlsPrcgCndnRecordScale(ConditionRecord, ConditionSequentialNumber, ConditionScaleLine, payload, headers);
    }

    # Reads the condition supplement for a specific condition supplement pricing scale.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + ConditionScaleLine - Current number of the line scale
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getSlsPrcgCndnRecdSuplmntOfA_SlsPrcgCndnRecordScale(string ConditionRecord, string ConditionSequentialNumber, string ConditionScaleLine, map<string|string[]> headers = {}, *oas:GetSlsPrcgCndnRecdSuplmntOfA_SlsPrcgCndnRecordScaleQueries queries) returns oas:A_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->getSlsPrcgCndnRecdSuplmntOfA_SlsPrcgCndnRecordScale(ConditionRecord, ConditionSequentialNumber, ConditionScaleLine, headers, queries = queries);
    }

    # Reads the condition record for a specific pricing scale.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + ConditionScaleLine - Current number of the line scale
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getSlsPrcgConditionRecordOfA_SlsPrcgCndnRecordScale(string ConditionRecord, string ConditionSequentialNumber, string ConditionScaleLine, map<string|string[]> headers = {}, *oas:GetSlsPrcgConditionRecordOfA_SlsPrcgCndnRecordScaleQueries queries) returns oas:A_SlsPrcgConditionRecordWrapper|error {
        return self.oasClient->getSlsPrcgConditionRecordOfA_SlsPrcgCndnRecordScale(ConditionRecord, ConditionSequentialNumber, ConditionScaleLine, headers, queries = queries);
    }

    # Reads all pricing supplement texts in the system.
    #
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listA_SlsPrcgCndnSupplementTexts(map<string|string[]> headers = {}, *oas:ListA_SlsPrcgCndnSupplementTextsQueries queries) returns oas:CollectionOfA_SlsPrcgCndnSupplementTextWrapper|error {
        return self.oasClient->listA_SlsPrcgCndnSupplementTexts(headers, queries = queries);
    }

    # Creates one or more pricing supplement texts.
    #
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createA_SlsPrcgCndnSupplementText(oas:CreateA_SlsPrcgCndnSupplementText payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgCndnSupplementTextWrapper|error {
        return self.oasClient->createA_SlsPrcgCndnSupplementText(payload, headers);
    }

    # Reads a specific pricing supplement text.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + Language - Language Key
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getA_SlsPrcgCndnSupplementText(string ConditionRecord, string ConditionSequentialNumber, string Language, map<string|string[]> headers = {}, *oas:GetA_SlsPrcgCndnSupplementTextQueries queries) returns oas:A_SlsPrcgCndnSupplementTextWrapper|error {
        return self.oasClient->getA_SlsPrcgCndnSupplementText(ConditionRecord, ConditionSequentialNumber, Language, headers, queries = queries);
    }

    # Deletes a specific pricing supplement text.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + Language - Language Key
    # + headers - Headers to be sent with the request 
    # + return - Success 
    remote isolated function deleteA_SlsPrcgCndnSupplementText(string ConditionRecord, string ConditionSequentialNumber, string Language, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->deleteA_SlsPrcgCndnSupplementText(ConditionRecord, ConditionSequentialNumber, Language, headers);
    }

    # Updates a specific pricing supplement text.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + Language - Language Key
    # + headers - Headers to be sent with the request 
    # + payload - New property values 
    # + return - Success 
    remote isolated function patchA_SlsPrcgCndnSupplementText(string ConditionRecord, string ConditionSequentialNumber, string Language, oas:Modified\ A_SlsPrcgCndnSupplementTextType payload, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->patchA_SlsPrcgCndnSupplementText(ConditionRecord, ConditionSequentialNumber, Language, payload, headers);
    }

    # Reads the condition record for a specific pricing supplement text.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + Language - Language Key
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getSlsPrcgCndnRecdSuplmntOfA_SlsPrcgCndnSupplementText(string ConditionRecord, string ConditionSequentialNumber, string Language, map<string|string[]> headers = {}, *oas:GetSlsPrcgCndnRecdSuplmntOfA_SlsPrcgCndnSupplementTextQueries queries) returns oas:A_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->getSlsPrcgCndnRecdSuplmntOfA_SlsPrcgCndnSupplementText(ConditionRecord, ConditionSequentialNumber, Language, headers, queries = queries);
    }

    # Reads all condition records in the system.
    #
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listA_SlsPrcgConditionRecords(map<string|string[]> headers = {}, *oas:ListA_SlsPrcgConditionRecordsQueries queries) returns oas:CollectionOfA_SlsPrcgConditionRecordWrapper|error {
        return self.oasClient->listA_SlsPrcgConditionRecords(headers, queries = queries);
    }

    # Creates one or more condition records.
    #
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createA_SlsPrcgConditionRecord(oas:CreateA_SlsPrcgConditionRecord payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgConditionRecordWrapper|error {
        return self.oasClient->createA_SlsPrcgConditionRecord(payload, headers);
    }

    # Reads a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getA_SlsPrcgConditionRecord(string ConditionRecord, map<string|string[]> headers = {}, *oas:GetA_SlsPrcgConditionRecordQueries queries) returns oas:A_SlsPrcgConditionRecordWrapper|error {
        return self.oasClient->getA_SlsPrcgConditionRecord(ConditionRecord, headers, queries = queries);
    }

    # Deletes a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + return - Success 
    remote isolated function deleteA_SlsPrcgConditionRecord(string ConditionRecord, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->deleteA_SlsPrcgConditionRecord(ConditionRecord, headers);
    }

    # Updates a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + payload - New property values 
    # + return - Success 
    remote isolated function patchA_SlsPrcgConditionRecord(string ConditionRecord, oas:Modified\ A_SlsPrcgConditionRecordType payload, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->patchA_SlsPrcgConditionRecord(ConditionRecord, payload, headers);
    }

    # Reads the condition supplements of a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listSlsPrcgCndnRecdSuplmntsOfA_SlsPrcgConditionRecord(string ConditionRecord, map<string|string[]> headers = {}, *oas:ListSlsPrcgCndnRecdSuplmntsOfA_SlsPrcgConditionRecordQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->listSlsPrcgCndnRecdSuplmntsOfA_SlsPrcgConditionRecord(ConditionRecord, headers, queries = queries);
    }

    # Creates one or more condition supplements for a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createSlsPrcgCndnRecdSuplmntOfA_SlsPrcgConditionRecord(string ConditionRecord, oas:CreateA_SlsPrcgCndnRecdSuplmnt payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgCndnRecdSuplmntWrapper|error {
        return self.oasClient->createSlsPrcgCndnRecdSuplmntOfA_SlsPrcgConditionRecord(ConditionRecord, payload, headers);
    }

    # Reads the validity of a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listSlsPrcgCndnRecdValiditiesOfA_SlsPrcgConditionRecord(string ConditionRecord, map<string|string[]> headers = {}, *oas:ListSlsPrcgCndnRecdValiditiesOfA_SlsPrcgConditionRecordQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecdValidityWrapper|error {
        return self.oasClient->listSlsPrcgCndnRecdValiditiesOfA_SlsPrcgConditionRecord(ConditionRecord, headers, queries = queries);
    }

    # Reads the pricing scales of a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listSlsPrcgCndnRecordScalesOfA_SlsPrcgConditionRecord(string ConditionRecord, map<string|string[]> headers = {}, *oas:ListSlsPrcgCndnRecordScalesOfA_SlsPrcgConditionRecordQueries queries) returns oas:CollectionOfA_SlsPrcgCndnRecordScaleWrapper|error {
        return self.oasClient->listSlsPrcgCndnRecordScalesOfA_SlsPrcgConditionRecord(ConditionRecord, headers, queries = queries);
    }

    # Creates one or more pricing scales for a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createSlsPrcgCndnRecordScaleOfA_SlsPrcgConditionRecord(string ConditionRecord, oas:CreateA_SlsPrcgCndnRecordScale payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgCndnRecordScaleWrapper|error {
        return self.oasClient->createSlsPrcgCndnRecordScaleOfA_SlsPrcgConditionRecord(ConditionRecord, payload, headers);
    }

    # Reads the pricing record texts of a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listSlsPrcgConditionRecordTextsOfA_SlsPrcgConditionRecord(string ConditionRecord, map<string|string[]> headers = {}, *oas:ListSlsPrcgConditionRecordTextsOfA_SlsPrcgConditionRecordQueries queries) returns oas:CollectionOfA_SlsPrcgConditionRecordTextWrapper|error {
        return self.oasClient->listSlsPrcgConditionRecordTextsOfA_SlsPrcgConditionRecord(ConditionRecord, headers, queries = queries);
    }

    # Creates one or more pricing record texts for a specific condition record.
    #
    # + ConditionRecord - Number of Condition Record
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createSlsPrcgConditionRecordTextOfA_SlsPrcgConditionRecord(string ConditionRecord, oas:CreateA_SlsPrcgConditionRecordText payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgConditionRecordTextWrapper|error {
        return self.oasClient->createSlsPrcgConditionRecordTextOfA_SlsPrcgConditionRecord(ConditionRecord, payload, headers);
    }

    # Reads all pricing record texts in the system.
    #
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entities 
    remote isolated function listA_SlsPrcgConditionRecordTexts(map<string|string[]> headers = {}, *oas:ListA_SlsPrcgConditionRecordTextsQueries queries) returns oas:CollectionOfA_SlsPrcgConditionRecordTextWrapper|error {
        return self.oasClient->listA_SlsPrcgConditionRecordTexts(headers, queries = queries);
    }

    # Creates one or more pricing record texts.
    #
    # + headers - Headers to be sent with the request 
    # + payload - New entity 
    # + return - Created entity 
    remote isolated function createA_SlsPrcgConditionRecordText(oas:CreateA_SlsPrcgConditionRecordText payload, map<string|string[]> headers = {}) returns oas:A_SlsPrcgConditionRecordTextWrapper|error {
        return self.oasClient->createA_SlsPrcgConditionRecordText(payload, headers);
    }

    # Reads a specific pricing record text.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + Language - Language Key
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getA_SlsPrcgConditionRecordText(string ConditionRecord, string ConditionSequentialNumber, string Language, map<string|string[]> headers = {}, *oas:GetA_SlsPrcgConditionRecordTextQueries queries) returns oas:A_SlsPrcgConditionRecordTextWrapper|error {
        return self.oasClient->getA_SlsPrcgConditionRecordText(ConditionRecord, ConditionSequentialNumber, Language, headers, queries = queries);
    }

    # Deletes a specific pricing record text.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + Language - Language Key
    # + headers - Headers to be sent with the request 
    # + return - Success 
    remote isolated function deleteA_SlsPrcgConditionRecordText(string ConditionRecord, string ConditionSequentialNumber, string Language, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->deleteA_SlsPrcgConditionRecordText(ConditionRecord, ConditionSequentialNumber, Language, headers);
    }

    # Updates a specific pricing record text.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + Language - Language Key
    # + headers - Headers to be sent with the request 
    # + payload - New property values 
    # + return - Success 
    remote isolated function patchA_SlsPrcgConditionRecordText(string ConditionRecord, string ConditionSequentialNumber, string Language, oas:Modified\ A_SlsPrcgConditionRecordTextType payload, map<string|string[]> headers = {}) returns error? {
        return self.oasClient->patchA_SlsPrcgConditionRecordText(ConditionRecord, ConditionSequentialNumber, Language, payload, headers);
    }

    # Reads the condition record for a specific pricing record text.
    #
    # + ConditionRecord - Number of Condition Record
    # + ConditionSequentialNumber - Sequential number of the condition
    # + Language - Language Key
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + return - Retrieved entity 
    remote isolated function getSlsPrcgConditionRecordOfA_SlsPrcgConditionRecordText(string ConditionRecord, string ConditionSequentialNumber, string Language, map<string|string[]> headers = {}, *oas:GetSlsPrcgConditionRecordOfA_SlsPrcgConditionRecordTextQueries queries) returns oas:A_SlsPrcgConditionRecordWrapper|error {
        return self.oasClient->getSlsPrcgConditionRecordOfA_SlsPrcgConditionRecordText(ConditionRecord, ConditionSequentialNumber, Language, headers, queries = queries);
    }
}
