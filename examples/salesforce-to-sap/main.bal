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

service sftrigger:RecordService on sfdcEventListener {
    isolated remote function onCreate(sftrigger:EventData payload) {
        log:printInfo(string `New opportunity created: ${payload.metadata?.recordId ?: ""}`);
    }

    isolated remote function onUpdate(sftrigger:EventData payload) returns error? {
        string? opportunityId = payload.metadata?.recordId;
        if opportunityId == null {
            log:printError("Error while creating SAP order: invalid opportunityId from event");
            return;
        }
        log:printInfo(string `Recieved an opportunity update event for id: ${opportunityId}`);

        boolean isClosed = check boolean:fromString(<string>(payload.changedData["IsClosed"] ?: "false"));
        if !isClosed {
            log:printInfo("Opportunity is not closed. Skipping order creation.");
            return;
        }

        boolean isWon = check boolean:fromString(<string>(payload.changedData["IsWon"] ?: "false"));
        if !isWon {
            log:printInfo("Opportunity is not won. Skipping order creation.");
            return;
        }

        SalesforceOpportunityItem[]|error retrievedItems = retrieveOpportunityItems(opportunityId);
        if retrievedItems is error {
            log:printError("Error while retrieving opportunity items: " + retrievedItems.message());
            return;
        }

        salesorder:CreateA_SalesOrder|error salesOrder = trap transformOrderData(retrievedItems);
        if salesOrder is error {
            log:printError("Error while transforming order: " + salesOrder.message());
            return;
        }

        salesorder:A_SalesOrderWrapper|error aSalesOrder = salesOrderClient->createA_SalesOrder(salesOrder);
        if aSalesOrder is error {
            log:printError("Error while creating SAP order: " + aSalesOrder.message(), aSalesOrder);
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

isolated function retrieveOpportunityItems(string opportunityId) returns SalesforceOpportunityItem[]|error {
    stream<record {}, error?> sfOpportunityItems = check sfClient->query(
        string `SELECT ProductCode, Name, Quantity FROM OpportunityLineItem 
        WHERE OpportunityId='${opportunityId}'`);
    return check from record {} sfOpportunityItem in sfOpportunityItems
        select {
            ProductCode: <string>sfOpportunityItem["ProductCode"],
            Quantity: <float>sfOpportunityItem["Quantity"],
            Name: <string>sfOpportunityItem["Name"]
        };
}

isolated function transformOrderData(SalesforceOpportunityItem[] salesforceItems) returns salesorder:CreateA_SalesOrder|error {

    int salesOrderId = check random:createIntInRange(5000000, 5999999);
    salesorder:CreateA_SalesOrder salesOrder = {
        SalesOrder: salesOrderId.toString(),
        SalesOrderType: SALES_ORDER_TYPE,
        SalesOrganization: SALES_ORGANIZATION,
        DistributionChannel: DISTRIBUTION_CHANNEL,
        OrganizationDivision: ORG_DIVISION,
        SoldToParty: SOLD_TO_PARTY
    };
    if salesforceItems.length() == 0 {
        log:printInfo("No items found in the opportunity. Skipping item creation in order creation.");
        return salesOrder;
    }

    salesorder:CreateA_SalesOrderItem[] orderItems = [];
    foreach int i in 0 ... salesforceItems.length() - 1 {
        string productCode = salesforceItems[i].ProductCode;
        S4HanaMaterial? material = CODE_TO_MATERIAL[productCode];
        if material is () {
            log:printError(string `Material mapping to Product Code is not found for ${productCode}`);
            continue;
        }
        orderItems.push({
            SalesOrderItem: (i + 1).toString(),
            Material: material.Material,
            SalesOrderItemText: salesforceItems[i].Name,
            SalesOrderItemCategory: material.SalesOrderItemCategory,
            RequestedQuantity: salesforceItems[i].Quantity.toString(),
            RequestedQuantityUnit: material.RequestedQuantityUnit
        });
    }
    salesOrder.to_Item = {
        results: orderItems
    };
    return salesOrder;
}
