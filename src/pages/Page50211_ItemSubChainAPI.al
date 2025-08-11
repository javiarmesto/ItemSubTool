page 50211 "Item Sub Chain API"
{
    PageType = API;
    Caption = 'Item Substitute Chain API';
    APIPublisher = 'custom';
    APIGroup = 'itemSubstitution';
    APIVersion = 'v1.0';
    EntityName = 'itemSubstituteChain';
    EntitySetName = 'itemSubstituteChains';
    SourceTable = "Item Substitute Chain Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;
    ODataKeyFields = "Item No.", Sequence;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(itemNo; Rec."Item No.") { Caption = 'Item No.'; }
                field(substituteItemNo; Rec."Substitute Item No.") { Caption = 'Substitute Item No.'; }
                field(priority; Rec.Priority) { Caption = 'Priority'; }
                field(sequence; Rec.Sequence) { Caption = 'Sequence'; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Mgmt: Codeunit "Substitute Management";
        ItemFilter: Text;
    begin
        ItemFilter := Rec.GetFilter("Item No.");
        if ItemFilter = '' then
            exit;
        Mgmt.GetSubstituteChain(ItemFilter, Rec);
    end;
}
