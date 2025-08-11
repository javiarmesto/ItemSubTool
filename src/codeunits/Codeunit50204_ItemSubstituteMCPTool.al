codeunit 50204 "Item Substitute MCP Tool"
{
    /// <summary>
    /// MCP Tool: Create a substitute relationship between two items
    /// </summary>
    /// <param name="ItemNo">Primary item number</param>
    /// <param name="SubstituteNo">Substitute item number</param>
    /// <param name="Priority">Priority level (1-10, lower is better)</param>
    /// <param name="EffectiveDate">When substitution becomes effective (optional)</param>
    /// <param name="ExpiryDate">When substitution expires (optional)</param>
    /// <param name="Notes">Additional notes (optional)</param>
    /// <returns>JSON response with success status and created record</returns>
    procedure CreateItemSubstitute(ItemNo: Code[20]; SubstituteNo: Code[20]; Priority: Integer; EffectiveDate: Date; ExpiryDate: Date; Notes: Text[250]): Text
    var
        Sub: Record "Item Substitution";
        Mgmt: Codeunit "Substitute Management";
        JsonResponse: JsonObject;
        JsonData: JsonObject;
        ResponseText: Text;
    begin
        Clear(JsonResponse);
        Clear(JsonData);

        // Validate inputs
        if ItemNo = '' then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'ItemNo is required');
            exit(Format(JsonResponse));
        end;

        if SubstituteNo = '' then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'SubstituteNo is required');
            exit(Format(JsonResponse));
        end;

        if (Priority < 1) or (Priority > 10) then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'Priority must be between 1 and 10');
            exit(Format(JsonResponse));
        end;

        // Set default effective date if not provided
        if EffectiveDate = 0D then
            EffectiveDate := Today();

        // Validate business rules
        if not Mgmt.ValidateSubstitute(ItemNo, SubstituteNo) then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', GetLastErrorText());
            exit(Format(JsonResponse));
        end;

        // Check if substitute already exists
        Sub.Reset();
        Sub.SetRange("No.", ItemNo);
        Sub.SetRange("Substitute No.", SubstituteNo);
        if Sub.FindFirst() then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'Substitute relationship already exists');
            exit(Format(JsonResponse));
        end;

        // Create new substitute record
        Clear(Sub);
        Sub.Init();
        Sub."No." := ItemNo;
        Sub."Substitute No." := SubstituteNo;
        Sub.Priority := Priority;
        Sub."Effective Date" := EffectiveDate;
        if ExpiryDate <> 0D then
            Sub."Expiry Date" := ExpiryDate;
        if Notes <> '' then
            Sub.Notes := Notes;
        Sub.Insert(true);

        // Build success response
        JsonResponse.Add('success', true);
        JsonResponse.Add('message', 'Item substitute created successfully');

        JsonData.Add('itemNo', Sub."No.");
        JsonData.Add('substituteNo', Sub."Substitute No.");
        JsonData.Add('priority', Sub.Priority);
        JsonData.Add('effectiveDate', Format(Sub."Effective Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        if Sub."Expiry Date" <> 0D then
            JsonData.Add('expiryDate', Format(Sub."Expiry Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        JsonData.Add('notes', Sub.Notes);
        JsonData.Add('createdBy', Sub."Created By");
        JsonData.Add('creationDateTime', Format(Sub."Creation DateTime", 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));

        JsonResponse.Add('data', JsonData);
        exit(Format(JsonResponse));
    end;

    /// <summary>
    /// MCP Tool: Get substitute chain for an item
    /// </summary>
    /// <param name="ItemNo">Item number to get substitutes for</param>
    /// <returns>JSON array of substitute items ordered by priority</returns>
    procedure GetItemSubstitutes(ItemNo: Code[20]): Text
    var
        Sub: Record "Item Substitution";
        JsonResponse: JsonObject;
        JsonArray: JsonArray;
        JsonItem: JsonObject;
        TodayDate: Date;
    begin
        Clear(JsonResponse);
        Clear(JsonArray);

        if ItemNo = '' then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'ItemNo is required');
            exit(Format(JsonResponse));
        end;

        TodayDate := Today();
        Sub.Reset();
        Sub.SetRange("No.", ItemNo);
        Sub.SetFilter("Effective Date", '%1|..%2', 0D, TodayDate);
        Sub.SetFilter("Expiry Date", '%1|>%2', 0D, TodayDate);
        Sub.SetCurrentKey("No.", Priority);
        Sub.SetAscending(Priority, true);

        if Sub.FindSet() then
            repeat
                Clear(JsonItem);
                JsonItem.Add('itemNo', Sub."No.");
                JsonItem.Add('substituteNo', Sub."Substitute No.");
                JsonItem.Add('priority', Sub.Priority);
                JsonItem.Add('effectiveDate', Format(Sub."Effective Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                if Sub."Expiry Date" <> 0D then
                    JsonItem.Add('expiryDate', Format(Sub."Expiry Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                JsonItem.Add('notes', Sub.Notes);
                JsonArray.Add(JsonItem);
            until Sub.Next() = 0;

        JsonResponse.Add('success', true);
        JsonResponse.Add('itemNo', ItemNo);
        JsonResponse.Add('substitutes', JsonArray);
        JsonResponse.Add('count', JsonArray.Count());

        exit(Format(JsonResponse));
    end;

    /// <summary>
    /// MCP Tool: Update substitute priority or notes
    /// </summary>
    /// <param name="ItemNo">Primary item number</param>
    /// <param name="SubstituteNo">Substitute item number</param>
    /// <param name="NewPriority">New priority (optional, 0 = no change)</param>
    /// <param name="NewNotes">New notes (optional, empty = no change)</param>
    /// <returns>JSON response with success status</returns>
    procedure UpdateItemSubstitute(ItemNo: Code[20]; SubstituteNo: Code[20]; NewPriority: Integer; NewNotes: Text[250]): Text
    var
        Sub: Record "Item Substitution";
        JsonResponse: JsonObject;
        JsonData: JsonObject;
        Changed: Boolean;
    begin
        Clear(JsonResponse);

        if (ItemNo = '') or (SubstituteNo = '') then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'ItemNo and SubstituteNo are required');
            exit(Format(JsonResponse));
        end;

        if (NewPriority <> 0) and ((NewPriority < 1) or (NewPriority > 10)) then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'Priority must be between 1 and 10');
            exit(Format(JsonResponse));
        end;

        Sub.Reset();
        Sub.SetRange("No.", ItemNo);
        Sub.SetRange("Substitute No.", SubstituteNo);
        if not Sub.FindFirst() then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'Substitute relationship not found');
            exit(Format(JsonResponse));
        end;

        Changed := false;
        if (NewPriority <> 0) and (Sub.Priority <> NewPriority) then begin
            Sub.Priority := NewPriority;
            Changed := true;
        end;

        if (NewNotes <> '') and (Sub.Notes <> NewNotes) then begin
            Sub.Notes := NewNotes;
            Changed := true;
        end;

        if Changed then
            Sub.Modify(true);

        JsonResponse.Add('success', true);
        JsonResponse.Add('message', 'Item substitute updated successfully');

        Clear(JsonData);
        JsonData.Add('itemNo', Sub."No.");
        JsonData.Add('substituteNo', Sub."Substitute No.");
        JsonData.Add('priority', Sub.Priority);
        JsonData.Add('notes', Sub.Notes);
        JsonData.Add('changed', Changed);
        JsonResponse.Add('data', JsonData);

        exit(Format(JsonResponse));
    end;

    /// <summary>
    /// MCP Tool: Deactivate substitute (soft delete by setting expiry date)
    /// </summary>
    /// <param name="ItemNo">Primary item number</param>
    /// <param name="SubstituteNo">Substitute item number</param>
    /// <returns>JSON response with success status</returns>
    procedure DeactivateItemSubstitute(ItemNo: Code[20]; SubstituteNo: Code[20]): Text
    var
        Sub: Record "Item Substitution";
        JsonResponse: JsonObject;
    begin
        Clear(JsonResponse);

        if (ItemNo = '') or (SubstituteNo = '') then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'ItemNo and SubstituteNo are required');
            exit(Format(JsonResponse));
        end;

        Sub.Reset();
        Sub.SetRange("No.", ItemNo);
        Sub.SetRange("Substitute No.", SubstituteNo);
        if not Sub.FindFirst() then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'Substitute relationship not found');
            exit(Format(JsonResponse));
        end;

        if Sub."Expiry Date" <> 0D then begin
            JsonResponse.Add('success', false);
            JsonResponse.Add('error', 'Substitute is already deactivated');
            exit(Format(JsonResponse));
        end;

        Sub."Expiry Date" := Today();
        Sub.Modify(true);

        JsonResponse.Add('success', true);
        JsonResponse.Add('message', 'Item substitute deactivated successfully');
        JsonResponse.Add('expiryDate', Format(Sub."Expiry Date", 0, '<Year4>-<Month,2>-<Day,2>'));

        exit(Format(JsonResponse));
    end;
}
