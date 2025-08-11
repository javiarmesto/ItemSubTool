pageextension 50220 ItemSubstitutionListExt extends "Item Substitution Entry" // Page 5716
{
    layout
    {
        addafter(Description)
        {
            field(Priority; Rec.Priority)
            {
                ApplicationArea = All;
            }
            field(EffectiveDate; Rec."Effective Date")
            {
                ApplicationArea = All;
            }
            field(ExpiryDate; Rec."Expiry Date")
            {
                ApplicationArea = All;
            }
            field(Notes; Rec.Notes)
            {
                ApplicationArea = All;
            }
            field(CreatedBy; Rec."Created By")
            {
                ApplicationArea = All;
            }
            field(CreationDateTime; Rec."Creation DateTime")
            {
                ApplicationArea = All;
            }
        }
    }
}
