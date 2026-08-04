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

// Support for the `$batch` operation.
//
// The OpenAPI tool cannot generate this: a batch body is a `multipart/mixed` envelope whose parts are
// complete HTTP requests, and for writes a nested `multipart/mixed` change set. That is a transport
// encoding rather than a data shape, so it has no representation in the OpenAPI contract, which is why
// the generated operation would otherwise hand back a raw `http:Request`.

import ballerina/http;
import ballerina/lang.regexp;
import ballerina/mime;
import ballerina/uuid;

import ballerinax/sap.s4hana.api_slspricingconditionrecord_srv.oas;

// OData requires CRLF line endings inside the envelope. LF alone is rejected.
const string BATCH_CRLF = "\r\n";

# An entity that may be sent inside a batch request: any create payload, any update payload, or an update
# payload already wrapped for a modify request.
#
# A bare array of entities is created in the given entity set, so updates only make sense through
# `BatchRequest`, which lets each request carry its own key in the URI and its own `If-Match` header.
#
# A modify request accepts either a bare `Update...` payload or the same payload wrapped as
# `{"d": { ... }}`, which is what the `oas:Modified\ ...Type` records are. Both answer `204`.
#
# A modify always needs the entity's current ETag in an `If-Match` header: without one the service
# answers `428 The Data Service Request is required to be conditional`, and `If-Match: *` is rejected
# with `State of the resource (entity) was already changed`.
public type BatchEntity oas:CreateA_SlsPrcgConditionRecord|oas:CreateA_SlsPrcgCndnRecdValidity|
    oas:CreateA_SlsPrcgCndnRecordScale|oas:CreateA_SlsPrcgCndnRecdSuplmnt|oas:CreateA_SlsPrcgConditionRecordText|
    oas:CreateA_SlsPrcgCndnSupplementText|oas:UpdateA_SlsPrcgConditionRecord|oas:UpdateA_SlsPrcgCndnRecdValidity|
    oas:UpdateA_SlsPrcgCndnRecordScale|oas:UpdateA_SlsPrcgCndnRecdSuplmnt|oas:UpdateA_SlsPrcgConditionRecordText|
    oas:UpdateA_SlsPrcgCndnSupplementText|oas:Modified\ A_SlsPrcgConditionRecordType|
    oas:Modified\ A_SlsPrcgCndnRecdValidityType|oas:Modified\ A_SlsPrcgCndnRecordScaleType|
    oas:Modified\ A_SlsPrcgCndnRecdSuplmntType|oas:Modified\ A_SlsPrcgConditionRecordTextType|
    oas:Modified\ A_SlsPrcgCndnSupplementTextType;

# A single request inside a batch.
#
# + method - HTTP method of the request
# + uri - Resource path relative to the service root, such as `oas:A_SlsPrcgConditionRecord`. Query options
#         must be percent encoded, since this goes into an HTTP request line
# + payload - Entity to send, omitted for methods that do not carry one
# + headers - Additional headers for this request, such as `If-Match` for an update
public type BatchRequest record {|
    "GET"|"POST"|"PATCH"|"PUT"|"DELETE" method = "POST";
    string uri;
    BatchEntity payload?;
    map<string> headers?;
|};

# The outcome of one request inside a batch.
#
# + statusCode - HTTP status of this individual request
# + location - Value of the `location` header, which carries the key assigned by a successful create
# + body - Raw response body of this individual request
public type BatchResult record {|
    int statusCode;
    string? location;
    string body;
|};

# Turns a plain array of entities into create requests against one entity set.
#
# `performBatchOperation` applies this on its own when it is given entities rather than requests, so it is
# only needed when the requests are assembled up front.
#
# + entitySet - Name of the target entity set, such as `oas:A_SlsPrcgConditionRecord`
# + entities - Entities to create
# + return - One create request per entity, in the given order
public isolated function batchCreate(string entitySet, BatchEntity[] entities) returns BatchRequest[] =>
    from BatchEntity entity in entities
    select {method: "POST", uri: entitySet, payload: entity};

