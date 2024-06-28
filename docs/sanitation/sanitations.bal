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

type Items record {
    string 'type?;
    string[] 'enum?;
    string \$ref?;
};

type Schema record {
    string 'type?;
    boolean uniqueItems?;
    Items items?;
    string title?;
    json properties?;
};

type ParametersItem record {
    string name?;
    string 'in?;
    boolean required?;
    string description?;
    boolean explode?;
    Schema schema?;
    string \$ref?;
};

type EnumItems record {
    string 'type;
    string[] 'enum;
};

type EnumSchema record {
    string 'type;
    boolean uniqueItems;
    EnumItems items;
};

type EnumParametersItem record {
    string name;
    string 'in;
    boolean required?;
    string description;
    Schema schema;
    boolean explode;
};

type Get record {
    string summary?;
    string description?;
    string[] tags?;
    ParametersItem[] parameters;
    map<ResponseCode> responses?;
};

type Post record {
    string summary?;
    string description?;
    string[] tags?;
    json requestBody?;
    ParametersItem[] parameters?;
    map<ResponseCode> responses?;
};

type Path record {
    json[] parameters?;
    Get get?;
    Post post?;
};

type Components record {
    map<json> schemas;
    map<ParametersItem> parameters;
    json responses;
    json securitySchemes;
};

type ResponseCode record {
    string description?;
    map<ResponseHeader> content?;
};

type ResponseHeader record {
    ResponseSchema schema?;
};

type ResponseSchema record {
    string title?;
    string 'type?;
    string schemaType?;
    map<ResponseProperties> properties?;
};

type ResponseProperties record {
    string title?;
    string 'type?;
    string objectType?;
    json properties?;
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

public function main(string apiName) returns error? {
    string specPath = string `spec/${apiName}.json`;
    check sanitizeSchemaNames(apiName, specPath);
    check sanitizeEnumParamters(specPath);
    check sanitizeResponseSchemaNames(specPath);
}

function sanitizeEnumParamters(string specPath) returns error? {
    json openAPISpec = check io:fileReadJson(specPath);

    Specification spec = check openAPISpec.cloneWithType(Specification);

    boolean isODATA4 = false;
    if spec.x\-sap\-api\-type == "ODATAV4" {
        isODATA4 = true;
    }

    map<ParametersItem> selectedParameters = {};
    map<EnumSchema> schemasLookup = {};
    [string, EnumSchema][] selectedSchemas = [];
    int selectedSchemaIndex = 0;
    record {|
        int index;
        string possibleDuplicateKey1;
        string possibleDuplicateKey2;
    |}[] possibleDuplicateSchemaIndex = [];

    map<Path> paths = spec.paths;
    foreach var [key, value] in paths.entries() {
        Get? getPath = value.get;
        if getPath is () {
            continue;
        }
        ParametersItem[] parameters = getPath.parameters;
        foreach int i in 0 ... parameters.length() - 1 {
            ParametersItem param = parameters[i];
            Schema? paramSchema = param.schema;
            if paramSchema is () {
                continue;
            }
            if paramSchema.'type != "array" {
                continue;
            }
            Items? items = paramSchema.items;
            if items is () {
                continue;
            }
            if items.'enum is () {
                continue;
            }
            [string, string, string] sanitizedParamName = getSanitizedParameterName(key, param.name ?: "", isODATA4);
            schemasLookup[sanitizedParamName[0]] = check param.schema.cloneWithType(EnumSchema);
            selectedSchemas.push([sanitizedParamName[0], <EnumSchema>schemasLookup[sanitizedParamName[0]]]);
            selectedParameters[sanitizedParamName[0]] = {
                name: param.name,
                'in: param.'in,
                description: param.description,
                explode: param.explode,
                schema: {
                    "$ref": "#/components/schemas/" + sanitizedParamName[0]
                }
            };
            parameters[i] = {
                \$ref: "#/components/parameters/" + sanitizedParamName[0]
            };
            if sanitizedParamName[1] != "" {
                possibleDuplicateSchemaIndex.push({
                    index: selectedSchemaIndex,
                    possibleDuplicateKey1: sanitizedParamName[1],
                    possibleDuplicateKey2: sanitizedParamName[2]
                });
            }
            selectedSchemaIndex += 1;
        }
    }

    map<EnumSchema> uniqueSchemas = {};
    int j = 0;
    foreach int i in 0 ... selectedSchemas.length() - 1 {
        if i == possibleDuplicateSchemaIndex[j].index {
            string duplicateKey = possibleDuplicateSchemaIndex[j].possibleDuplicateKey1;
            EnumSchema? possibleDuplicateSchema = schemasLookup[duplicateKey];
            if possibleDuplicateSchema is () {
                duplicateKey = possibleDuplicateSchemaIndex[j].possibleDuplicateKey2;
                possibleDuplicateSchema = schemasLookup[duplicateKey];
            }
            if possibleDuplicateSchema !is () {
                if selectedSchemas[i][1].items.'enum.length() == possibleDuplicateSchema.items.'enum.length() {
                    boolean isEqual = possibleDuplicateSchema.items.'enum.every(val => selectedSchemas[i][1].items.'enum.indexOf(val) != ());
                    if isEqual {
                        selectedParameters[selectedSchemas[i][0]].schema = {
                            "$ref": "#/components/schemas/" + duplicateKey
                        };
                        j += 1;
                        continue;
                    }
                }
            }
            uniqueSchemas[selectedSchemas[i][0]] = selectedSchemas[i][1];
            j += 1;
        } else {
            uniqueSchemas[selectedSchemas[i][0]] = selectedSchemas[i][1];
        }
    }

    foreach var [schemaName, value] in uniqueSchemas.entries() {
        spec.components.schemas[schemaName] = value.toJson();
    }

    foreach var [paramName, value] in selectedParameters.entries() {
        spec.components.parameters[paramName] = value;
    }

    check io:fileWriteJson(specPath, spec.toJson());

}

