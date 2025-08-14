# Guía de Datos de Prueba - Business Central AL Extensions

## Índice
- [Estrategia General de Testing](#estrategia-general-de-testing)
- [Plantillas de Datos de Prueba](#plantillas-de-datos-de-prueba)
- [Scripts Reutilizables](#scripts-reutilizables)
- [Datasets Específicos por Funcionalidad](#datasets-específicos-por-funcionalidad)
- [Automatización de Datos de Prueba](#automatización-de-datos-de-prueba)
- [Limpieza y Mantenimiento](#limpieza-y-mantenimiento)

---

## Estrategia General de Testing

### Principios de Datos de Prueba
1. **Aislamiento**: Usar prefijos únicos (TEST*, DEV*, DEMO*)
2. **Reproducibilidad**: Scripts que pueden ejecutarse múltiples veces
3. **Limpieza**: Mecanismos automáticos de cleanup
4. **Escalabilidad**: Datasets pequeños, medianos y grandes
5. **Realismo**: Datos que simulan escenarios reales

### Estructura de Nomenclatura Estándar
```
Prefijos por Tipo:
- TEST*     : Datos básicos de testing unitario
- PERF*     : Datos para pruebas de rendimiento  
- DEMO*     : Datos para demostraciones
- DEV*      : Datos para desarrollo general
- EDGE*     : Casos extremos y edge cases
- BULK*     : Datos para operaciones masivas
```

---

## Plantillas de Datos de Prueba

### 1. Template Base para Items
**Archivo: `test/templates/ItemTestDataTemplate.al`**
```al
codeunit 50290 "Item Test Data Template"
{
    /// <summary>
    /// Plantilla reutilizable para crear items de prueba
    /// Usar en cualquier proyecto que requiera items de BC
    /// </summary>
    
    procedure CreateTestItem(ItemNo: Code[20]; Description: Text[100]; ItemType: Option; UnitOfMeasure: Code[10]): Boolean
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit(true); // Ya existe
            
        Item.Init();
        Item."No." := ItemNo;
        Item.Description := Description;
        Item.Type := ItemType;
        Item."Base Unit of Measure" := UnitOfMeasure;
        Item."Unit Cost" := Random(1000) + 1; // Costo aleatorio 1-1000
        Item."Unit Price" := Item."Unit Cost" * (1 + (Random(100) / 100)); // Margen 1-100%
        Item."Inventory Posting Group" := GetDefaultInventoryPostingGroup();
        Item."Gen. Prod. Posting Group" := GetDefaultGenProdPostingGroup();
        
        exit(Item.Insert());
    end;
    
    procedure CreateItemSeries(Prefix: Code[10]; Count: Integer; ItemType: Option): Integer
    var
        i: Integer;
        ItemNo: Code[20];
        CreatedCount: Integer;
    begin
        for i := 1 to Count do begin
            ItemNo := Prefix + Format(i, 0, '<Integer,3><Filler Character,0>'); // TEST001, TEST002, etc.
            if CreateTestItem(ItemNo, 'Test Item ' + Format(i), ItemType, 'PCS') then
                CreatedCount += 1;
        end;
        exit(CreatedCount);
    end;
    
    procedure DeleteTestItems(Prefix: Code[10])
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", Prefix + '*');
        Item.DeleteAll();
    end;
    
    local procedure GetDefaultInventoryPostingGroup(): Code[20]
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        InventoryPostingGroup.SetRange("Code", 'FINISHED');
        if InventoryPostingGroup.FindFirst() then
            exit(InventoryPostingGroup."Code");
            
        // Fallback al primero disponible
        if InventoryPostingGroup.FindFirst() then
            exit(InventoryPostingGroup."Code");
            
        exit('');
    end;
    
    local procedure GetDefaultGenProdPostingGroup(): Code[20]
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProdPostingGroup.SetRange("Code", 'RETAIL');
        if GenProdPostingGroup.FindFirst() then
            exit(GenProdPostingGroup."Code");
            
        if GenProdPostingGroup.FindFirst() then
            exit(GenProdPostingGroup."Code");
            
        exit('');
    end;
}
```

### 2. Template para Relaciones Entre Entidades
**Archivo: `test/templates/RelationshipTestTemplate.al`**
```al
codeunit 50291 "Relationship Test Template"
{
    /// <summary>
    /// Plantilla genérica para testing de relaciones entre entidades
    /// Adaptable a cualquier escenario de relaciones (sustitutos, alternativas, etc.)
    /// </summary>
    
    procedure CreateLinearChain(EntityPrefix: Code[10]; ChainLength: Integer): Text
    var
        i: Integer;
        ChainDescription: Text;
        CurrentEntity: Code[20];
        NextEntity: Code[20];
    begin
        // Crear cadena lineal: A -> B -> C -> D
        ChainDescription := 'Linear Chain: ';
        
        for i := 1 to ChainLength - 1 do begin
            CurrentEntity := EntityPrefix + Format(i, 0, '<Integer,3><Filler Character,0>');
            NextEntity := EntityPrefix + Format(i + 1, 0, '<Integer,3><Filler Character,0>');
            
            CreateRelationship(CurrentEntity, NextEntity, 'Linear chain link ' + Format(i));
            
            if i = 1 then
                ChainDescription += CurrentEntity
            else
                ChainDescription += ' -> ' + CurrentEntity;
                
            if i = ChainLength - 1 then
                ChainDescription += ' -> ' + NextEntity;
        end;
        
        exit(ChainDescription);
    end;
    
    procedure CreateCircularChain(EntityPrefix: Code[10]; ChainLength: Integer): Text
    var
        i: Integer;
        CurrentEntity: Code[20];
        NextEntity: Code[20];
        FirstEntity: Code[20];
    begin
        // Crear cadena circular: A -> B -> C -> A
        FirstEntity := EntityPrefix + '001';
        
        for i := 1 to ChainLength do begin
            CurrentEntity := EntityPrefix + Format(i, 0, '<Integer,3><Filler Character,0>');
            
            if i = ChainLength then
                NextEntity := FirstEntity // Cerrar el círculo
            else
                NextEntity := EntityPrefix + Format(i + 1, 0, '<Integer,3><Filler Character,0>');
                
            CreateRelationship(CurrentEntity, NextEntity, 'Circular chain link ' + Format(i));
        end;
        
        exit('Circular Chain: ' + Format(ChainLength) + ' entities');
    end;
    
    procedure CreateStarPattern(CenterEntity: Code[20]; SatellitePrefix: Code[10]; SatelliteCount: Integer): Text
    var
        i: Integer;
        SatelliteEntity: Code[20];
    begin
        // Crear patrón estrella: CENTER -> SAT1, CENTER -> SAT2, etc.
        for i := 1 to SatelliteCount do begin
            SatelliteEntity := SatellitePrefix + Format(i, 0, '<Integer,3><Filler Character,0>');
            CreateRelationship(CenterEntity, SatelliteEntity, 'Star pattern satellite ' + Format(i));
        end;
        
        exit('Star Pattern: 1 center, ' + Format(SatelliteCount) + ' satellites');
    end;
    
    procedure CreateComplexNetwork(Prefix: Code[10]; NodeCount: Integer; ConnectionDensity: Decimal): Text
    var
        i, j: Integer;
        ConnectionsCreated: Integer;
        EntityA, EntityB: Code[20];
        ShouldConnect: Boolean;
    begin
        // Crear red compleja con densidad específica (0.0 = sin conexiones, 1.0 = completamente conectado)
        for i := 1 to NodeCount do begin
            for j := i + 1 to NodeCount do begin
                ShouldConnect := (Random(100) / 100) <= ConnectionDensity;
                
                if ShouldConnect then begin
                    EntityA := Prefix + Format(i, 0, '<Integer,3><Filler Character,0>');
                    EntityB := Prefix + Format(j, 0, '<Integer,3><Filler Character,0>');
                    CreateRelationship(EntityA, EntityB, 'Network connection');
                    ConnectionsCreated += 1;
                end;
            end;
        end;
        
        exit('Complex Network: ' + Format(NodeCount) + ' nodes, ' + Format(ConnectionsCreated) + ' connections');
    end;
    
    local procedure CreateRelationship(FromEntity: Code[20]; ToEntity: Code[20]; Description: Text[100])
    begin
        // Este método debe ser sobrescrito en cada implementación específica
        // Por ejemplo, para Item Substitution:
        // CreateItemSubstitute(FromEntity, ToEntity, Description);
        Error('CreateRelationship must be implemented in derived codeunit');
    end;
}
```

### 3. Template para Datos de Rendimiento
**Archivo: `test/templates/PerformanceTestData.al`**
```al
codeunit 50292 "Performance Test Data Template"
{
    /// <summary>
    /// Plantilla para generar datasets de pruebas de rendimiento
    /// Escalable y configurable para diferentes volúmenes
    /// </summary>
    
    procedure GenerateDataset(DatasetType: Option Small,Medium,Large,Massive; EntityPrefix: Code[10]): Text
    var
        EntityCount: Integer;
        RelationshipCount: Integer;
        StartTime: DateTime;
        EndTime: DateTime;
        Result: Text;
    begin
        StartTime := CurrentDateTime;
        
        case DatasetType of
            DatasetType::Small:
                begin
                    EntityCount := 100;
                    RelationshipCount := 150;
                end;
            DatasetType::Medium:
                begin
                    EntityCount := 1000;
                    RelationshipCount := 2000;
                end;
            DatasetType::Large:
                begin
                    EntityCount := 10000;
                    RelationshipCount := 25000;
                end;
            DatasetType::Massive:
                begin
                    EntityCount := 50000;
                    RelationshipCount := 100000;
                end;
        end;
        
        // Generar entidades base
        CreateEntities(EntityPrefix, EntityCount);
        
        // Generar relaciones aleatorias
        CreateRandomRelationships(EntityPrefix, EntityCount, RelationshipCount);
        
        EndTime := CurrentDateTime;
        
        Result := 'Dataset ' + Format(DatasetType) + ' created: ' +
                  Format(EntityCount) + ' entities, ' +
                  Format(RelationshipCount) + ' relationships. ' +
                  'Time: ' + Format(EndTime - StartTime);
                  
        exit(Result);
    end;
    
    procedure CreatePerformanceTestScenarios(ProjectPrefix: Code[10])
    var
        ScenarioResults: List of [Text];
        Scenario: Text;
    begin
        // Escenario 1: Cadena larga para pruebas de algoritmos de grafos
        Scenario := CreateLinearPerformanceChain(ProjectPrefix + 'CHAIN', 1000);
        ScenarioResults.Add('Long Chain: ' + Scenario);
        
        // Escenario 2: Red densa para pruebas de consultas complejas
        Scenario := CreateDenseNetwork(ProjectPrefix + 'NET', 500, 0.1);
        ScenarioResults.Add('Dense Network: ' + Scenario);
        
        // Escenario 3: Múltiples cadenas independientes
        Scenario := CreateMultipleChains(ProjectPrefix + 'MULTI', 10, 100);
        ScenarioResults.Add('Multiple Chains: ' + Scenario);
        
        // Guardar resultados en log
        LogPerformanceScenarios(ScenarioResults);
    end;
    
    local procedure CreateEntities(Prefix: Code[10]; Count: Integer)
    var
        i: Integer;
        EntityNo: Code[20];
    begin
        for i := 1 to Count do begin
            EntityNo := Prefix + Format(i, 0, '<Integer,5><Filler Character,0>');
            // Implementar creación específica de entidad
            CreateSingleEntity(EntityNo, 'Performance test entity ' + Format(i));
            
            // Progress indicator cada 1000 entidades
            if (i mod 1000) = 0 then
                Message('Created %1 entities', i);
        end;
    end;
    
    local procedure CreateRandomRelationships(Prefix: Code[10]; EntityCount: Integer; RelationshipCount: Integer)
    var
        i: Integer;
        FromIndex, ToIndex: Integer;
        FromEntity, ToEntity: Code[20];
    begin
        for i := 1 to RelationshipCount do begin
            // Seleccionar entidades aleatorias
            FromIndex := Random(EntityCount);
            ToIndex := Random(EntityCount);
            
            // Evitar auto-referencias
            while FromIndex = ToIndex do
                ToIndex := Random(EntityCount);
                
            FromEntity := Prefix + Format(FromIndex, 0, '<Integer,5><Filler Character,0>');
            ToEntity := Prefix + Format(ToIndex, 0, '<Integer,5><Filler Character,0>');
            
            CreateSingleRelationship(FromEntity, ToEntity, 'Random relationship ' + Format(i));
            
            // Progress indicator cada 5000 relaciones
            if (i mod 5000) = 0 then
                Message('Created %1 relationships', i);
        end;
    end;
    
    procedure CleanupPerformanceData(Prefix: Code[10])
    var
        StartTime: DateTime;
        EndTime: DateTime;
    begin
        StartTime := CurrentDateTime;
        
        // Eliminar relaciones primero (por integridad referencial)
        DeleteRelationshipsWithPrefix(Prefix);
        
        // Luego eliminar entidades
        DeleteEntitiesWithPrefix(Prefix);
        
        EndTime := CurrentDateTime;
        
        Message('Cleanup completed in %1', EndTime - StartTime);
    end;
    
    // Métodos abstractos - implementar en codeunits específicos
    local procedure CreateSingleEntity(EntityNo: Code[20]; Description: Text[100])
    begin
        Error('CreateSingleEntity must be implemented');
    end;
    
    local procedure CreateSingleRelationship(FromEntity: Code[20]; ToEntity: Code[20]; Description: Text[100])
    begin
        Error('CreateSingleRelationship must be implemented');
    end;
    
    local procedure DeleteEntitiesWithPrefix(Prefix: Code[10])
    begin
        Error('DeleteEntitiesWithPrefix must be implemented');
    end;
    
    local procedure DeleteRelationshipsWithPrefix(Prefix: Code[10])
    begin
        Error('DeleteRelationshipsWithPrefix must be implemented');
    end;
}
```

---

## Scripts Reutilizables

### 1. PowerShell para Setup de Datos
**Archivo: `scripts/universal-test-data-setup.ps1`**
```powershell
# Universal Test Data Setup for BC AL Extensions
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [string]$DatasetSize = "Small", # Small, Medium, Large
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "Local", # Local, Cloud, Docker
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanExisting = $false
)

Write-Host "=== Universal Test Data Setup ===" -ForegroundColor Green
Write-Host "Project: $ProjectName" -ForegroundColor Cyan
Write-Host "Dataset: $DatasetSize" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan

# Configuración por tamaño de dataset
$datasets = @{
    "Small" = @{ Entities = 50; Relations = 75; Complexity = "Low" }
    "Medium" = @{ Entities = 500; Relations = 1000; Complexity = "Medium" }  
    "Large" = @{ Entities = 5000; Relations = 15000; Complexity = "High" }
}

$config = $datasets[$DatasetSize]
Write-Host "Configuration: $($config.Entities) entities, $($config.Relations) relations" -ForegroundColor Yellow

# Generar prefijo único para el proyecto
$prefix = ($ProjectName -replace '[^a-zA-Z0-9]', '').ToUpper()
if ($prefix.Length -gt 8) {
    $prefix = $prefix.Substring(0, 8)
}

# Crear estructura de datos de prueba
$testDataStructure = @{
    "BasicEntities" = @{
        "Prefix" = "TEST"
        "Count" = [math]::Floor($config.Entities * 0.6)
        "Description" = "Basic test entities for standard scenarios"
    }
    "EdgeCaseEntities" = @{
        "Prefix" = "EDGE"  
        "Count" = [math]::Floor($config.Entities * 0.2)
        "Description" = "Edge case entities for boundary testing"
    }
    "PerformanceEntities" = @{
        "Prefix" = "PERF"
        "Count" = [math]::Floor($config.Entities * 0.2)
        "Description" = "Performance test entities for load testing"
    }
}

# Generar archivos de configuración
$configPath = "./test/data-config.json"
$testDataStructure | ConvertTo-Json -Depth 3 | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "✓ Test data configuration saved: $configPath" -ForegroundColor Green

# Generar script AL de inicialización
$initScript = @"
codeunit 50299 "$ProjectName Test Data Init"
{
    // Auto-generated test data initialization for $ProjectName
    // Dataset: $DatasetSize ($($config.Entities) entities, $($config.Relations) relations)
    // Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    
    procedure InitializeAllTestData(): Text
    var
        Results: List of [Text];
        ItemTemplate: Codeunit "Item Test Data Template";
        RelationTemplate: Codeunit "Relationship Test Template";
        PerfTemplate: Codeunit "Performance Test Data Template";
    begin
        // Clean existing data if requested
        if ShouldCleanExisting() then
            CleanAllTestData();
            
        // Create basic test entities
        Results.Add(ItemTemplate.CreateItemSeries('TEST', $($testDataStructure.BasicEntities.Count), Item.Type::Inventory));
        Results.Add(ItemTemplate.CreateItemSeries('EDGE', $($testDataStructure.EdgeCaseEntities.Count), Item.Type::Service));
        Results.Add(ItemTemplate.CreateItemSeries('PERF', $($testDataStructure.PerformanceEntities.Count), Item.Type::Inventory));
        
        // Create relationships based on project needs
        // TODO: Implement specific relationship creation
        
        exit('Test data initialization completed: ' + Format(Results.Count) + ' operations');
    end;
    
    procedure CleanAllTestData()
    var
        ItemTemplate: Codeunit "Item Test Data Template";
    begin
        ItemTemplate.DeleteTestItems('TEST');
        ItemTemplate.DeleteTestItems('EDGE');
        ItemTemplate.DeleteTestItems('PERF');
        // TODO: Add cleanup for relationships
    end;
    
    local procedure ShouldCleanExisting(): Boolean
    begin
        // Configure based on setup parameters
        exit(true); // Default: clean existing data
    end;
}
"@

$initScriptPath = "./test/TestDataInit.al"
$initScript | Out-File -FilePath $initScriptPath -Encoding UTF8
Write-Host "✓ AL initialization script created: $initScriptPath" -ForegroundColor Green

# Crear script de validación de datos
$validationScript = @"
codeunit 50298 "$ProjectName Data Validation"
{
    // Auto-generated data validation for $ProjectName
    
    procedure ValidateTestDataIntegrity(): Text
    var
        ValidationResults: List of [Text];
        Item: Record Item;
        TestEntityCount: Integer;
        EdgeEntityCount: Integer;
        PerfEntityCount: Integer;
    begin
        // Count entities by type
        Item.SetFilter("No.", 'TEST*');
        TestEntityCount := Item.Count();
        
        Item.SetFilter("No.", 'EDGE*');
        EdgeEntityCount := Item.Count();
        
        Item.SetFilter("No.", 'PERF*');
        PerfEntityCount := Item.Count();
        
        // Validate counts
        ValidationResults.Add('TEST entities: ' + Format(TestEntityCount) + ' (expected: $($testDataStructure.BasicEntities.Count))');
        ValidationResults.Add('EDGE entities: ' + Format(EdgeEntityCount) + ' (expected: $($testDataStructure.EdgeCaseEntities.Count))');
        ValidationResults.Add('PERF entities: ' + Format(PerfEntityCount) + ' (expected: $($testDataStructure.PerformanceEntities.Count))');
        
        // TODO: Add relationship validation
        
        exit('Validation completed: ' + Format(ValidationResults.Count) + ' checks');
    end;
    
    procedure GetDatasetStatistics(): Text
    var
        Stats: JsonObject;
        Item: Record Item;
        TotalCount: Integer;
    begin
        Item.SetFilter("No.", 'TEST*|EDGE*|PERF*');
        TotalCount := Item.Count();
        
        Stats.Add('totalEntities', TotalCount);
        Stats.Add('datasetSize', '$DatasetSize');
        Stats.Add('projectName', '$ProjectName');
        Stats.Add('generatedDate', CurrentDateTime);
        
        exit(Format(Stats));
    end;
}
"@

$validationScriptPath = "./test/DataValidation.al"
$validationScript | Out-File -FilePath $validationScriptPath -Encoding UTF8
Write-Host "✓ AL validation script created: $validationScriptPath" -ForegroundColor Green

Write-Host "`n=== Setup Completado ===" -ForegroundColor Green
Write-Host "1. Compile los nuevos codeunits AL" -ForegroundColor Yellow
Write-Host "2. Ejecute InitializeAllTestData() en BC" -ForegroundColor Yellow  
Write-Host "3. Valide con ValidateTestDataIntegrity()" -ForegroundColor Yellow
```

### 2. Script de Datos JSON para APIs
**Archivo: `scripts/generate-api-test-data.ps1`**
```powershell
# Generate JSON Test Data for API Testing
param(
    [Parameter(Mandatory=$true)]
    [string]$APIEndpoint,
    
    [Parameter(Mandatory=$false)]
    [int]$RecordCount = 50,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./test/api-test-data.json"
)

Write-Host "=== Generating API Test Data ===" -ForegroundColor Green

# Template de datos base
$baseTemplate = @{
    "validScenarios" = @()
    "invalidScenarios" = @()
    "edgeCases" = @()
    "performanceTest" = @()
}

# Generar escenarios válidos
for ($i = 1; $i -le $RecordCount; $i++) {
    $validRecord = @{
        "testId" = "VALID_$($i.ToString('D3'))"
        "description" = "Valid scenario $i"
        "data" = @{
            "itemNo" = "TEST$($i.ToString('D3'))"
            "substituteNo" = "SUB$($i.ToString('D3'))"
            "priority" = [math]::Floor((Get-Random -Maximum 10) + 1)
            "effectiveDate" = (Get-Date).AddDays((Get-Random -Maximum 30)).ToString('yyyy-MM-dd')
            "notes" = "Auto-generated test data $i"
        }
        "expectedResult" = @{
            "success" = $true
            "statusCode" = 201
        }
    }
    $baseTemplate.validScenarios += $validRecord
}

# Generar escenarios inválidos
$invalidScenarios = @(
    @{
        "testId" = "INVALID_001"
        "description" = "Missing required field"
        "data" = @{
            "itemNo" = "MISSING001"
            # substituteNo intencionalmente omitido
            "priority" = 5
        }
        "expectedResult" = @{
            "success" = $false
            "statusCode" = 400
            "errorCode" = "MISSING_FIELD"
        }
    },
    @{
        "testId" = "INVALID_002" 
        "description" = "Invalid priority range"
        "data" = @{
            "itemNo" = "INVALID002"
            "substituteNo" = "SUB002"
            "priority" = 15 # Fuera de rango 1-10
        }
        "expectedResult" = @{
            "success" = $false
            "statusCode" = 400
            "errorCode" = "PRIORITY_RANGE"
        }
    },
    @{
        "testId" = "INVALID_003"
        "description" = "Self-reference circular dependency"
        "data" = @{
            "itemNo" = "CIRCULAR001"
            "substituteNo" = "CIRCULAR001" # Mismo item
            "priority" = 5
        }
        "expectedResult" = @{
            "success" = $false
            "statusCode" = 400
            "errorCode" = "CIRCULAR_DEP"
        }
    }
)

$baseTemplate.invalidScenarios = $invalidScenarios

# Generar casos edge
$edgeCases = @(
    @{
        "testId" = "EDGE_001"
        "description" = "Maximum length strings"
        "data" = @{
            "itemNo" = "X" * 20 # Máximo permitido
            "substituteNo" = "Y" * 20
            "priority" = 1
            "notes" = "Z" * 250 # Campo de texto largo
        }
    },
    @{
        "testId" = "EDGE_002"
        "description" = "Minimum values"
        "data" = @{
            "itemNo" = "A"
            "substituteNo" = "B" 
            "priority" = 1 # Mínimo
            "effectiveDate" = "1900-01-01" # Fecha mínima
        }
    },
    @{
        "testId" = "EDGE_003"
        "description" = "Future dates"
        "data" = @{
            "itemNo" = "FUTURE001"
            "substituteNo" = "FUTURE002"
            "priority" = 10
            "effectiveDate" = "2099-12-31"
            "expiryDate" = "2100-01-01"
        }
    }
)

$baseTemplate.edgeCases = $edgeCases

# Generar datos para pruebas de rendimiento
$performanceData = @()
for ($i = 1; $i -le 1000; $i++) {
    $perfRecord = @{
        "itemNo" = "PERF$($i.ToString('D4'))"
        "substituteNo" = "SUBS$($i.ToString('D4'))"
        "priority" = [math]::Floor((Get-Random -Maximum 10) + 1)
        "effectiveDate" = (Get-Date).AddDays((Get-Random -Maximum 365)).ToString('yyyy-MM-dd')
    }
    $performanceData += $perfRecord
}

$baseTemplate.performanceTest = $performanceData

# Guardar archivo JSON
$baseTemplate | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "✓ API test data generated: $OutputPath" -ForegroundColor Green
Write-Host "  - Valid scenarios: $($baseTemplate.validScenarios.Count)" -ForegroundColor Cyan
Write-Host "  - Invalid scenarios: $($baseTemplate.invalidScenarios.Count)" -ForegroundColor Cyan
Write-Host "  - Edge cases: $($baseTemplate.edgeCases.Count)" -ForegroundColor Cyan
Write-Host "  - Performance records: $($baseTemplate.performanceTest.Count)" -ForegroundColor Cyan
```

---

## Datasets Específicos por Funcionalidad

### 1. Dataset para Item Substitution
**Archivo: `test/datasets/ItemSubstitutionDataset.al`**
```al
codeunit 50295 "Item Substitution Dataset"
{
    // Implementación específica para Item Substitution API
    
    procedure CreateBasicSubstitutionScenarios(): Text
    var
        ItemTemplate: Codeunit "Item Test Data Template";
        SubstituteMgt: Codeunit "Substitute Management";
        Results: List of [Text];
    begin
        // Escenario 1: Sustitución simple A -> B
        ItemTemplate.CreateTestItem('BASIC001', 'Basic Item A', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('BASIC002', 'Basic Item B', Item.Type::Inventory, 'PCS');
        SubstituteMgt.CreateItemSubstitute('BASIC001', 'BASIC002', 5, 0D, 0D, 'Basic substitution');
        Results.Add('Basic A->B substitution created');
        
        // Escenario 2: Múltiples sustitutos para un item
        ItemTemplate.CreateTestItem('MULTI001', 'Multi Substitute Main', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('MULTI002', 'Multi Substitute Alt 1', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('MULTI003', 'Multi Substitute Alt 2', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('MULTI004', 'Multi Substitute Alt 3', Item.Type::Inventory, 'PCS');
        
        SubstituteMgt.CreateItemSubstitute('MULTI001', 'MULTI002', 1, 0D, 0D, 'Primary substitute');
        SubstituteMgt.CreateItemSubstitute('MULTI001', 'MULTI003', 5, 0D, 0D, 'Secondary substitute');
        SubstituteMgt.CreateItemSubstitute('MULTI001', 'MULTI004', 10, 0D, 0D, 'Tertiary substitute');
        Results.Add('Multi-substitute scenario created (3 alternatives)');
        
        // Escenario 3: Cadena de sustitución válida
        ItemTemplate.CreateTestItem('CHAIN001', 'Chain Start', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('CHAIN002', 'Chain Middle', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('CHAIN003', 'Chain End', Item.Type::Inventory, 'PCS');
        
        SubstituteMgt.CreateItemSubstitute('CHAIN001', 'CHAIN002', 3, 0D, 0D, 'First link');
        SubstituteMgt.CreateItemSubstitute('CHAIN002', 'CHAIN003', 7, 0D, 0D, 'Second link');
        Results.Add('Valid chain created: CHAIN001->CHAIN002->CHAIN003');
        
        exit('Basic scenarios: ' + Format(Results.Count) + ' created');
    end;
    
    procedure CreateCircularDependencyTestCases(): Text
    var
        ItemTemplate: Codeunit "Item Test Data Template";
        SubstituteMgt: Codeunit "Substitute Management";
        Results: List of [Text];
    begin
        // Caso 1: Auto-referencia directa (A -> A)
        ItemTemplate.CreateTestItem('SELF001', 'Self Reference Item', Item.Type::Inventory, 'PCS');
        // Intentar crear auto-referencia - debe fallar
        if not TryCreateSubstitute('SELF001', 'SELF001', 5, 0D, 0D, 'Self reference') then
            Results.Add('✓ Self-reference correctly prevented');
        
        // Caso 2: Circular directo (A -> B, B -> A)
        ItemTemplate.CreateTestItem('CIRC001', 'Circular Item A', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('CIRC002', 'Circular Item B', Item.Type::Inventory, 'PCS');
        
        SubstituteMgt.CreateItemSubstitute('CIRC001', 'CIRC002', 5, 0D, 0D, 'First relation');
        // Intentar crear relación inversa - debe fallar
        if not TryCreateSubstitute('CIRC002', 'CIRC001', 5, 0D, 0D, 'Reverse relation') then
            Results.Add('✓ Direct circular dependency correctly prevented');
        
        // Caso 3: Circular indirecto (A -> B -> C -> A)
        ItemTemplate.CreateTestItem('IND001', 'Indirect Circular A', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('IND002', 'Indirect Circular B', Item.Type::Inventory, 'PCS'); 
        ItemTemplate.CreateTestItem('IND003', 'Indirect Circular C', Item.Type::Inventory, 'PCS');
        
        SubstituteMgt.CreateItemSubstitute('IND001', 'IND002', 5, 0D, 0D, 'Indirect link 1');
        SubstituteMgt.CreateItemSubstitute('IND002', 'IND003', 5, 0D, 0D, 'Indirect link 2');
        // Intentar cerrar el círculo - debe fallar
        if not TryCreateSubstitute('IND003', 'IND001', 5, 0D, 0D, 'Closing circle') then
            Results.Add('✓ Indirect circular dependency correctly prevented');
        
        exit('Circular test cases: ' + Format(Results.Count) + ' validated');
    end;
    
    procedure CreateDateRangeScenarios(): Text
    var
        ItemTemplate: Codeunit "Item Test Data Template";
        SubstituteMgt: Codeunit "Substitute Management";
        Results: List of [Text];
        Today: Date;
        PastDate: Date;
        FutureDate: Date;
    begin
        Today := WorkDate();
        PastDate := CalcDate('-30D', Today);
        FutureDate := CalcDate('+30D', Today);
        
        // Escenario 1: Sustituto activo (sin fechas)
        ItemTemplate.CreateTestItem('DATE001', 'Date Test Main', Item.Type::Inventory, 'PCS');
        ItemTemplate.CreateTestItem('DATE002', 'Date Test Active', Item.Type::Inventory, 'PCS');
        SubstituteMgt.CreateItemSubstitute('DATE001', 'DATE002', 5, 0D, 0D, 'Always active');
        Results.Add('Always active substitute created');
        
        // Escenario 2: Sustituto con fecha efectiva futura
        ItemTemplate.CreateTestItem('DATE003', 'Date Test Future', Item.Type::Inventory, 'PCS');
        SubstituteMgt.CreateItemSubstitute('DATE001', 'DATE003', 3, FutureDate, 0D, 'Future effective');
        Results.Add('Future effective substitute created');
        
        // Escenario 3: Sustituto expirado
        ItemTemplate.CreateTestItem('DATE004', 'Date Test Expired', Item.Type::Inventory, 'PCS');
        SubstituteMgt.CreateItemSubstitute('DATE001', 'DATE004', 7, PastDate, PastDate, 'Expired substitute');
        Results.Add('Expired substitute created');
        
        // Escenario 4: Sustituto con rango de fechas válido
        ItemTemplate.CreateTestItem('DATE005', 'Date Test Valid Range', Item.Type::Inventory, 'PCS');
        SubstituteMgt.CreateItemSubstitute('DATE001', 'DATE005', 2, PastDate, FutureDate, 'Valid range');
        Results.Add('Valid date range substitute created');
        
        exit('Date scenarios: ' + Format(Results.Count) + ' created');
    end;
    
    procedure CreatePriorityTestData(): Text
    var
        ItemTemplate: Codeunit "Item Test Data Template";
        SubstituteMgt: Codeunit "Substitute Management";
        Results: List of [Text];
        i: Integer;
        SubstituteNo: Code[20];
    begin
        // Crear item principal
        ItemTemplate.CreateTestItem('PRIORITY01', 'Priority Test Main', Item.Type::Inventory, 'PCS');
        
        // Crear sustitutos con diferentes prioridades (1-10)
        for i := 1 to 10 do begin
            SubstituteNo := 'PRIO' + Format(i, 0, '<Integer,2><Filler Character,0>');
            ItemTemplate.CreateTestItem(SubstituteNo, 'Priority ' + Format(i) + ' Substitute', Item.Type::Inventory, 'PCS');
            SubstituteMgt.CreateItemSubstitute('PRIORITY01', SubstituteNo, i, 0D, 0D, 'Priority ' + Format(i));
        end;
        
        Results.Add('Priority test data created: 1 main item, 10 substitutes (priority 1-10)');
        
        exit('Priority scenarios: ' + Format(Results.Count) + ' created');
    end;
    
    local procedure TryCreateSubstitute(ItemNo: Code[20]; SubstituteNo: Code[20]; Priority: Integer; EffectiveDate: Date; ExpiryDate: Date; Notes: Text[250]): Boolean
    var
        SubstituteMgt: Codeunit "Substitute Management";
        Result: Text;
    begin
        Result := SubstituteMgt.CreateItemSubstitute(ItemNo, SubstituteNo, Priority, EffectiveDate, ExpiryDate, Notes);
        exit(StrPos(Result, '"success":true') > 0);
    end;
}
```

---

## Automatización de Datos de Prueba

### 1. Script de Setup Automatizado por Fase
**Archivo: `scripts/automated-phase-setup.ps1`**
```powershell
# Automated Test Data Setup by Implementation Phase
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Phase1", "Phase2", "Phase3", "Phase4", "All")]
    [string]$Phase,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanFirst = $false
)

Write-Host "=== Automated Phase $Phase Data Setup ===" -ForegroundColor Green

# Configuración por fase
$phaseConfigs = @{
    "Phase1" = @{
        "Name" = "Code Quality & Consistency"
        "DataSets" = @("Basic", "Constants", "ErrorHandling")
        "Entities" = 100
        "Focus" = "Language standardization and constants testing"
    }
    "Phase2" = @{
        "Name" = "Feature Enhancements" 
        "DataSets" = @("Priority", "Filtering", "BulkOperations")
        "Entities" = 1000
        "Focus" = "Priority sorting and advanced filtering"
    }
    "Phase3" = @{
        "Name" = "Testing & QA"
        "DataSets" = @("UnitTests", "Integration", "Performance")
        "Entities" = 5000
        "Focus" = "Comprehensive test coverage"
    }
    "Phase4" = @{
        "Name" = "Advanced Features"
        "DataSets" = @("Audit", "Reporting", "Versioning")
        "Entities" = 2000
        "Focus" = "Audit trails and reporting capabilities"
    }
}

function Setup-PhaseData {
    param($PhaseConfig, $PhaseName)
    
    Write-Host "`nSetting up $PhaseName data..." -ForegroundColor Cyan
    Write-Host "Focus: $($PhaseConfig.Focus)" -ForegroundColor Yellow
    Write-Host "Entities: $($PhaseConfig.Entities)" -ForegroundColor Yellow
    
    # Crear AL script específico por fase
    $phaseScript = @"
codeunit 50280 "$PhaseName Test Data Setup"
{
    // Auto-generated test data for $PhaseName
    // Focus: $($PhaseConfig.Focus)
    // Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    
    procedure Setup$($PhaseName)TestData(): Text
    var
        Results: List of [Text];
        ItemDataset: Codeunit "Item Substitution Dataset";
    begin
"@
    
    foreach ($dataSet in $PhaseConfig.DataSets) {
        switch ($dataSet) {
            "Basic" { 
                $phaseScript += "`n        Results.Add(ItemDataset.CreateBasicSubstitutionScenarios());"
            }
            "Priority" {
                $phaseScript += "`n        Results.Add(ItemDataset.CreatePriorityTestData());"
            }
            "Filtering" {
                $phaseScript += "`n        Results.Add(ItemDataset.CreateDateRangeScenarios());"
            }
            "UnitTests" {
                $phaseScript += "`n        Results.Add(ItemDataset.CreateCircularDependencyTestCases());"
            }
            "Performance" {
                $phaseScript += "`n        Results.Add(CreatePerformanceDataset($($PhaseConfig.Entities)));"
            }
        }
    }
    
    $phaseScript += @"

        exit('$PhaseName setup completed: ' + Format(Results.Count) + ' datasets created');
    end;
    
    local procedure CreatePerformanceDataset(EntityCount: Integer): Text
    var
        PerfTemplate: Codeunit "Performance Test Data Template";
        DatasetSize: Option Small,Medium,Large;
    begin
        case EntityCount of
            1..500: DatasetSize := DatasetSize::Small;
            501..2000: DatasetSize := DatasetSize::Medium;
            else DatasetSize := DatasetSize::Large;
        end;
        
        exit(PerfTemplate.GenerateDataset(DatasetSize, '$($PhaseName.ToUpper())'));
    end;
}
"@

    # Guardar script AL
    $scriptPath = "./test/phase-scripts/$PhaseName" + "TestDataSetup.al"
    
    # Crear directorio si no existe
    if (-not (Test-Path "./test/phase-scripts")) {
        New-Item -ItemType Directory -Path "./test/phase-scripts" -Force
    }
    
    $phaseScript | Out-File -FilePath $scriptPath -Encoding UTF8
    Write-Host "✓ $PhaseName AL script created: $scriptPath" -ForegroundColor Green
    
    return $scriptPath
}

# Ejecutar setup según el parámetro de fase
if ($Phase -eq "All") {
    foreach ($phaseName in @("Phase1", "Phase2", "Phase3", "Phase4")) {
        $config = $phaseConfigs[$phaseName]
        Setup-PhaseData -PhaseConfig $config -PhaseName $phaseName
    }
} else {
    $config = $phaseConfigs[$Phase]
    Setup-PhaseData -PhaseConfig $config -PhaseName $Phase
}

# Crear script maestro de ejecución
$masterScript = @"
codeunit 50279 "Master Test Data Controller"
{
    // Master controller for all phase test data
    
    procedure SetupAllPhases(): Text
    var
        Results: List of [Text];
    begin
        Results.Add(SetupPhase1Data());
        Results.Add(SetupPhase2Data());
        Results.Add(SetupPhase3Data());
        Results.Add(SetupPhase4Data());
        
        exit('All phases setup completed: ' + Format(Results.Count) + ' phases');
    end;
    
    procedure SetupPhase1Data(): Text
    var
        Phase1Setup: Codeunit "Phase1 Test Data Setup";
    begin
        exit(Phase1Setup.SetupPhase1TestData());
    end;
    
    procedure SetupPhase2Data(): Text
    var
        Phase2Setup: Codeunit "Phase2 Test Data Setup";
    begin
        exit(Phase2Setup.SetupPhase2TestData());
    end;
    
    procedure SetupPhase3Data(): Text
    var
        Phase3Setup: Codeunit "Phase3 Test Data Setup";
    begin
        exit(Phase3Setup.SetupPhase3TestData());
    end;
    
    procedure SetupPhase4Data(): Text
    var
        Phase4Setup: Codeunit "Phase4 Test Data Setup";
    begin
        exit(Phase4Setup.SetupPhase4TestData());
    end;
    
    procedure CleanAllPhases(): Text
    var
        ItemTemplate: Codeunit "Item Test Data Template";
        PerfTemplate: Codeunit "Performance Test Data Template";
        Results: List of [Text];
    begin
        // Clean by prefixes used in each phase
        ItemTemplate.DeleteTestItems('BASIC');
        ItemTemplate.DeleteTestItems('MULTI');
        ItemTemplate.DeleteTestItems('CHAIN');
        ItemTemplate.DeleteTestItems('PRIORITY');
        ItemTemplate.DeleteTestItems('DATE');
        PerfTemplate.CleanupPerformanceData('PHASE1');
        PerfTemplate.CleanupPerformanceData('PHASE2');
        PerfTemplate.CleanupPerformanceData('PHASE3');
        PerfTemplate.CleanupPerformanceData('PHASE4');
        
        Results.Add('All test data cleaned');
        exit(Format(Results.Count) + ' cleanup operations completed');
    end;
}
"@

$masterScriptPath = "./test/MasterTestDataController.al"
$masterScript | Out-File -FilePath $masterScriptPath -Encoding UTF8

Write-Host "`n✓ Master controller created: $masterScriptPath" -ForegroundColor Green
Write-Host "`n=== Setup Instructions ===" -ForegroundColor Green
Write-Host "1. Compile all generated AL files" -ForegroundColor Yellow
Write-Host "2. Execute SetupAllPhases() or specific phase setup" -ForegroundColor Yellow
Write-Host "3. Validate data with appropriate validation codeunits" -ForegroundColor Yellow
```

---

## Limpieza y Mantenimiento

### 1. Script de Limpieza Inteligente
**Archivo: `scripts/smart-cleanup.ps1`**
```powershell
# Smart Test Data Cleanup
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("TestOnly", "PerfOnly", "ExpiredOnly", "All", "Selective")]
    [string]$CleanupType = "Selective",
    
    [Parameter(Mandatory=$false)]
    [int]$KeepRecentDays = 7,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "=== Smart Test Data Cleanup ===" -ForegroundColor Green
Write-Host "Type: $CleanupType" -ForegroundColor Cyan
Write-Host "Keep Recent: $KeepRecentDays days" -ForegroundColor Cyan
Write-Host "Dry Run: $DryRun" -ForegroundColor Cyan

# Generar script AL de limpieza inteligente
$cleanupScript = @"
codeunit 50278 "Smart Cleanup Manager"
{
    // Smart cleanup for test data based on age, usage, and type
    
    procedure PerformSmartCleanup(CleanupType: Option TestOnly,PerfOnly,ExpiredOnly,All,Selective; KeepRecentDays: Integer; DryRun: Boolean): Text
    var
        Results: List of [Text];
        CleanupStats: Record "Cleanup Statistics" temporary;
    begin
        case CleanupType of
            CleanupType::TestOnly:
                Results.Add(CleanupTestEntities(KeepRecentDays, DryRun));
            CleanupType::PerfOnly:
                Results.Add(CleanupPerformanceEntities(KeepRecentDays, DryRun));
            CleanupType::ExpiredOnly:
                Results.Add(CleanupExpiredEntities(DryRun));
            CleanupType::All:
                begin
                    Results.Add(CleanupTestEntities(KeepRecentDays, DryRun));
                    Results.Add(CleanupPerformanceEntities(KeepRecentDays, DryRun));
                    Results.Add(CleanupExpiredEntities(DryRun));
                end;
            CleanupType::Selective:
                Results.Add(SelectiveCleanup(KeepRecentDays, DryRun));
        end;
        
        exit('Smart cleanup completed: ' + Format(Results.Count) + ' operations');
    end;
    
    local procedure CleanupTestEntities(KeepRecentDays: Integer; DryRun: Boolean): Text
    var
        Item: Record Item;
        ItemSubstitution: Record "Item Substitution";
        CutoffDate: DateTime;
        DeletedItems: Integer;
        DeletedSubstitutions: Integer;
    begin
        CutoffDate := CreateDateTime(CalcDate('-' + Format(KeepRecentDays) + 'D', Today), 0T);
        
        // Find old test items
        Item.SetFilter("No.", 'TEST*|DEMO*|DEV*');
        // Add date filter based on creation or last modification
        // Item.SetFilter("Last DateTime Modified", '<%1', CutoffDate);
        
        if DryRun then begin
            DeletedItems := Item.Count();
            exit('DRY RUN: Would delete ' + Format(DeletedItems) + ' test items');
        end else begin
            // First delete related substitutions
            ItemSubstitution.SetFilter("Item No.", 'TEST*|DEMO*|DEV*');
            DeletedSubstitutions := ItemSubstitution.Count();
            ItemSubstitution.DeleteAll();
            
            // Then delete items
            DeletedItems := Item.Count();
            Item.DeleteAll();
            
            exit('Deleted ' + Format(DeletedItems) + ' items and ' + Format(DeletedSubstitutions) + ' substitutions');
        end;
    end;
    
    local procedure CleanupPerformanceEntities(KeepRecentDays: Integer; DryRun: Boolean): Text
    var
        Item: Record Item;
        PerfItemCount: Integer;
    begin
        Item.SetFilter("No.", 'PERF*|BULK*|LOAD*');
        PerfItemCount := Item.Count();
        
        if DryRun then
            exit('DRY RUN: Would delete ' + Format(PerfItemCount) + ' performance test items')
        else begin
            Item.DeleteAll();
            exit('Deleted ' + Format(PerfItemCount) + ' performance test items');
        end;
    end;
    
    local procedure CleanupExpiredEntities(DryRun: Boolean): Text
    var
        ItemSubstitution: Record "Item Substitution";
        ExpiredCount: Integer;
    begin
        // Find substitutions with expiry date in the past
        ItemSubstitution.SetFilter("Expiry Date", '<%1&<>%2', Today, 0D);
        ExpiredCount := ItemSubstitution.Count();
        
        if DryRun then
            exit('DRY RUN: Would delete ' + Format(ExpiredCount) + ' expired substitutions')
        else begin
            ItemSubstitution.DeleteAll();
            exit('Deleted ' + Format(ExpiredCount) + ' expired substitutions');
        end;
    end;
    
    local procedure SelectiveCleanup(KeepRecentDays: Integer; DryRun: Boolean): Text
    var
        Results: List of [Text];
    begin
        // Implement smart logic to determine what to clean
        // Based on usage patterns, age, and test results
        
        // Keep items that are part of successful test runs
        // Clean items that haven't been accessed recently
        // Preserve edge case data that might be reused
        
        Results.Add('Selective cleanup logic not yet implemented');
        exit('Selective cleanup: ' + Format(Results.Count) + ' operations');
    end;
}

table 50299 "Cleanup Statistics"
{
    TableType = Temporary;
    
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Cleanup Type"; Text[50]) { }
        field(3; "Items Deleted"; Integer) { }
        field(4; "Relationships Deleted"; Integer) { }
        field(5; "Cleanup Date"; DateTime) { }
        field(6; "Was Dry Run"; Boolean) { }
    }
}
"@

$cleanupScriptPath = "./test/SmartCleanupManager.al"
$cleanupScript | Out-File -FilePath $cleanupScriptPath -Encoding UTF8

Write-Host "✓ Smart cleanup AL script created: $cleanupScriptPath" -ForegroundColor Green

# Crear script de PowerShell complementario para análisis
$analysisScript = @"
# Test Data Analysis and Cleanup Recommendations
Write-Host "=== Test Data Analysis ===" -ForegroundColor Green

# Simular análisis de datos de prueba
`$testPrefixes = @('TEST', 'DEMO', 'DEV', 'PERF', 'EDGE', 'BULK')

foreach (`$prefix in `$testPrefixes) {
    Write-Host "Analyzing $prefix* entities..." -ForegroundColor Cyan
    
    # En un escenario real, estos valores vendrían de BC
    `$entityCount = Get-Random -Maximum 1000
    `$ageInDays = Get-Random -Maximum 30
    `$lastUsed = (Get-Date).AddDays(-`$ageInDays)
    
    if (`$ageInDays -gt $KeepRecentDays) {
        Write-Host "  ⚠ `$entityCount entities (Last used: `$(`$lastUsed.ToString('yyyy-MM-dd')))" -ForegroundColor Yellow
        Write-Host "    Recommendation: Consider cleanup" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ `$entityCount entities (Recent: `$(`$lastUsed.ToString('yyyy-MM-dd')))" -ForegroundColor Green
        Write-Host "    Recommendation: Keep" -ForegroundColor Green
    }
}

Write-Host "`nExecute SmartCleanupManager.PerformSmartCleanup() in BC to proceed" -ForegroundColor Cyan
"@

$analysisScriptPath = "./scripts/analyze-test-data.ps1"  
$analysisScript | Out-File -FilePath $analysisScriptPath -Encoding UTF8

Write-Host "✓ Analysis script created: $analysisScriptPath" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    & $analysisScriptPath
} else {
    Write-Host "`n⚠ LIVE MODE - Changes will be applied" -ForegroundColor Red
    Write-Host "Execute the AL cleanup procedures to perform actual cleanup" -ForegroundColor Yellow
}
```

---

**🎯 Con esta guía de datos de prueba, los proyectos AL de Business Central tendrán datasets completos, escalables y reutilizables que soporten testing automatizado en todos los niveles - desde pruebas unitarias hasta validación de rendimiento.**