# Item Substitution API for Business Central

## Overview

This extension provides a robust and secure API for managing item substitutions within Microsoft Dynamics 365 Business Central.

It is designed with a layered architecture to ensure data integrity and to provide a clean, easy-to-use interface for external applications. Key features include advanced validation against circular dependencies and a dedicated set of API actions for simplified integration.

## Key Features

- **CRUD Operations:** Create, Read, Update, and Deactivate item substitutions.
- **Advanced Validation:** Automatically detects and prevents circular substitute references (e.g., A -> B -> C -> A).
- **Soft-Delete:** Deactivating a substitute sets an expiry date rather than deleting the record, preserving historical data.
- **Layered Architecture:** A clear separation of concerns between the API presentation layer, the service/tool layer, and the core business logic layer.
- **Dual API Models:**
  1.  **Actions API (Recommended):** A set of explicit, service-enabled procedures for common operations.
  2.  **Standard OData API:** Standard RESTful access to the underlying data entities.

---

## API Usage (Recommended: Actions API)

The recommended way to interact with this extension is through the **Actions API**, which simplifies calls from external systems.

**Base URL:**
`{BC_Base_URL}/api/custom/itemSubstitution/v1.0/companies({companyId})/itemSubstituteActions({dummyKey})`

Replace `{dummyKey}` with a placeholder, for example: `itemNo='-',sequence=0`.

### 1. Get Item Substitutes

Retrieves all valid substitutes for a given item.

- **Action:** `GetItemSubstitutes`
- **Method:** `POST`
- **Request Body:**
  ```json
  {
      "itemNo": "ITEM001"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
      "success": true,
      "itemNo": "ITEM001",
      "substitutes": [
          {
              "itemNo": "ITEM001",
              "substituteNo": "SUB001",
              "priority": 1,
              "effectiveDate": "2025-08-11",
              "notes": "Primary substitute"
          }
      ],
      "count": 1
  }
  ```

### 2. Create Item Substitute

Creates a new, validated substitute relationship.

- **Action:** `CreateItemSubstitute`
- **Method:** `POST`
- **Request Body:**
  ```json
  {
      "itemNo": "ITEM001",
      "substituteNo": "SUB002",
      "priority": 2,
      "effectiveDate": "2025-01-01",
      "expiryDate": "2026-01-01",
      "notes": "Promotional substitute"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
      "success": true,
      "message": "Item substitute created successfully",
      "data": {
          "itemNo": "ITEM001",
          "substituteNo": "SUB002",
          "priority": 2,
          "effectiveDate": "2025-01-01",
          "expiryDate": "2026-01-01",
          "notes": "Promotional substitute",
          "createdBy": "USER",
          "creationDateTime": "2025-08-11T14:30:00"
      }
  }
  ```
- **Error Response (200 OK):**
  ```json
  {
      "success": false,
      "error": "Se detectó referencia circular entre ITEM001 y SUB002."
  }
  ```

### 3. Update Item Substitute

Updates the `Priority` or `Notes` of an existing substitute.

- **Action:** `UpdateItemSubstitute`
- **Method:** `POST`
- **Request Body:**
  ```json
  {
      "itemNo": "ITEM001",
      "substituteNo": "SUB001",
      "newPriority": 5,
      "newNotes": "Updated notes"
  }
  ```

### 4. Deactivate Item Substitute

Performs a soft-delete by setting the `Expiry Date` to the current date.

- **Action:** `DeactivateItemSubstitute`
- **Method:** `POST`
- **Request Body:**
  ```json
  {
      "itemNo": "ITEM001",
      "substituteNo": "SUB001"
  }
  ```

---

## Architecture Overview

The extension is built with a clean, layered architecture:

1.  **API Layer (`Page` objects):**
    - `Page 50212 "Item Substitute Actions API"`: Exposes the service-enabled actions (Recommended).
    - `Page 50210 "Item Substitution API"`: Provides standard OData REST access (`GET`, `POST`, `PATCH`, `DELETE`).
    - `Page 50211 "Item Sub Chain API"`: A read-only endpoint to get the full substitution chain.

2.  **Service/Tool Layer (`Codeunit 50204 "Item Substitute MCP Tool"`):**
    - Acts as a facade for the API layer.
    - Handles input validation and formats consistent JSON responses for the actions.
    - Orchestrates calls to the core logic layer.

3.  **Core Logic Layer (`Codeunit 50202 "Substitute Management"`):**
    - Contains the critical business logic, including the circular dependency detection algorithm.
    - Ensures data integrity regardless of how the data is accessed.

---

## Setup & Installation

*(Placeholder for setup and installation instructions)*