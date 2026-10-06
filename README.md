# Item Substitution API for Business Central

## Antes de empezar

Extensión de ejemplo para consultar y gestionar sustitutos de artículos mediante APIs y acciones AL.

**Referencia del checkout:** `application 26.0.0.0`, `runtime 15.2`; extensión `ItemSubsAPI` versión `1.0.0.0`. Es la configuración del manifiesto, no una prueba de compatibilidad con otros entornos.

1. Clona `https://github.com/javiarmesto/ItemSubTool.git` y abre la carpeta en VS Code con AL Language.
2. Configura tu sandbox en `.vscode/launch.json` (créalo si falta), comprueba las dependencias de [app.json](app.json) y descarga símbolos con **AL: Download Symbols**.
3. Compila con `Ctrl+Shift+B`; publica en el sandbox con `F5` cuando hayas completado la configuración específica del ejemplo.
4. Sigue los datos de prueba y comprueba las respuestas de la API en tu sandbox. Crear, actualizar o desactivar sustitutos modifica datos; registra la respuesta real, no solo el ejemplo del README.

**Mapa del ejemplo:** [SETUP_GUIDE](SETUP_GUIDE.md) → [TEST_DATA](TEST_DATA.md) → [VALIDATION_SCRIPTS](VALIDATION_SCRIPTS.md); `src/` para implementación y `test/` para pruebas.

**Límites:** Las respuestas JSON de esta guía son ejemplos. Comprueba rutas, publicación y autorización en tu entorno; no se ha confirmado una licencia aplicable. La revisión documental del 6 de octubre de 2026 es estática; no acredita compilación, publicación ni llamadas a servicios externos.


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
