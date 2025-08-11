# Item Substitutes API - MCP Tool Integration

Esta extensión AL implementa una API completa para gestionar productos sustitutos en Business Central, optimizada para ser utilizada como herramienta en MCP (Model Context Protocol) servers.

## Características Principales

- ✅ **API RESTful** para CRUD de sustituciones
- ✅ **Codeunit MCP Tool** con funciones especializadas
- ✅ **Validación de reglas de negocio** (circular references, items existentes)
- ✅ **Respuestas JSON estructuradas** para integración MCP
- ✅ **Soft delete** mediante fechas de expiración
- ✅ **Auditoría automática** (Created By, Creation DateTime)
- ✅ **Priorización** de sustitutos (1-10)

## Endpoints Disponibles

### 1. API RESTful (OData v4) - CRUD Estándar

```http
GET    /api/custom/itemSubstitution/v1.0/companies({id})/itemSubstitutions
POST   /api/custom/itemSubstitution/v1.0/companies({id})/itemSubstitutions
PATCH  /api/custom/itemSubstitution/v1.0/companies({id})/itemSubstitutions({keys})
DELETE /api/custom/itemSubstitution/v1.0/companies({id})/itemSubstitutions({keys})
```

### 2. MCP Actions API (Unbound Actions) - **Recomendado para MCP Servers**

```http
POST /api/custom/itemSubstitution/v1.0/companies({id})/itemSubstituteActions/Microsoft.NAV.CreateItemSubstitute
POST /api/custom/itemSubstitution/v1.0/companies({id})/itemSubstituteActions/Microsoft.NAV.GetItemSubstitutes  
POST /api/custom/itemSubstitution/v1.0/companies({id})/itemSubstituteActions/Microsoft.NAV.UpdateItemSubstitute
POST /api/custom/itemSubstitution/v1.0/companies({id})/itemSubstituteActions/Microsoft.NAV.DeactivateItemSubstitute
```

### 3. Legacy Web Services (Fallback)

```http
POST /ODataV4/Company('{company}')/ItemSubstituteMCPTool_CreateItemSubstitute
POST /ODataV4/Company('{company}')/ItemSubstituteMCPTool_GetItemSubstitutes
POST /ODataV4/Company('{company}')/ItemSubstituteMCPTool_UpdateItemSubstitute
POST /ODataV4/Company('{company}')/ItemSubstituteMCPTool_DeactivateItemSubstitute
```

## Uso en MCP Server

### Ejemplo 1: Crear Sustituto

```javascript
// Método 1: Unbound Action (Recomendado para MCP)
const result = await callBusinessCentral({
  method: 'POST',
  url: '/api/custom/itemSubstitution/v1.0/companies(\'CRONUS ES\')/itemSubstituteActions/Microsoft.NAV.CreateItemSubstitute',
  body: {
    ItemNo: '1000',
    SubstituteNo: '1001',
    Priority: 1,
    EffectiveDate: '2025-08-11',
    ExpiryDate: '2025-12-31',
    Notes: 'Sustituto preferido para temporada alta'
  }
});

// Método 2: Web Service Legacy (Fallback)
const resultLegacy = await callBusinessCentral({
  method: 'POST',
  url: '/ODataV4/Company(\'CRONUS ES\')/ItemSubstituteMCPTool_CreateItemSubstitute',
  body: {
    ItemNo: '1000',
    SubstituteNo: '1001',
    Priority: 1,
    EffectiveDate: '2025-08-11',
    ExpiryDate: '2025-12-31',
    Notes: 'Sustituto preferido para temporada alta'
  }
});
```
{
  "success": true,
  "message": "Item substitute created successfully",
  "data": {
    "itemNo": "1000",
    "substituteNo": "1001", 
    "priority": 1,
    "effectiveDate": "2025-08-11",
    "expiryDate": "2025-12-31",
    "notes": "Sustituto preferido para temporada alta",
    "createdBy": "USER123",
    "creationDateTime": "2025-08-11T14:30:00"
  }
}
```

### Ejemplo 2: Obtener Sustitutos

```javascript
// Método 1: Unbound Action (Recomendado para MCP)
const substitutes = await callBusinessCentral({
  method: 'POST',
  url: '/api/custom/itemSubstitution/v1.0/companies(\'CRONUS ES\')/itemSubstituteActions/Microsoft.NAV.GetItemSubstitutes',
  body: {
    ItemNo: '1000'
  }
});

