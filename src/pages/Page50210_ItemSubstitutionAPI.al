page 50210 "Item Substitution API"
{
    PageType = API;
    Caption = 'Item Substitution API';
    APIPublisher = 'custom';
    APIGroup = 'itemSubstitution';
    APIVersion = 'v1.0';
    EntityName = 'itemSubstitution';
    EntitySetName = 'itemSubstitutions';
    SourceTable = "Item Substitution";
    DelayedInsert = true;
    ODataKeyFields = "No.", "Substitute No.";
    // SourceTableView = sorting("No.", Priority) order(ascending); // Activar cuando key esté disponible

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(itemNo; Rec."No.") { Caption = 'Item No.'; }
                field(substituteNo; Rec."Substitute No.") { Caption = 'Substitute No.'; }
                field(priority; Rec.Priority) { Caption = 'Priority'; }
                field(effectiveDate; Rec."Effective Date") { Caption = 'Effective Date'; }
                field(expiryDate; Rec."Expiry Date") { Caption = 'Expiry Date'; }
                field(notes; Rec.Notes) { Caption = 'Notes'; }
                field(createdBy; Rec."Created By") { Caption = 'Created By'; Editable = false; }
                field(creationDateTime; Rec."Creation DateTime") { Caption = 'Creation DateTime'; Editable = false; }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Mgmt: Codeunit "Substitute Management";
    begin
        Mgmt.ValidateSubstitute(Rec."No.", Rec."Substitute No.");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        ErrLbl: Label 'Solo se permite actualizar Priority o Notes mediante PATCH.';
    begin
        if (Rec."No." <> xRec."No.") or
           (Rec."Substitute No." <> xRec."Substitute No.") or
           (Rec."Effective Date" <> xRec."Effective Date") or
           (Rec."Expiry Date" <> xRec."Expiry Date") or
           (Rec."Created By" <> xRec."Created By") or
           (Rec."Creation DateTime" <> xRec."Creation DateTime") then
            Error(ErrLbl);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec."Expiry Date" = 0D then begin
            Rec."Expiry Date" := Today();
            Rec.Modify(true);
        end;
        exit(false);
    end;
}
