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

import ballerina/http;
import ballerina/log;
import ballerina/random;
import ballerinax/sap.s4hana.api_sales_order_srv as salesorder;

configurable S4HanaClientConfig s4hanaClientConfig = ?;

final salesorder:Client salesOrderClient = check new ({
        auth: {
            username: s4hanaClientConfig.username,
            password: s4hanaClientConfig.password
        }
    },
    s4hanaClientConfig.hostname
);

service /sap\-bridge on new http:Listener(9090) {

    isolated resource function post 'order(ShopifyOrder shopifyOrder) returns http:Created|http:InternalServerError {
        log:printInfo(string `Received order with confirmation number: ${shopifyOrder.confirmation_number}`);

        salesorder:CreateA_SalesOrder|error salesOrder = transformShopifyOrder(shopifyOrder);
        if salesOrder is error {
            log:printError(string `Error while transforming order: ${salesOrder.message()}`, salesOrder);
            return http:INTERNAL_SERVER_ERROR;
        }

        salesorder:A_SalesOrderWrapper|error createdSO = salesOrderClient->createA_SalesOrder(salesOrder);
        if createdSO is error {
            log:printError("Error: " + createdSO.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        log:printInfo(string `Successfully created an SAP sales order with id: ${createdSO.d?.SalesOrder ?: ""}`);
        return http:CREATED;
    }
}

isolated function transformShopifyOrder(ShopifyOrder shopifyOrder) returns salesorder:CreateA_SalesOrder|error {
    int salesOrderId = check random:createIntInRange(5000000, 5999999);
    salesorder:CreateA_SalesOrder salesOrder = {
        SalesOrder: salesOrderId.toString(),
        SalesOrderType: SALES_ORDER_TYPE,
        SalesOrganization: SALES_ORGANIZATION,
        DistributionChannel: DISTRIBUTION_CHANNEL,
        OrganizationDivision: ORG_DIVISION,
        SoldToParty: SOLD_TO_PARTY
    };
    if shopifyOrder.line_items.length() == 0 {
        log:printInfo("No items found in the opportunity. Skipping item creation in order creation.");
        return salesOrder;
    }

    salesorder:CreateA_SalesOrderItem[] orderItems = [];
    foreach int i in 0 ... shopifyOrder.line_items.length() - 1 {
        string productId = shopifyOrder.line_items[i].product_id.toString();
        S4HanaMaterial? material = CODE_TO_MATERIAL[productId];
        if material is () {
            log:printError(string `Material mapping to Product Id is not found for ${productId}`);
            continue;
        }
        orderItems.push({
            SalesOrderItem: (i + 1).toString(),
            Material: material.Material,
            SalesOrderItemText: material.Name,
            SalesOrderItemCategory: material.SalesOrderItemCategory,
            RequestedQuantity: shopifyOrder.line_items[i].quantity.toString(),
            RequestedQuantityUnit: material.RequestedQuantityUnit
        });
    }
    salesOrder.to_Item = {
        results: orderItems
    };
    return salesOrder;
}
