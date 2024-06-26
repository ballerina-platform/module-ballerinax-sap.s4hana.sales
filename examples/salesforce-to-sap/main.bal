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
import ballerinax/salesforce;
import ballerinax/sap.s4hana.api_sales_order_srv as salesorder;
import ballerinax/trigger.salesforce as sftrigger;

configurable SalesforceListenerConfig salesforceListenerConfig = ?;
configurable SalesforceClientConfig salesforceClientConfig = ?;
configurable S4HANAClientConfig s4hanaClientConfig = ?;

listener sftrigger:Listener sfdcEventListener = new ({
    username: salesforceListenerConfig.username,
    password: salesforceListenerConfig.password,
    channelName: "/data/OpportunityChangeEvent",
    environment: salesforceListenerConfig.environment
});

final salesforce:Client sfClient = check new ({
    baseUrl: salesforceClientConfig.baseUrl,
    auth: {
        clientId: salesforceClientConfig.clientId,
        clientSecret: salesforceClientConfig.clientSecret,
        refreshToken: salesforceClientConfig.refreshToken,
        refreshUrl: salesforceClientConfig.refreshUrl
    }
});

final salesorder:Client salesOrderClient = check new (
    config = {
        auth: {
            username: s4hanaClientConfig.username,
            password: s4hanaClientConfig.password
        }
    },
    hostname = s4hanaClientConfig.hostname
);

final map<string> & readonly productMap = {"01t5g000001Ak0xAAC": "001"};

service sftrigger:RecordService on sfdcEventListener {
    isolated remote function onCreate(sftrigger:EventData payload) {
        log:printInfo(string `New opportunity created: ${payload.metadata?.recordId ?: ""}`);
    }

    isolated remote function onUpdate(sftrigger:EventData payload) {
        string? opportunityId = payload.metadata?.recordId;
        if opportunityId == null {
            log:printError("Error while creating SAP order: invalid opportunityId from event");
            return;
        }
        log:printInfo(string `Recieved an opportunity update event for id: ${opportunityId}`);

        json isClosed = payload.changedData["IsClosed"] ?: false;
        if isClosed == "false" {
            log:printInfo("Opportunity is not closed. Skipping order creation.");
            return;
        }

        json isWon = payload.changedData["IsWon"] ?: false;
        if isWon == "false" {
            log:printInfo("Opportunity is not won. Skipping order creation.");
            return;
        }

        stream<SalesforceOpportunityItem, error?>|error retrievedStream = retrieveOpportunityItems(opportunityId);
        if retrievedStream is error {
            log:printError("Error while retrieving opportunity items: " + retrievedStream.message());
            return;
        }

        salesorder:CreateA_SalesOrder|error salesOrder = transformOrderData(retrievedStream);
        if salesOrder is error {
            log:printError("Error while transforming order: " + salesOrder.message());
            return;
        }

        salesorder:A_SalesOrderType|error aSalesOrder = salesOrderClient->createA_SalesOrder(salesOrder);
        if aSalesOrder is error {
            log:printError("Error while creating SAP order: " + aSalesOrder.message());
        } else {
            log:printInfo(string `Successfully created an SAP sales order with id: ${aSalesOrder.d?.SalesOrder ?: ""}`);
        }
    }

    isolated remote function onDelete(sftrigger:EventData payload) {
        log:printInfo(string `Opportunity deleted: ${payload.metadata?.recordId ?: ""}`);
    }

    isolated remote function onRestore(sftrigger:EventData payload) returns error? {
        log:printInfo(string `Opportunity restored: ${payload.metadata?.recordId ?: ""}`);
    }
}

isolated function retrieveOpportunityItems(string opportunityId) returns stream<SalesforceOpportunityItem, error?>|error {
    return check sfClient->query(
            string `SELECT Product2Id, Name, Quantity, TotalPrice FROM OpportunityLineItem 
            WHERE OpportunityId='${opportunityId}'`);
}

isolated function transformOrderData(stream<SalesforceOpportunityItem, error?> salesforceItems) returns salesorder:CreateA_SalesOrder|error {
    string salesOrderType = "OR";
    string purchaser = "17300096";
    string salesOrganization = "1710";
    string group = "001";

    salesorder:CreateA_SalesOrderItem[] orderItems = check from SalesforceOpportunityItem item in salesforceItems
        select
        {
            SalesOrderItem: productMap[item.Product2Id] ?: "001",
            Material: item.Product2Id
        };

    return {
        SalesOrder: "123456",
        SalesOrderType: salesOrderType,
        SalesOrganization: salesOrganization,
        SalesGroup: group,
        SoldToParty: purchaser,
        to_Item: {
            results: orderItems
        }
    };
}
