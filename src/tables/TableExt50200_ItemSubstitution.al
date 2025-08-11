tableextension 50200 ItemSubstitutionExt extends "Item Substitution"
{
    fields
    {
        field(50200; Priority; Integer)
        {
            Caption = 'Priority';
            MinValue = 1;
            MaxValue = 10;
            DataClassification = CustomerContent;
        }
        field(50201; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
            DataClassification = CustomerContent;
        }
        field(50202; "Expiry Date"; Date)
        {
            Caption = 'Expiry Date';
            DataClassification = CustomerContent;
        }
        field(50203; Notes; Text[250])
        {
            Caption = 'Notes';
            DataClassification = CustomerContent;
        }
        field(50204; "Created By"; Code[50])
        {
            Caption = 'Created By';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(50205; "Creation DateTime"; DateTime)
        {
            Caption = 'Creation DateTime';
            Editable = false;
            DataClassification = SystemMetadata;
        }
    }

    trigger OnBeforeInsert()
    begin
        if Rec."Created By" = '' then
            Rec."Created By" := CopyStr(Format(UserSecurityId()), 1, MaxStrLen(Rec."Created By"));
        if Rec."Creation DateTime" = 0DT then
            Rec."Creation DateTime" := CurrentDateTime();
    end;

    // NOTE: Para ordenar por Priority en la página API se puede definir una key extendida:
    // keys { addlast(PriorityKey; "Item No.", Priority) { } }
    // Comentado temporalmente si el runtime/símbolos generan error; descomentar tras descargar símbolos base.
}