# Builds the `http:Request` that the generated `$batch` operation expects.
#
# The boundary is a fresh UUID on every call, so that no payload or header text can collide with the
# delimiters that frame the envelope.
#
# + requests - Requests to send, in order
# + atomic - Whether every write belongs to one transaction
# + return - A request carrying the `multipart/mixed` envelope, or an error if a request cannot be
# rendered safely
isolated function buildBatchRequest(BatchRequest[] requests, boolean atomic) returns http:Request|error {
    string token = uuid:createType4AsString();
    http:Request request = new;
    request.setPayload(check buildBatchBody(requests, atomic, token),
            string `multipart/mixed; boundary=b_${token}`);
    return request;
}

# Renders batch requests into an OData V2 `$batch` body.
#
# Read requests are sent as standalone parts, because OData does not allow them inside a change set.
# Writes get one change set each, so that a rejected request does not roll back the others, and the
# batch keeps the order it was given in.
#
# When `atomic` is set every write moves into a single change set, which is the only way to have them
# commit or roll back together. That also means the writes become contiguous, so a read that was sent
# between two writes comes back before both of them, and `Content-ID` references such as `$1` resolve
# only in this mode, since the request they point at has to be in the same change set.
#
# + requests - Requests to render, in order
# + atomic - Whether every write belongs to one transaction
# + token - Unique token the batch and change set boundaries are derived from
# + return - The `multipart/mixed` body, or an error if a request cannot be rendered safely
isolated function buildBatchBody(BatchRequest[] requests, boolean atomic, string token)
        returns string|error {
    string boundary = string `b_${token}`;
    string body = "";

    if !atomic {
        // Requests keep their original order, so the results line up with what was sent.
        int changeSet = 0;
        foreach BatchRequest request in requests {
            body += string `--${boundary}${BATCH_CRLF}`;
            if request.method == "GET" {
                body += check renderBatchRequest(request, token);
            } else {
                changeSet += 1;
                body += check renderChangeSet([request], string `cs${changeSet}_${token}`, token);
            }
        }
        return body + string `--${boundary}--${BATCH_CRLF}`;
    }

    // Every write has to sit in the same change set to be one transaction, so the writes move
    // together to the position of the first of them and the reads keep their own order.
    BatchRequest[] writes = [];
    boolean changeSetWritten = false;
    foreach BatchRequest request in requests {
        if request.method == "GET" {
            body += string `--${boundary}${BATCH_CRLF}`;
            body += check renderBatchRequest(request, token);
            continue;
        }
        writes.push(request);
        if !changeSetWritten {
            changeSetWritten = true;
            body += "@writes@";
        }
    }
    string changeSetBody = writes.length() == 0 ? ""
        : string `--${boundary}${BATCH_CRLF}` + check renderChangeSet(writes, string `cs1_${token}`, token);
    body = re `@writes@`.replaceAll(body, changeSetBody);
    return body + string `--${boundary}--${BATCH_CRLF}`;
}

// Wraps requests in a nested multipart change set, which S/4HANA applies as one transaction.
isolated function renderChangeSet(BatchRequest[] requests, string boundary, string token)
        returns string|error {
    string changeSet = string `Content-Type: multipart/mixed; boundary=${boundary}${BATCH_CRLF}${BATCH_CRLF}`;
    foreach BatchRequest request in requests {
        changeSet += string `--${boundary}${BATCH_CRLF}`;
        changeSet += check renderBatchRequest(request, token);
    }
    return changeSet + string `--${boundary}--${BATCH_CRLF}`;
}

