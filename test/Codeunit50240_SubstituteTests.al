codeunit 50240 "Substitute Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mgmt: Codeunit "Substitute Management";
        MCPTool: Codeunit "Item Substitute MCP Tool";

    [Test]
    procedure CircularDetection_SimpleLoop()
    var
        Sub: Record "Item Substitution";
    begin
        InsertSub('ITEMA', 'ITEMB');
        InsertSub('ITEMB', 'ITEMC');
        InsertSub('ITEMC', 'ITEMA');
        asserterror Mgmt.ValidateSubstitute('ITEMA', 'ITEMC');
    end;

    [Test]
    procedure MCPTool_CreateSubstitute_Success()
    var
        JsonResponse: Text;
        JsonObject: JsonObject;
        SuccessToken: JsonToken;
    begin
        // Act
        JsonResponse := MCPTool.CreateItemSubstitute('ITEM001', 'ITEM002', 1, Today(), 0D, 'Test substitute');

        // Assert
        JsonObject.ReadFrom(JsonResponse);
        JsonObject.Get('success', SuccessToken);
        if not SuccessToken.AsValue().AsBoolean() then
            Error('Expected success = true, got: %1', JsonResponse);
    end;

    [Test]
    procedure MCPTool_GetSubstitutes_ReturnsCorrectCount()
    var
        JsonResponse: Text;
        JsonObject: JsonObject;
        CountToken: JsonToken;
    begin
        // Arrange
        InsertSub('ITEM100', 'ITEM101');
        InsertSub('ITEM100', 'ITEM102');

        // Act
        JsonResponse := MCPTool.GetItemSubstitutes('ITEM100');

        // Assert
        JsonObject.ReadFrom(JsonResponse);
        JsonObject.Get('count', CountToken);
        if CountToken.AsValue().AsInteger() <> 2 then
            Error('Expected 2 substitutes, got: %1', CountToken.AsValue().AsInteger());
    end;

    local procedure InsertSub(ItemNo: Code[20]; SubNo: Code[20])
    var
        Sub: Record "Item Substitution";
    begin
        Clear(Sub);
        Sub.Init();
        Sub."No." := ItemNo;
        Sub."Substitute No." := SubNo;
        Sub.Priority := 5;
        Sub."Effective Date" := Today() - 1;
        Sub.Insert(true);
    end;
}
