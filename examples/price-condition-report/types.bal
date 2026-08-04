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

type S4HanaClientConfig record {|
    string hostname;
    string username;
    string password;
    // Only needs to be set when the service is not on the default HTTPS port, for example when
    // running against the mock server of this connector.
    int port = 443;
    // Trusted certificate of the target server. Only needed when the server presents a certificate
    // that the JVM does not already trust, for example the self signed certificate of the mock server.
    string certPath?;
|};

// A single row of the report.
type ConditionSummary record {|
    string conditionRecord;
    string conditionType;
    string rate;
    string rateUnit;
    string validFrom;
    string validTo;
|};
