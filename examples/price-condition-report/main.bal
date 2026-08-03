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

import ballerina/io;
import ballerina/lang.regexp;
import ballerina/time;
import ballerinax/sap.s4hana.api_slspricingconditionrecord_srv as conditionrecord;
import ballerinax/sap.s4hana.api_slspricingconditionrecord_srv.oas;

configurable S4HanaClientConfig s4hanaClientConfig = ?;

// An OData filter expression restricting the report, for example "ConditionType eq 'PPR0'" to report
// on prices only. Leave it empty to report on every condition record.
configurable string conditionFilter = "";

// Number of condition records to pull into the report.
configurable int reportSize = 20;

final conditionrecord:Client conditionRecordClient = check initConditionRecordClient();

public function main() returns error? {
    oas:ListA_SlsPrcgConditionRecordsQueries queries = {
        \$top: reportSize,
        // Ask the server for the total number of matching records, not just this page.
        \$inlinecount: "allpages",
        \$orderby: ["ConditionRecord"],
        // Only pull the fields the report actually prints.
        \$select: [
            "ConditionRecord",
            "ConditionType",
            "ConditionRateValue",
            "ConditionRateValueUnit",
            "ConditionValidityStartDate",
            "ConditionValidityEndDate"
        ]
    };
    if conditionFilter.trim() != "" {
        queries.\$filter = conditionFilter;
    }

    oas:CollectionOfA_SlsPrcgConditionRecordWrapper response =
        check conditionRecordClient->listA_SlsPrcgConditionRecords(queries = queries);

    oas:A_SlsPrcgConditionRecord[] records = response.d?.results ?: [];
    if records.length() == 0 {
        io:println("No condition records matched the report criteria.");
        return;
    }

    ConditionSummary[] summaries = from oas:A_SlsPrcgConditionRecord entry in records
        select {
            conditionRecord: entry?.ConditionRecord ?: "-",
            conditionType: entry?.ConditionType ?: "-",
            rate: entry?.ConditionRateValue ?: "-",
            rateUnit: entry?.ConditionRateValueUnit ?: "",
            validFrom: toDisplayDate(entry?.ConditionValidityStartDate),
            validTo: toDisplayDate(entry?.ConditionValidityEndDate)
        };

    printReport(summaries, response.d?.__count);
}

isolated function printReport(ConditionSummary[] summaries, string? totalCount) {
    io:println("Condition record | Type | Rate            | Valid from | Valid to");
    io:println("-----------------+------+-----------------+------------+-----------");
    foreach ConditionSummary summary in summaries {
        io:println(string `${pad(summary.conditionRecord, 16)} | ${pad(summary.conditionType, 4)}`
                + string ` | ${pad(summary.rate + " " + summary.rateUnit, 15)}`
                + string ` | ${pad(summary.validFrom, 10)} | ${summary.validTo}`);
    }

    io:println(string `
Reported on ${summaries.length()} condition record(s)`
            + (totalCount is string ? string ` out of ${totalCount} matching the filter.` : "."));

    // Break the report down by condition type.
    map<int> countByType = {};
    foreach ConditionSummary summary in summaries {
        countByType[summary.conditionType] = (countByType[summary.conditionType] ?: 0) + 1;
    }
    io:println("\nBy condition type:");
    foreach [string, int] [conditionType, count] in countByType.entries() {
        io:println(string `  ${pad(conditionType, 4)} : ${count}`);
    }

    // A zero rate usually means the condition exists only to carry a tax or discount key, so it is
    // worth calling out separately in a pricing review.
    ConditionSummary[] zeroRated = from ConditionSummary summary in summaries
        where summary.rate == "0.00" || summary.rate == "0.000"
        select summary;
    io:println(string `
Condition records with a zero rate: ${zeroRated.length()}`);
    foreach ConditionSummary summary in zeroRated {
        io:println(string `  ${summary.conditionRecord} (${summary.conditionType})`);
    }
}

# Converts an OData V2 `Edm.DateTime` value into a readable date.
#
# The service serialises dates as `/Date(<milliseconds since epoch>)/`, optionally followed by a
# timezone offset, so the raw value is not directly presentable.
#
# + odataDate - Raw date value as returned by the service
# + return - The date as `yyyy-MM-dd`, or the untouched input if it cannot be parsed
isolated function toDisplayDate(string? odataDate) returns string {
    if odataDate is () {
        return "-";
    }
    regexp:Groups? groups = re `Date\((-?\d+)`.findGroups(odataDate);
    if groups is () || groups.length() < 2 {
        return odataDate;
    }
    regexp:Span? milliseconds = groups[1];
    if milliseconds is () {
        return odataDate;
    }
    int|error epochMilliseconds = int:fromString(milliseconds.substring());
    if epochMilliseconds is error {
        return odataDate;
    }
    time:Civil civil = time:utcToCivil([epochMilliseconds / 1000, 0]);
    return string `${civil.year}-${pad2(civil.month)}-${pad2(civil.day)}`;
}

isolated function pad2(int value) returns string => value < 10 ? string `0${value}` : value.toString();

isolated function pad(string value, int width) returns string {
    string padded = value;
    while padded.length() < width {
        padded += " ";
    }
    return padded;
}

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