// Método 2: Web Service Legacy (Fallback)
const substitutesLegacy = await callBusinessCentral({
  method: 'POST',
  url: '/ODataV4/Company(\'CRONUS ES\')/ItemSubstituteMCPTool_GetItemSubstitutes',
  body: {
    ItemNo: '1000'
  }
});
```

Respuesta JSON:
{
  "success": true,
  "itemNo": "1000",
  "count": 2,
  "substitutes": [
    {
      "itemNo": "1000",
      "substituteNo": "1001",
      "priority": 1,
      "effectiveDate": "2025-08-11",
      "notes": "Sustituto preferido"
    },
    {
      "itemNo": "1000", 
      "substituteNo": "1002",
      "priority": 2,
      "effectiveDate": "2025-08-11",
      "notes": "Sustituto secundario"
    }
  ]
}
```

### Ejemplo 3: Actualizar Prioridad
```javascript
const update = await callBusinessCentral({
  method: 'POST',
  url: '/ODataV4/Company(\'CRONUS ES\')/ItemSubstituteMCPTool_UpdateItemSubstitute',
  body: {
    ItemNo: '1000',
    SubstituteNo: '1001',
    NewPriority: 3,
    NewNotes: 'Actualizado por sistema MCP'
  }
});
```

### Ejemplo 4: Desactivar Sustituto (Soft Delete)
```javascript
const deactivate = await callBusinessCentral({
  method: 'POST',
  url: '/ODataV4/Company(\'CRONUS ES\')/ItemSubstituteMCPTool_DeactivateItemSubstitute',
  body: {
    ItemNo: '1000',
    SubstituteNo: '1001'
  }
});
```

## Configuración

### 1. Permisos
Asignar permission set `ITEMSUBS API` a usuarios/aplicaciones que utilizarán la API.

### 2. Autenticación
Configurar OAuth 2.0 o API Key según políticas de tu entorno Business Central.

### 3. Compilación
```powershell
# Desde VS Code con AL Extension
Ctrl+Shift+P > AL: Publish
```

## Validaciones Implementadas

1. **Items deben existir** - Valida que tanto el item principal como el sustituto existan
2. **No auto-referencia** - Un item no puede ser sustituto de sí mismo  
3. **No referencias circulares** - Detecta cadenas circulares (A→B→C→A)
4. **Prioridad válida** - Range 1-10, donde 1 es mayor prioridad
5. **Fechas lógicas** - Effective Date <= Expiry Date
6. **Duplicados** - No permite crear relaciones que ya existen

## Estructura de Respuestas JSON

Todas las funciones MCP devuelven JSON estructurado:

```typescript
interface MCPResponse {
  success: boolean;
  message?: string;
  error?: string;
  data?: any;
}
```

## Testing

Ejecutar tests unitarios:
```powershell
# Desde terminal AL
Test-ALCodeunit -CodeunitId 50240 -CompanyName "CRONUS ES"
```

## Troubleshooting

### Error: "Field does not exist"
- Ejecutar `AL: Download Symbols` en VS Code
- Verificar que los símbolos base estén actualizados

### Error: "Permission denied"
- Verificar assignment del permission set `ITEMSUBS API`
- Validar configuración OAuth/API Key

### Error: "Circular reference detected"
- Normal - es una validación de negocio
- Revisar cadena de sustituciones antes de crear nueva relación

## Roadmap

- [ ] Bulk operations para múltiples sustitutos
- [ ] Integration events para workflows personalizados  
- [ ] Performance optimization para cadenas >100 items
- [ ] Webhooks para notificaciones en tiempo real
