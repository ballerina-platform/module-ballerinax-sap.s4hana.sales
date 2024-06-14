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
import ballerina/os;

public function main(string moduleName, string apiPostfix) returns error? {
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

    _ = check os:exec(command = {
                value: "bal",
                arguments: ["format", "../ballerina/" + moduleName]
            });

    _ = check os:exec(command = {
                value: "bal",
                arguments: ["build", "../ballerina/" + moduleName]
            });
}
