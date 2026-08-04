// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/os;

public function main(string moduleName, string apiPostfix, string apiName = "") returns error? {
    string[] clientFileLines = check io:fileReadLines(string `../ballerina/${moduleName}/client.bal`);
    string[] updatedClientFileLines = [];
    int j = 0;

    int importFileLine = 0;
    int serviceUrlLine = 0;

    foreach int i in 0 ... clientFileLines.length() - 1 {
        if clientFileLines[i] == "import ballerina/http;" {
            importFileLine = i;
        }

        int? firstClientOccurance = clientFileLines[i].indexOf("http:Client clientEp");
        if firstClientOccurance is int {
            clientFileLines[i] = clientFileLines[i].substring(0, firstClientOccurance) + "sap:Client clientEp" +
                                clientFileLines[i].substring(firstClientOccurance + 20);
        }

        int? serviceUrlDocOccurance = clientFileLines[i].indexOf("# + serviceUrl - URL of the target service");
        if serviceUrlDocOccurance is int {
            // The signature below is rewritten to `hostname` and `port`, so the documentation has to
            // follow, otherwise doc generation reports the parameters as undocumented.
            clientFileLines[i] = "    # + hostname - Hostname of the S/4HANA system, without the scheme \n" +
                                "    # + port - Port the service is reachable on ";
        }

        int? serviceUrlOccurance = clientFileLines[i].indexOf("string serviceUrl");
        if serviceUrlOccurance is int {
            clientFileLines[i] = clientFileLines[i].substring(0, serviceUrlOccurance - 1) + "string hostname, int port = 443" +
                                clientFileLines[i].substring(serviceUrlOccurance + 17);
            serviceUrlLine = i;
        }

        int? secondClientOccurance = clientFileLines[i].indexOf("http:Client httpEp");
        if secondClientOccurance is int {
            clientFileLines[i] = clientFileLines[i].substring(0, secondClientOccurance) + "sap:Client httpEp" +
                                clientFileLines[i].substring(secondClientOccurance + 18);
            break;
        }
    }

    foreach int i in 0 ... clientFileLines.length() - 1 {
        if i == importFileLine {
            updatedClientFileLines[j] = clientFileLines[i];
            updatedClientFileLines[j + 1] = "import ballerinax/sap;";
            j = j + 2;
        } else if i == serviceUrlLine {
            updatedClientFileLines[j] = clientFileLines[i];
            string replaceText = "string serviceUrl = string `https://${hostname}:${port}/" + apiPostfix + "`;";
            updatedClientFileLines[j + 1] = replaceText;
            j = j + 2;
        } else {
            updatedClientFileLines[j] = clientFileLines[i];
            j = j + 1;
        }
    }

    check io:fileWriteLines(string `../ballerina/${moduleName}/client.bal`, updatedClientFileLines);

    if apiName != "" {
        check restoreOperationIdBasedNames(moduleName, apiName);
    }

    _ = check os:exec(command = {
                value: "bal",
                arguments: ["format", "../ballerina/" + moduleName]
            });

    _ = check os:exec(command = {
                value: "bal",
                arguments: ["build", "../ballerina/" + moduleName]
            });
}

# Renames the generated identifiers back to the sanitized `operationId`s.
#
# The OpenAPI tool drops underscores when it derives Ballerina identifiers from an
# `operationId`, which loses the `A_<EntitySet>` naming that the S/4HANA connectors use,
# for example `listA_SlsPrcgConditionRecords` is generated as `listASlsPrcgConditionRecords`.
# Schema based type names keep the underscore, so without this the client is inconsistent
# with both `types.bal` and the other connectors in this repository.
#
# + moduleName - Name of the module holding the generated client
# + apiName - Name of the sanitized specification under `spec`
# + return - An error if the generated sources could not be updated
function restoreOperationIdBasedNames(string moduleName, string apiName) returns error? {
    json openAPISpec = check io:fileReadJson(string `spec/${apiName}.json`);
    map<json> paths = check openAPISpec.paths.ensureType();

    map<string> renames = {};
    foreach json pathItem in paths {
        map<json> operations = check pathItem.ensureType();
        foreach [string, json] [method, operation] in operations.entries() {
            if method == "parameters" {
                continue;
            }
            map<json> operationDetails = check operation.ensureType();
            json? operationId = operationDetails["operationId"];
            if operationId !is string || !operationId.includes("_") {
                continue;
            }
            string generatedName = re `_`.replaceAll(operationId, "");
            renames[generatedName] = operationId;
            // The query parameter record of an operation is named after the operation itself.
            renames[capitalize(generatedName) + "Queries"] = capitalize(operationId) + "Queries";
        }
    }

    // Longer names are replaced first, so that an operation name that is a prefix of another
    // one, such as `getA_SlsPrcgConditionRecord` and `getA_SlsPrcgConditionRecordText`, does
    // not corrupt the longer name.
    string[] generatedNames = from string name in renames.keys()
        order by name.length() descending
        select name;

    foreach string file in ["client.bal", "types.bal"] {
        string path = string `../ballerina/${moduleName}/${file}`;
        string content = check io:fileReadString(path);
        foreach string generatedName in generatedNames {
            regexp:RegExp generatedNameRegex = re `${generatedName}`;
            content = generatedNameRegex.replaceAll(content, renames.get(generatedName));
        }
        check io:fileWriteString(path, content);
    }
}

function capitalize(string name) returns string =>
    name.substring(0, 1).toUpperAscii() + name.substring(1);
