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

import ballerina/log;
import ballerina/random;
import ballerina/time;
import ballerinax/sap.s4hana.api_slspricingconditionrecord_srv as conditionrecord;
import ballerinax/sap.s4hana.api_slspricingconditionrecord_srv.oas;

configurable S4HanaClientConfig s4hanaClientConfig = ?;

// SAP uses 9999-12-31 to mean "valid until further notice".
const int NO_END_DATE_EPOCH_SECONDS = 253402214400;
const int SECONDS_PER_DAY = 86400;

final conditionrecord:Client conditionRecordClient = check initConditionRecordClient();

public function main() returns error? {
    // Prices are valid from the start of today until further notice.
    time:Utc now = time:utcNow();
    int validFrom = now[0] - now[0] % SECONDS_PER_DAY;

    int published = 0;
    foreach PriceListEntry entry in PRICE_LIST {
        oas:CreateA_SlsPrcgConditionRecord payload =
            check buildConditionRecord(entry, validFrom);

        oas:A_SlsPrcgConditionRecordWrapper|error created =
            conditionRecordClient->createA_SlsPrcgConditionRecord(payload);

        if created is error {
            log:printError(string `Failed to publish the price of ${entry.material}: ${created.message()}`,
                    created);
            continue;
        }

        published += 1;
        // S/4HANA assigns the condition record number internally, so the number in the response is
        // the authoritative one rather than the number that was sent.
        oas:CreateA_SlsPrcgCndnRecordScale[] scaleLines =
            payload.to_SlsPrcgCndnRecordScale?.results ?: [];
        log:printInfo(string `Published ${entry.material} at ${entry.price} ${entry.currency}`
                + string ` per ${entry.quantityUnit} as condition record `
                + string `${created.d?.ConditionRecord ?: payload.ConditionRecord}`
                + string ` with ${scaleLines.length()} scale line(s)`);
    }

    log:printInfo(string `Published ${published} of ${PRICE_LIST.length()} price list entries.`);
}

# Maps one price list entry onto a condition record, deep inserting its validity and pricing scales.
#
# The condition record header carries the rate, while the condition table key -- which material, sales
# organization and distribution channel the price applies to -- lives on the validity entity. Both are
# sent in a single request so that S/4HANA creates the whole condition in one transaction.
#
# + entry - The price list entry to publish
# + validFrom - Start of the validity period, as epoch seconds
# + return - The request payload, or an error if a condition record number could not be generated
isolated function buildConditionRecord(PriceListEntry entry, int validFrom)
        returns oas:CreateA_SlsPrcgConditionRecord|error {
    string conditionRecord = check nextConditionRecordNumber();
    string validFromDate = toODataDate(validFrom);
    string validToDate = toODataDate(NO_END_DATE_EPOCH_SECONDS);

    oas:CreateA_SlsPrcgConditionRecord payload = {
        ConditionRecord: conditionRecord,
        ConditionSequentialNumber: CONDITION_SEQUENTIAL_NUMBER,
        ConditionTable: CONDITION_TABLE,
        ConditionType: CONDITION_TYPE,
        ConditionApplication: CONDITION_APPLICATION,
        ConditionCalculationType: CONDITION_CALCULATION_TYPE,
        ConditionRateValue: entry.price.toString(),
        ConditionRateValueUnit: entry.currency,
        ConditionCurrency: entry.currency,
        ConditionQuantity: "1",
        ConditionQuantityUnit: entry.quantityUnit,
        ConditionValidityStartDate: validFromDate,
        ConditionValidityEndDate: validToDate,
        // The validity entity holds the condition table key.
        to_SlsPrcgCndnRecdValidity: {
            results: [
                {
                    ConditionRecord: conditionRecord,
                    ConditionValidityStartDate: validFromDate,
                    ConditionValidityEndDate: validToDate,
                    ConditionType: CONDITION_TYPE,
                    ConditionApplication: CONDITION_APPLICATION,
                    Material: entry.material,
                    SalesOrganization: SALES_ORGANIZATION,
                    DistributionChannel: DISTRIBUTION_CHANNEL
                }
            ]
        }
    };

    if entry.scales.length() == 0 {
        return payload;
    }

    // Quantity based scales, one line per break point.
    //
    // For a scaled condition S/4HANA derives the rate of the condition record header from the first
    // scale line, so the base price has to be sent as a scale line starting at quantity one rather
    // than being left on the header alone. S/4HANA also renumbers the scale lines it stores, so the
    // line numbers below are only the order in which the breaks are sent.
    payload.PricingScaleType = PRICING_SCALE_TYPE;
    payload.PricingScaleBasis = PRICING_SCALE_BASIS;
    PriceScale[] breakPoints = [{fromQuantity: 1, price: entry.price}, ...entry.scales];

    oas:CreateA_SlsPrcgCndnRecordScale[] scaleLines = [];
    foreach int i in 0 ..< breakPoints.length() {
        PriceScale scale = breakPoints[i];
        scaleLines.push({
            ConditionRecord: conditionRecord,
            ConditionSequentialNumber: CONDITION_SEQUENTIAL_NUMBER,
            ConditionScaleLine: pad2(i + 1),
            ConditionScaleQuantity: scale.fromQuantity.toString(),
            ConditionScaleQuantityUnit: entry.quantityUnit,
            ConditionRateValue: scale.price.toString(),
            ConditionCurrency: entry.currency
        });
    }
    payload.to_SlsPrcgCndnRecordScale = {results: scaleLines};
    return payload;
}

# Generates a condition record number in a range reserved for this demo.
#
# A productive integration would either let S/4HANA assign the number internally or take it from the
# upstream system, rather than generating one here.
#
# + return - A ten character condition record number, or an error if generation failed
isolated function nextConditionRecordNumber() returns string|error {
    int candidate = check random:createIntInRange(9000000, 9999999);
    string digits = candidate.toString();
    string padded = digits;
    while padded.length() < 10 {
        padded = "0" + padded;
    }
    return padded;
}

# Formats epoch seconds the way OData V2 expects an `Edm.DateTime` to be written.
#
# + epochSeconds - Point in time to format
# + return - The value as `/Date(<milliseconds since epoch>)/`
isolated function toODataDate(int epochSeconds) returns string => string `/Date(${epochSeconds * 1000})/`;

isolated function pad2(int value) returns string => value < 10 ? string `0${value}` : value.toString();

# Builds the connector client, adding a trusted certificate only when one is configured.
#
# + return - The initialized client, or an error if initialization failed
function initConditionRecordClient() returns conditionrecord:Client|error {
    oas:ConnectionConfig config = {
        auth: {
            username: s4hanaClientConfig.username,
            password: s4hanaClientConfig.password
        }
    };
    string? certPath = s4hanaClientConfig?.certPath;
    if certPath is string {
        config.secureSocket = {cert: certPath};
    }
    return new (config, s4hanaClientConfig.hostname, s4hanaClientConfig.port);
}
