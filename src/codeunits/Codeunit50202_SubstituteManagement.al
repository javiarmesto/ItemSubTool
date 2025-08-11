codeunit 50202 "Substitute Management"
{
    procedure ValidateSubstitute(ItemNo: Code[20]; SubstituteNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            Error('Item %1 no existe.', ItemNo);
        if not Item.Get(SubstituteNo) then
            Error('Sustituto %1 no existe.', SubstituteNo);
        if ItemNo = SubstituteNo then
            Error('No se permite auto-referencia %1.', ItemNo);
        if DetectCircular(ItemNo, SubstituteNo) then
            Error('Se detectó referencia circular entre %1 y %2.', ItemNo, SubstituteNo);
        exit(true);
    end;

    procedure GetSubstituteChain(ItemNo: Code[20]; var TempChain: Record "Item Substitute Chain Buffer" temporary)
    var
        Sub: Record "Item Substitution";
        Seq: Integer;
        TodayDate: Date;
    begin
        Clear(TempChain);
        TodayDate := Today();
        Sub.Reset();
        Sub.SetRange("No.", ItemNo);
        Sub.SetFilter("Effective Date", '%1|..%2', 0D, TodayDate);
        Sub.SetFilter("Expiry Date", '%1|>%2', 0D, TodayDate);
        if Sub.FindSet() then begin
            Seq := 0;
            repeat
                Seq += 1;
                TempChain.Init();
                TempChain."Item No." := Sub."No.";
                TempChain."Substitute Item No." := Sub."Substitute No.";
                TempChain.Priority := Sub.Priority; // field from extension
                TempChain.Sequence := Seq;
                TempChain.Insert();
            until Sub.Next() = 0;
        end;
    end;

    procedure GetSubstituteChainService(ItemNo: Code[20]): Text
    var
        TempChain: Record "Item Substitute Chain Buffer" temporary;
        JsonArr: JsonArray;
        JsonObj: JsonObject;
    begin
        GetSubstituteChain(ItemNo, TempChain);
        if TempChain.FindSet() then
            repeat
                Clear(JsonObj);
                JsonObj.Add('itemNo', TempChain."Item No.");
                JsonObj.Add('substituteItemNo', TempChain."Substitute Item No.");
                JsonObj.Add('priority', TempChain.Priority);
                JsonObj.Add('sequence', TempChain.Sequence);
                JsonArr.Add(JsonObj);
            until TempChain.Next() = 0;
        exit(Format(JsonArr));
    end;

    local procedure DetectCircular(RootItemNo: Code[20]; CandidateSubNo: Code[20]): Boolean
    var
        Sub: Record "Item Substitution";
        Stack: List of [Code[20]];
        Visited: Dictionary of [Code[20], Boolean];
        Current: Code[20];
    begin
        Stack.Add(CandidateSubNo);
        while Stack.Count() > 0 do begin
            Current := Stack.Get(Stack.Count());
            Stack.RemoveAt(Stack.Count());
            if Visited.ContainsKey(Current) then
                continue;
            Visited.Add(Current, true);
            if Current = RootItemNo then
                exit(true);
            Sub.Reset();
            Sub.SetRange("No.", Current);
            Sub.SetFilter("Effective Date", '%1|..%2', 0D, Today());
            Sub.SetFilter("Expiry Date", '%1|>%2', 0D, Today());
            if Sub.FindSet() then
                repeat
                    if not Visited.ContainsKey(Sub."Substitute No.") then
                        Stack.Add(Sub."Substitute No.");
                until Sub.Next() = 0;
        end;
        exit(false);
    end;
}