// Renders one request as an `application/http` part, whose content is a complete HTTP request.
//
// Each part ends with two CRLF pairs rather than one: the first terminates the inner HTTP message, and the
// second is the CRLF that MIME counts as part of the following boundary delimiter. Omitting it is
// rejected by the gateway with "The Data Services Request could not be understood due to malformed
// syntax".
isolated function renderBatchRequest(BatchRequest request, string token) returns string|error {
    // A CR or LF in the request line or a header would inject structure into the inner HTTP message.
    if containsLineBreak(request.uri) {
        return error("The request URI must not contain a line break", uri = request.uri);
    }
    string rendered = string `Content-Type: application/http${BATCH_CRLF}`;
    rendered += string `Content-Transfer-Encoding: binary${BATCH_CRLF}${BATCH_CRLF}`;
    rendered += string `${request.method} ${request.uri} HTTP/1.1${BATCH_CRLF}`;
    rendered += string `Accept: application/json${BATCH_CRLF}`;
    foreach [string, string] [name, value] in (request?.headers ?: {}).entries() {
        if containsLineBreak(name) || containsLineBreak(value) {
            return error("A header must not contain a line break", header = name);
        }
        rendered += string `${name}: ${value}${BATCH_CRLF}`;
    }

    BatchEntity? payload = request?.payload;
    if payload is () {
        rendered += BATCH_CRLF + BATCH_CRLF;
    } else {
        rendered += string `Content-Type: application/json${BATCH_CRLF}${BATCH_CRLF}`;
        rendered += string `${payload.toJson().toJsonString()}${BATCH_CRLF}${BATCH_CRLF}`;
    }

    // The boundaries are derived from a UUID created for this batch, so a collision with the rendered
    // text cannot realistically happen; this guards the envelope even if it somehow does.
    if rendered.includes(token) {
        return error("The rendered request collides with the batch boundary");
    }
    return rendered;
}

isolated function containsLineBreak(string value) returns boolean =>
    value.includes("\r") || value.includes("\n");

# Reads a batch response into the outcome of each individual request.
#
# A batch answers `202 Accepted` even when every request inside it failed, so the per request status codes
# are the only reliable indication of success.
#
# + response - The raw batch response
# + return - One result per request, in the order they were sent, or an error if the batch itself failed
isolated function parseBatchResults(http:Response response) returns BatchResult[]|error {
    // A batch rejected by the gateway answers with a plain error document rather than a multipart body,
    // so the parts can only be read once that case is out of the way.
    if !response.getContentType().toLowerAscii().startsWith("multipart/") {
        string detail = check response.getTextPayload();
        return error("The batch request was rejected", statusCode = response.statusCode, body = detail);
    }
    // The MIME layer owns the envelope: `getTextPayload` rejects a multipart entity, `getBinaryPayload`
    // comes back empty and `getByteStream` errors, because the body has already been split into parts.
    return collectBatchResults(check response.getBodyParts());
}

// Walks the response parts, descending into change sets, and reads each `application/http` part.
isolated function collectBatchResults(mime:Entity[] parts) returns BatchResult[]|error {
    BatchResult[] results = [];
    foreach mime:Entity part in parts {
        if part.getContentType().toLowerAscii().startsWith("multipart/") {
            results.push(...check collectBatchResults(check part.getBodyParts()));
            continue;
        }
        string content = check string:fromBytes(check part.getByteArray());
        BatchResult? result = readBatchResult(content);
        if result is () {
            // Dropping the part silently would leave the caller pairing the remaining results with the
            // wrong requests.
            return error("A batch response part could not be parsed", part = content);
        }
        results.push(result);
    }
    return results;
}

// Reads the status code, the location header and the body out of one inner HTTP response.
isolated function readBatchResult(string part) returns BatchResult? {
    regexp:Groups? groups = re `HTTP/1\.1 (\d{3})`.findGroups(part);
    if groups is () || groups.length() < 2 {
        return ();
    }
    regexp:Span? status = groups[1];
    if status is () {
        return ();
    }
    int|error statusCode = int:fromString(status.substring());
    if statusCode is error {
        return ();
    }

    // The body of the inner response starts after its blank header separator line.
    int? headerEnd = part.indexOf(BATCH_CRLF + BATCH_CRLF, status.endIndex);
    string body = headerEnd is int ? part.substring(headerEnd + 4).trim() : "";
    string headers = headerEnd is int ? part.substring(status.endIndex, headerEnd) : "";
    return {statusCode, location: readHeader(headers, "location"), body};
}

// Reads a header value out of the header block of an inner HTTP response.
isolated function readHeader(string headers, string name) returns string? {
    foreach string line in re `\r?\n`.split(headers) {
        int? colon = line.indexOf(":");
        if colon is int && line.substring(0, colon).trim().toLowerAscii() == name {
            return line.substring(colon + 1).trim();
        }
    }
    return ();
}
