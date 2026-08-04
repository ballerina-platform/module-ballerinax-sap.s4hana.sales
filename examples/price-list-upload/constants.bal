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

// Pricing configuration. `PPR0` is the standard price condition type of S/4HANA Cloud, and `V` is
// the sales application. Note that on-premise systems use `PR00` instead. Condition table `304`
// keys a price by material, sales organization and distribution channel, which is why those three
// fields are set on the validity entity rather than on the condition record header.
const CONDITION_TYPE = "PPR0";
const CONDITION_APPLICATION = "V";
const CONDITION_TABLE = "304";
const CONDITION_SEQUENTIAL_NUMBER = "1";

// Organizational constants
const SALES_ORGANIZATION = "1710";
const DISTRIBUTION_CHANNEL = "10";

// `A` selects a quantity based pricing scale, `C` bases the scale on quantity, and the condition
// itself is calculated as an amount per unit, which is also `C`.
const PRICING_SCALE_TYPE = "A";
const PRICING_SCALE_BASIS = "C";
const CONDITION_CALCULATION_TYPE = "C";

// The price list to publish. Replace this with the feed of your upstream system. Each material must
// already exist in the sales organization and distribution channel above, and must not have an
// overlapping price for the same condition type, otherwise S/4HANA rejects the record.
final readonly & PriceListEntry[] PRICE_LIST = [
    {
        material: "HW0001",
        price: 249.00,
        currency: "USD",
        quantityUnit: "PC",
        scales: [
            {fromQuantity: 10, price: 239.00},
            {fromQuantity: 50, price: 225.00}
        ]
    },
    {
        material: "LI0001",
        price: 89.50,
        currency: "USD",
        quantityUnit: "PC"
    }
];
