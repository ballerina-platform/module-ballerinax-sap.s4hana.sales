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

import niveathika/pluralize;

type Method record {
    string operationId?;
    string summary?;
    string description?;
    string[] tags?;
    json[] parameters?;
    json requestBody?;
    json responses?;
};

type Path record {|
    json[] parameters?;
    Method get?;
    Method post?;
    Method put?;
    Method patch?;
    Method delete?;
|};

type Components record {
    map<json> schemas;
    json parameters;
    json responses;
    json securitySchemes;
};

type Specification record {
    string openapi;
    json info;
    json externalDocs;
    string x\-sap\-api\-type;
    string x\-sap\-shortText;
    string x\-sap\-software\-min\-version;
    json[] x\-sap\-ext\-overview;
    json[] servers;
    json x\-sap\-extensible;
    json[] tags;
    map<Path> paths;
    Components components;
    json[] security;
};

enum HttpMethod {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH
}

public function main(string apiName) returns error? {
    string specPath = string `spec/${apiName}.json`;
    json openAPISpec = check io:fileReadJson(specPath);

    Specification spec = check openAPISpec.cloneWithType(Specification);

    map<Path> paths = spec.paths;
    foreach var [key, value] in paths.entries() {
        if (value.get is Method) {
            value.get.operationId = check getSanitisedPathName(key, GET, value.get?.responses);
        }
        if (value.post is Method) {
            value.post.operationId = check getSanitisedPathName(key, POST);
        }
        if (value.put is Method) {
            value.put.operationId = check getSanitisedPathName(key, PUT);
        }
        if (value.delete is Method) {
            value.delete.operationId = check getSanitisedPathName(key, DELETE);
        }
        if (value.patch is Method) {
            value.patch.operationId = check getSanitisedPathName(key, PATCH);
        }
    }
    check io:fileWriteJson(specPath, spec.toJson());
}

function getSanitisedPathName(string key, HttpMethod method, json? response = ()) returns string|error {

    match key {
        "/rejectApprovalRequest" => {
            return "rejectApprovalRequest";
        }
        "/releaseApprovalRequest" => {
            return "releaseApprovalRequest";
        }
        "/$batch" => {
            return "performBatchOperation";
        }
    }

    string parameterName = "";

    regexp:RegExp pathRegex = re `/([^(]*)(\(.*\))?(/.*)?`;
    regexp:Groups? groups = pathRegex.findGroups(key);
    if groups is () {
        // Can be requestApproval/ batch query path
        return "";
    }

    boolean isCollectionReturnedResult = isCollectionReturned(method, response);

    match (groups.length()) {
        0|1 => {
            io:println("Error: Invalid path" + key);
            parameterName += key;
        }
        2 => {
            regexp:Span? basePath = groups[1];
            if basePath !is () {
                parameterName += check getSanitizedName(basePath.substring(), isCollectionReturnedResult);
            }
        }
        3 => {
            regexp:Span? basePath = groups[1];
            if basePath !is () {
                parameterName += basePath.substring();
            }
        }
        4 => {
            regexp:Span? resourcePath = groups[3];
            if resourcePath !is () {
                string resourcePathString = resourcePath.substring();
                if resourcePathString.startsWith("/") {
                    resourcePathString = resourcePathString.substring(1);
                }
                if resourcePathString.startsWith("to_") {
                    resourcePathString = resourcePathString.substring(3);
                }
                resourcePathString = resourcePathString.substring(0, 1).toUpperAscii() + resourcePathString.substring(1);

                resourcePathString = check getSanitizedName(resourcePathString, isCollectionReturnedResult);

                regexp:Span? basePath = groups[1];
                if basePath is () {
                    return "";
                }
                parameterName += resourcePathString.concat("Of", basePath.substring());
            }
        }
    }

    match method {
        GET => {
            if isCollectionReturnedResult {
                parameterName = "list" + parameterName;
            } else {
                parameterName = "get" + parameterName;
            }
        }
        POST => {
            parameterName = "create" + parameterName;
        }
        PUT => {
            parameterName = "update" + parameterName;
        }
        DELETE => {
            parameterName = "delete" + parameterName;
        }
        PATCH => {
            parameterName = "patch" + parameterName;
        }
    }

    return parameterName;
}

function getSanitizedName(string word, boolean isCollectionReturnedResult) returns string|error {
    if (isCollectionReturnedResult && !word.endsWith("Details")) {
        string pluralizeBasePath = check pluralize:pluralize(word);
        io:println(string `Plural of ${word} is ${pluralizeBasePath}`);
        return pluralizeBasePath;
    } else {
        return word;
    }
}

function isCollectionReturned(HttpMethod method, json? response) returns boolean {
    if (method == GET) {
        if response is () {
            return false;
        }
        json|error description = response.'200.description;
        if description is json {
            return description.toBalString().includes("Retrieved entities");
        }
    }
    return false;
}