function getSanitizedParameterName(string key, string paramName, boolean isODATA4) returns [string, string, string] {

    string parameterName = "";
    string possibleDuplicateKey1 = "";
    string possibleDuplicateKey2 = "";

    regexp:RegExp pathRegex;
    if isODATA4 {
        pathRegex = re `^/([^/]+)?(/[^{]+)?(/[^/{]+)?(/.*)?$`;
    } else {
        pathRegex = re `/([^(]*)(\(.*\))?(/.*)?`;
    }

    regexp:Groups? groups = pathRegex.findGroups(key);
    if groups is () {
        // Can be requestApproval/ batch query path
        return ["", "", ""];
    }

    match (groups.length()) {
        0|1 => {
            io:println("Error: Invalid path" + key);
            parameterName += key;
        }
        2 => {
            regexp:Span? basePath = groups[1];
            if basePath !is () {
                parameterName += basePath.substring();
            }
        }
        3 => {
            regexp:Span? basePath = groups[1];
            if basePath !is () {
                parameterName += basePath.substring().concat("ByKey");
                possibleDuplicateKey1 = basePath.substring();
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
                possibleDuplicateKey1 = resourcePathString;

                regexp:Span? basePath = groups[1];
                if basePath is () {
                    return ["", "", ""];
                }
                parameterName += resourcePathString.concat("Of", basePath.substring());
                possibleDuplicateKey2 = basePath.substring() + resourcePathString;
            }
        }
    }

    string postfix = "";
    match (paramName) {
        "$filter" => {
            postfix = "FilterOptions";
        }
        "$select" => {
            postfix = "SelectOptions";
        }
        "$expand" => {
            postfix = "ExpandOptions";
        }
        "$search" => {
            postfix = "SearchOptions";
        }
        "$orderby" => {
            postfix = "OrderByOptions";
        }
        _ => {
            io:println("Error: Invalid parameter name: " + parameterName);
        }
    }

    parameterName += postfix;
    possibleDuplicateKey1 = possibleDuplicateKey1 == "" ? "" : possibleDuplicateKey1 + postfix;
    possibleDuplicateKey2 = possibleDuplicateKey2 == "" ? "" : possibleDuplicateKey2 + postfix;
    return [parameterName, possibleDuplicateKey1, possibleDuplicateKey2];
}

function sanitizeSchemaNames(string apiName, string specPath) returns error? {
    // Directory name = api name
    // File name = api_name.json
    json openAPISpec = check io:fileReadJson(specPath);

    Specification spec = check openAPISpec.cloneWithType(Specification);

    map<json> updatedSchemas = {};
    map<string> updatedNames = {};

    foreach [string, json] [schemaName, schema] in spec.components.schemas.entries() {
        boolean schemaNameCheck = schemaName.includes(".");
        if schemaNameCheck {
            string updatedKey = getSanitizedSchemaName(schemaName);
            updatedSchemas[updatedKey] = schema;
            updatedNames[schemaName] = updatedKey;
        } else {
            updatedSchemas[schemaName] = schema;
        }
    }
    spec.components.schemas = updatedSchemas;

    string updatedSpec = spec.toJsonString();
    foreach [string, string] [oldName, newName] in updatedNames.entries() {
        string sanitizedOldNameRegex = re `\.`.replace(oldName, "\\.");
        regexp:RegExp regexp = re `${sanitizedOldNameRegex}"`;
        updatedSpec = regexp.replaceAll(updatedSpec, newName + "\"");
    }

    check io:fileWriteString(specPath, updatedSpec);
}

