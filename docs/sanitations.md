# SAP S/4HANA OpenAPI Specification Sanitization

_Author_: @niveathika \
_Created_: 2024/05/21 \
_Updated_: 2024/07/02 \
_Edition_: Swan Lake  

## Sanitization Steps

1. Move inline enum parameters to schemas. This simplifies function definitions and enhances documentation. Schema names
   are generated based on the following pattern:  
   `${The Resource Name}Of${Base Path Name}`

2. Remove unnecessary grouping prefixes from schema names. For example:  
   `Api_sales_contract_srvA_Salesorder` -> `A_Salesorder`  
   `com\.sap\.gateway\.srvd_a2x\.api_defect\.v0001\.Defect_Type` -> `Defect`

3. Improve response schema names by removing unnecessary prefixes and suffixes and renaming them to be more
   descriptive.  
   `wrapper` -> `A_InspectionlotWrapper`  
   `Collection of A_InspectionlotType` -> `CollectionOfA_Inspectionlot`

4. Change parameter name to start with lowercase if the response schema is also named the same.
   ```
   "/TaskCode/{TaskCodeGroup}/{TaskCode}": {
      "parameters": [
        ...
        {
          "name": "TaskCode",
          "in": "path",
          "required": true,
          "description": "Code for Classification of a Task",
          "schema": {
            "type": "string",
            "maxLength": 4
          }
        ...
      ],
      "get": {
        "summary": "Get entity from TaskCode by key",
        "responses": {
          "200": {
            "description": "Retrieved entity",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/TaskCode"
                }
              }
            }
          },
          "4XX": {
            "$ref": "#/components/responses/error"
          }
        }
      }
    },
   ```
   ```
   "/TaskCode/{TaskCodeGroup}/{taskCode}": {
      "parameters": [
        ...
        {
          "name": "taskCode",
   ```

5. Add operation Ids. This is more user-friendly with SAP-specific scripts. The logic for parameter sanitization is
   reused, making it less complicated for the tool. The pattern is as follows:  
   `${HTTP Method}${The Resource Name}Of${Base Path Name}`  
   `/salesorder(asdad)/to_Item` => `getTo_ItemOfSalesorder`

   Exceptions: /rejectApprovalRequest, /releaseApprovalRequest, /$batch

## Sanitization for SAP S/4HANA OpenAPI Generated Client

1. Import the `ballerinax/sap` package.

2. Replace `http:Client` with `sap:HttpClient`.

3. Update the initialization parameter `serviceUrl` as follows:
   `string serviceUrl` -> `string hostname, int port = 443`

4. Construct the `serviceUrl` parameter as follows:
   ```
   string serviceUrl = string `https://${hostname}:${port}/sap/opu/odata/sap/API_SALES_ORDER_SRV`;
   ```

5. Rename the generated remote functions and their `<Operation>Queries` records back to the
   sanitized `operationId`s. The OpenAPI tool drops underscores when it derives a Ballerina
   identifier from an `operationId`, which loses the `A_<EntitySet>` naming used by these
   connectors:
   `listASlsPrcgConditionRecords` -> `listA_SlsPrcgConditionRecords`  
   `ListASlsPrcgConditionRecordsQueries` -> `ListA_SlsPrcgConditionRecordsQueries`

   Schema based type names such as `CollectionOfA_SlsPrcgConditionRecordWrapper` already keep the
   underscore, so this keeps the client consistent with both `types.bal` and the other connectors.

   **Note**: This step only runs when the API name is passed to `clientSanitations.bal`.

## Process to Create a New S/4HANA Connector

1. Under `ballerina` directory, create a simple case <API_Name> module.

2. Initialize the module with `bal new .`

3. Add `README.md`, `docs.json` files. For sample, Refer to `api_salesdistrict_srv` module.

4. Add module to the build.

5. Add the `<API_NAME>.json` file under the `docs/spec` directory.

   **Note**: Following scripts need to be run within the `docs` folder.

6. Run `bal run sanitation/sanitations.bal -- "<API Name>"`

7. Run `bal run sanitation/operationId.bal -- "<API Name>"`

   **Note**: Commit each change separately for easier future reviews.

8. Generate the OpenAPI client.

    ```ballerina
    bal openapi -i spec/<API Name>.json -o ../ballerina/<Module Name> --mode client  --license license.txt
    ```
   **Note**: DO NOT FORGET to delete main.bal.

9. Run `bal run sanitation/clientSanitations.bal -- "<Module Name>" "<API Postfix>" "<API Name>"`

   **Note**: The `<API Name>` argument is optional. When it is omitted, the generated remote
   functions keep the names derived by the OpenAPI tool.

10. To generate mock server for tests, remove any parameterized path in the spec and commit
    under `spec/<API_NAME>_MOCK.json`.

11. Generate mock server under `modules/mock` folder.

    ```ballerina
    bal openapi -i spec/<API_NAME>_MOCK.json -o ../ballerina/<Module Name>/modules/mock --mode service  --license license.txt
    ```

12. Ensure the test cases are written against mock and live servers, with `isTestOnLiveServer` as the param to switch. 

## Connectors That Wrap the Generated Client

A connector needs a hand-written wrapper when the service does something the OpenAPI tool cannot express.
`api_slspricingconditionrecord_srv` is the first such module here, because its `$batch` operation is a
`multipart/mixed` envelope whose parts are complete HTTP requests. That is a transport encoding rather
than a data shape, so no OpenAPI contract can describe it and the generated operation only ever hands
back a raw `http:Request`.

Those modules keep the generated code in an `oas` submodule, so that regenerating never touches the
hand-written code:

```
ballerina/<Module Name>/
├── Ballerina.toml      # declares the oas submodule with export = true
├── client.bal          # hand-written wrapper, forwards to oas and adds what is missing
├── util.bal            # the hand-written support code
└── modules/oas/        # generated, never edited by hand
    ├── client.bal
    ├── types.bal
    └── utils.bal
```

`Ballerina.toml` has to export the submodule, otherwise callers cannot reference the generated types:

```toml
[[package.modules]]
name = "<Package Name>.oas"
export = true
```

The generation steps above stay the same, except that the output directory and the module name passed to
the client sanitation both point at the submodule:

```ballerina
bal openapi -i spec/<API Name>.json -o ../ballerina/<Module Name>/modules/oas --mode client --license license.txt
bal run sanitation/clientSanitations.bal -- "<Module Name>/modules/oas" "<API Postfix>" "<API Name>"
```

The wrapper forwards every generated operation unchanged, so it has to be revisited whenever the
regenerated `oas` module gains, loses or changes an operation.
