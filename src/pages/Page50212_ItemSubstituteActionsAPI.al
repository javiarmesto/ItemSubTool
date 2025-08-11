page 50212 "Item Substitute Actions API"
{
    PageType = API;
    Caption = 'Item Substitute Actions API';
    APIPublisher = 'custom';
    APIGroup = 'itemSubstitution';
    APIVersion = 'v1.0';
    EntityName = 'itemSubstituteAction';
    EntitySetName = 'itemSubstituteActions';
    SourceTable = "Item Substitute Chain Buffer"; // Dummy table for actions
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(dummy; 'Actions') { Caption = 'Actions'; }
            }
        }
    }

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure CreateItemSubstitute(ItemNo: Code[20]; SubstituteNo: Code[20]; Priority: Integer; EffectiveDate: Date; ExpiryDate: Date; Notes: Text[250]): Text
    var
        MCPTool: Codeunit "Item Substitute MCP Tool";
    begin
        exit(MCPTool.CreateItemSubstitute(ItemNo, SubstituteNo, Priority, EffectiveDate, ExpiryDate, Notes));
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure GetItemSubstitutes(ItemNo: Code[20]): Text
    var
        MCPTool: Codeunit "Item Substitute MCP Tool";
    begin
        exit(MCPTool.GetItemSubstitutes(ItemNo));
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure UpdateItemSubstitute(ItemNo: Code[20]; SubstituteNo: Code[20]; NewPriority: Integer; NewNotes: Text[250]): Text
    var
        MCPTool: Codeunit "Item Substitute MCP Tool";
    begin
        exit(MCPTool.UpdateItemSubstitute(ItemNo, SubstituteNo, NewPriority, NewNotes));
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure DeactivateItemSubstitute(ItemNo: Code[20]; SubstituteNo: Code[20]): Text
    var
        MCPTool: Codeunit "Item Substitute MCP Tool";
    begin
        exit(MCPTool.DeactivateItemSubstitute(ItemNo, SubstituteNo));
    end;
}