function getSanitizedSchemaName(string schemaName) returns string {
    int? indexOfPeriod = schemaName.lastIndexOf(".");
    int substringStartIndex = indexOfPeriod == () ? 0 : indexOfPeriod + 1;
    string updatedKey = schemaName.substring(substringStartIndex);

    if updatedKey.endsWith("_Type") {
        updatedKey = updatedKey.substring(0, updatedKey.length() - 5);
    }

    if updatedKey.endsWith("_Type-create") {
        updatedKey = "Create" + updatedKey.substring(0, updatedKey.length() - 12);
    }

    if updatedKey.endsWith("_Type-update") {
        updatedKey = "Update" + updatedKey.substring(0, updatedKey.length() - 12);
    }

    if updatedKey.endsWith("Type") {
        updatedKey = updatedKey.substring(0, updatedKey.length() - 4);
    }

    if updatedKey.endsWith("Type-create") {
        updatedKey = "Create" + updatedKey.substring(0, updatedKey.length() - 11);
    }

    if updatedKey.endsWith("Type-update") {
        updatedKey = "Update" + updatedKey.substring(0, updatedKey.length() - 11);
    }

    if updatedKey.endsWith("-create") {
        updatedKey = "Create" + updatedKey.substring(0, updatedKey.length() - 7);
    }

    if updatedKey.endsWith("-update") {
        updatedKey = "Update" + updatedKey.substring(0, updatedKey.length() - 7);
    }
    return updatedKey;
}

function sanitizeResponseSchemaNames(string specPath) returns error? {
    json openAPISpec = check io:fileReadJson(specPath);
    Specification spec = check openAPISpec.cloneWithType(Specification);
    boolean isODATA4 = false;
    if spec.x\-sap\-api\-type == "ODATAV4" {
        isODATA4 = true;
    }
    map<Path> paths = spec.paths;
    foreach var [key, value] in paths.entries() {
        if value.get != () {
            Get getPath = value.get ?: {parameters: []};
            map<ResponseCode> responses = getPath.responses ?: {};
            foreach [string, ResponseCode] [_, item] in responses.entries() {
                if item.description == "Retrieved entities" {
                    map<ResponseHeader> content = item.content ?: {};
                    ResponseHeader app = content["application/json"] ?: {};
                    ResponseSchema schema = app.schema ?: {};
                    if !isODATA4 {
                        ResponseProperties properties = schema.properties["d"] ?: {properties: ()};
                        string sanitizedTitle = properties.title ?: "";
                        sanitizedTitle = sanitizedTitle.trim();
                        if sanitizedTitle.startsWith("Collection of") {
                            sanitizedTitle = "CollectionOf" + sanitizedTitle.substring(14, sanitizedTitle.length());
                        }
                        if sanitizedTitle.endsWith("Type") {
                            sanitizedTitle = sanitizedTitle.substring(0, sanitizedTitle.length() - 4);
                        }
                        schema.title = sanitizedTitle + "Wrapper";
                        properties.title = sanitizedTitle;
                    } else {
                        string sanitizedTitle = schema.title ?: "";
                        if sanitizedTitle.startsWith("Collection of") {
                            schema.title = "CollectionOf" + sanitizedTitle.substring(14, sanitizedTitle.length() - 5);
                        }
                    }
                } else if item.description == "Retrieved entity" {
                    map<ResponseHeader> content = item.content ?: {};
                    ResponseHeader app = content["application/json"] ?: {};
                    ResponseSchema schema = app.schema ?: {};
                    string sanitizedTitle = schema.title ?: "";
                    if sanitizedTitle.endsWith("Type") {
                        sanitizedTitle = sanitizedTitle.substring(0, sanitizedTitle.length() - 4);
                    }
                    if !isODATA4 {
                        schema.title = sanitizedTitle + "Wrapper";
                    }
                }
            }
        }
        if value.post != () {
            Post postPath = value.post ?: {parameters: []};
            map<ResponseCode> responses = postPath.responses ?: {};
            foreach [string, ResponseCode] [_, item] in responses.entries() {
                map<ResponseHeader> content = item.content ?: {};
                ResponseHeader app = content["application/json"] ?: {};
                ResponseSchema schema = app.schema ?: {};
                string schemaTitle = schema.title ?: "";
                if schemaTitle == "Wrapper" {
                    schema.title = key.substring(1, key.length()) + "Wrapper";
                    schema.title = schemaTitle;
                } else if schemaTitle.endsWith("Type") {
                    schemaTitle = schemaTitle.substring(0, schemaTitle.length() - 4);
                    if !isODATA4 {
                        schema.title = schemaTitle + "Wrapper";
                    } else {
                        schema.title = schemaTitle;
                    }
                }
            }
        }
    }
    check io:fileWriteJson(specPath, spec.toJson());
};
