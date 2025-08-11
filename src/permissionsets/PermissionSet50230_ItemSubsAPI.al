permissionset 50230 "ITEMSUBS API"
{
    Assignable = true;
    Caption = 'Item Substitutions API';
    Permissions =
        tabledata "Item Substitution" = RIMD,
        tabledata "Item Substitute Chain Buffer" = R,
        page "Item Substitution API" = X,
        page "Item Sub Chain API" = X,
        page "Item Substitute Actions API" = X,
        codeunit "Substitute Management" = X,
        codeunit "Item Substitute MCP Tool" = X;
}
