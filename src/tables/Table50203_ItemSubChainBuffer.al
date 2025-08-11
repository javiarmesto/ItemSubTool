table 50203 "Item Substitute Chain Buffer"
{
    Caption = 'Item Substitute Chain Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(2; "Substitute Item No."; Code[20])
        {
            Caption = 'Substitute Item No.';
        }
        field(3; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(4; Sequence; Integer)
        {
            Caption = 'Sequence';
        }
    }

    keys
    {
        key(PK; "Item No.", Sequence)
        {
            Clustered = true;
        }
    }
}


