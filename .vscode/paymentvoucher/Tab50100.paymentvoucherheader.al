table 50100 "Payment Voucher Header"
{
    Caption = 'Payment Voucher';
    DataClassification = ToBeClassified;
    // DrillDownPageId = 50000;
    // LookupPageId = 50000;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
            DataClassification = CustomerContent;
            Description = 'Stores the reference of the payment voucher in the database';
        }

        field(2; "Date"; Date)
        {
            Caption = 'Date';

            DataClassification = CustomerContent;
            Description = 'Stores the date when the payment voucher was inserted into the system';
            trigger
            OnValidate()
            begin
                IF PayLinesExist() THEN BEGIN
                    ERROR('You first need to delete the existing Payment lines before changing the Currency Code'
                    );
                END ELSE BEGIN
                    "Paying Bank Account" := '';
                    VALIDATE("Paying Bank Account");
                END;
                IF "Currency Code" = xRec."Currency Code" THEN
                    UpdateCurrencyFactor();

                IF "Currency Code" <> xRec."Currency Code" THEN BEGIN
                    UpdateCurrencyFactor();
                END ELSE
                    IF "Currency Code" <> '' THEN
                        UpdateCurrencyFactor();

                //Update Payment Lines
                UpdateLines();
            end;
        }

        field(3; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DataClassification = CustomerContent;
        }

        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                TestField("Paying Bank Account");
                if "Currency Code" <> '' then begin
                    if BankAcc.Get("Paying Bank Account") then begin
                        BankAcc.TestField(BankAcc."Currency Code", "Currency Code");
                        "Currency Factor" := CurrExchRate.ExchangeRate(Date, "Currency Code");
                    end;
                end else begin
                    if BankAcc.Get("Paying Bank Account") then begin
                        BankAcc.TestField(BankAcc."Currency Code", '');
                    end;
                end;
            end;

        }

        field(9; "Payee"; Text[100])
        {
            Caption = 'Payee';
            DataClassification = CustomerContent;
            Description = 'Stores the name of the person who received the money';
        }

        field(10; "On Behalf Of"; Text[100])
        {
            Caption = 'On Behalf Of';
            DataClassification = CustomerContent;
            Description = 'Stores the name of the person on whose behalf the payment voucher was taken';
        }

        field(11; "Cashier"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
            Description = 'Stores the identifier of the cashier in the database';
        }

        field(16; "Posted"; Boolean)
        {
            Caption = 'Posted';
            DataClassification = CustomerContent;
            Description = 'Stores whether the payment voucher is posted or not';
        }

        field(17; "Date Posted"; Date)
        {
            Caption = 'Date Posted';
            DataClassification = CustomerContent;
            Description = 'Stores the date when the payment voucher was posted';
        }

        field(18; "Time Posted"; Time)
        {
            Caption = 'Time Posted';
            DataClassification = CustomerContent;
            Description = 'Stores the time when the payment voucher was posted';
        }

        field(19; "Posted By"; Code[50])
        {
            Caption = 'Posted By';
            DataClassification = CustomerContent;
            Description = 'Stores the name of the person who posted the payment voucher';
        }

        field(20; "Total Payment Amount"; Decimal)
        {
            Caption = 'Total Payment Amount';

            Description = 'Stores the amount of the payment voucher';
            FieldClass = FlowField;
            CalcFormula = Sum("Pv Lines Table".Amount WHERE(No = FIELD("No.")));

        }

        field(28; "Paying Bank Account"; Code[20])
        {
            Caption = 'Paying Bank Account';
            DataClassification = CustomerContent;
            Description = 'Stores the name of the paying bank account in the database';
            TableRelation = "Bank Account";
            trigger
            OnValidate()
            begin

                IF BankAcc.GET("Paying Bank Account") THEN BEGIN
                    "Bank Name" := BankAcc.Name;
                    "Currency Code" := BankAcc."Currency Code";
                    Validate("Currency Code");
                    IF "Pay Mode" = "Pay Mode"::Cash THEN BEGIN
                        // IF BankAcc. <> BankAcc."Bank Type"::Cash THEN
                        //ERROR('This Payment can only be made against Banks Handling Cash');
                    END;
                END;

                IF "Paying Type" = "Paying Type"::Bank THEN BEGIN
                    BankAcc.RESET();

                    IF BankAcc.GET("Paying Bank Account") THEN BEGIN
                        "Bank Name" := BankAcc.Name;
                        "Bank Account No" := BankAcc."Bank Account No.";
                        "Currency Code" := BankAcc."Currency Code";
                        Validate("Currency Code");

                        IF "Pay Mode" = "Pay Mode"::Cash THEN BEGIN
                            // IF BankAcc. <> BankAcc."Bank Type"::Cash THEN
                            //ERROR('This Payment can only be made against Banks Handling Cash');
                        END;
                    END;
                END ELSE
                    Vend.RESET();

                IF Vend.GET("Paying Bank Account") THEN BEGIN
                    "Bank Name" := Vend.Name;
                END;

                PLine.RESET();
                PLine.SETRANGE(PLine.No, "No.");
                PLine.SETRANGE(PLine."Account Type", PLine."Account Type"::"Bank Account");
                PLine.SETRANGE(PLine."Account No.", "Paying Bank Account");
                IF PLine.FINDFIRST() THEN
                    ERROR(Text002);
            end;
        }

        field(30; "Global Dimension 1 Code"; Code[25])
        {
            Caption = 'Global Dimension 1 Code';
            DataClassification = CustomerContent;
            Description = 'Stores the reference to the first global dimension in the database';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger
            OnValidate()
            begin
                "Shortcut Dimension 2 Code" := '';
                DimVal.RESET();
                DimVal.SETRANGE(DimVal."Global Dimension No.", 1);
                DimVal.SETRANGE(DimVal.Code, "Global Dimension 1 Code");
                IF DimVal.FIND('-') THEN
                    "Function Name" := DimVal.Name;
                UpdateLines();
            end;
        }

        field(35; "Status"; Option)
        {
            Caption = 'Status';
            DataClassification = ToBeClassified;
            OptionMembers = Open,"Pending Approval",Approved,Rejected,Posted,Cancelled;
            Description = 'Stores the status of the record in the database';
            trigger
            OnValidate()
            begin
                if Status = Status::Approved then begin

                    "Approval By" := UserId;
                    "Approval Date" := Today;
                end;
            end;
        }

        field(38; "Payment Type"; Option)
        {
            Caption = 'Payment Type';
            OptionMembers = Normal,"Petty Cash";
            DataClassification = CustomerContent;
        }

        field(56; "Shortcut Dimension 2 Code"; Code[25])
        {
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            Description = 'Stores the reference of the second global dimension in the database';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2), "Project Dimension Value" = field("Global Dimension 1 Code"));
            trigger
            OnValidate()
            begin
                DimVal.RESET();
                DimVal.SETRANGE(DimVal."Global Dimension No.", 2);
                DimVal.SETRANGE(DimVal.Code, "Shortcut Dimension 2 Code");
                IF DimVal.FIND('-') THEN
                    "Budget Center Name" := DimVal.Name;
                UpdateLines()
            end;
        }

        field(57; "Function Name"; Text[100])
        {
            Caption = 'Function Name';
            DataClassification = CustomerContent;
            Description = 'Stores the name of the function in the database';
        }

        field(58; "Budget Center Name"; Text[100])
        {
            Caption = 'Budget Center Name';
            DataClassification = CustomerContent;
            Description = 'Stores the name of the budget center in the database';
        }

        field(59; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
            DataClassification = CustomerContent;
            Description = 'Stores the description of the paying bank account in the database';
        }

        field(60; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            Description = 'Stores the number series in the database';
        }

        field(61; "Select"; Boolean)
        {
            Caption = 'Select';
            DataClassification = CustomerContent;
            Description = 'Enables the user to select a particular record';
        }

        field(62; "Total VAT Amount"; Decimal)
        {
            Caption = 'Total VAT Amount';
            FieldClass = FlowField;
            CalcFormula = Sum("Pv Lines Table"."VAT Amount" WHERE(No = FIELD("No.")));
            Editable = false;
        }

        field(63; "Total Withholding Tax Amount"; Decimal)
        {
            Caption = 'Total Withholding Tax Amount';

            FieldClass = FlowField;
            CalcFormula = Sum("Pv Lines Table"."Withholding Tax Amount" WHERE(No = FIELD("No.")));
            Editable = false;
        }

        field(64; "Total Net Amount"; Decimal)
        {
            Caption = 'Total Net Amount';
            FieldClass = FlowField;
            CalcFormula = Sum("Pv Lines Table"."Net Amount" WHERE(No = FIELD("No.")));
            Editable = false;
        }
        field(65; "Paying Type"; option)
        {
            OptionMembers = " ",Vendor,Bank;

        }
        field(104; "Current Status"; code[40])
        {

        }

        field(66; "Cheque No."; Code[20])
        {
            trigger
            OnValidate()
            begin
                Paymentsvoucher.RESET();
                Paymentsvoucher.SETRANGE(Paymentsvoucher."Cheque No.", "Cheque No.");
                Paymentsvoucher.SETRANGE(Paymentsvoucher.Posted, TRUE);
                IF Paymentsvoucher.FIND('-') THEN
                    ERROR('Cheque no has already been used.');


                IF STRLEN("Cheque No.") < 6 THEN
                    ERROR('Cheque No. Can not be less than 6 Characters');

            end;

        }
        field(67; "Pay Mode"; Option)
        {
            OptionMembers = " ",Cash,Cheque,EFT,RTGS,"Letter of Credit";
        }
        field(68; "Payment Release Date"; Date)
        {

            trigger
            OnValidate()
            begin
                IF "Payment Release Date" < Date THEN
                    ERROR('The Payment Release Date cannot be lesser than the Document Date');
            end;
        }
        field(69; "No. Printed"; Integer) { }
        field(70; "VAT Base Amount"; Decimal) { }
        field(71; "Exchange Rate"; Decimal) { }
        field(72; "Currency Reciprical"; Decimal) { }
        field(73; "Current Source A/C Bal."; Decimal) { }
        field(74; "Cancellation Remarks"; Text[250]) { }
        field(75; "Register Number"; Integer) { }
        field(76; "From Entry No."; Integer) { }
        field(77; "To Entry No."; Integer) { }
        field(78; "Invoice Currency Code"; Code[10])
        {
            TableRelation = Currency;
        }

        field(79; "Total Payment Amount LCY"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Sum("Pv Lines Table"."Amount lcy" WHERE(No = FIELD("No.")));
        }
        field(80; "Document Type"; Option)
        {
            OptionMembers = " ","Payment Voucher","Petty Cash";

        }
        field(81; "Shortcut Dimension 3 Code"; Code[25])
        {

            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3));
            trigger
            OnValidate()
            begin
                DimVal.RESET();
                //DimVal.SETRANGE(DimVal."Global Dimension No.",2);
                DimVal.SETRANGE(DimVal.Code, "Shortcut Dimension 3 Code");
                IF DimVal.FIND('-') THEN
                    Dim3 := DimVal.Name
            end;
        }
        field(82; "Shortcut Dimension 4 Code"; Code[25])
        {

            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3));
            trigger
            OnValidate()
            begin
                DimVal.RESET();
                //DimVal.SETRANGE(DimVal."Global Dimension No.",2);
                DimVal.SETRANGE(DimVal.Code, "Shortcut Dimension 4 Code");
                IF DimVal.FIND('-') THEN
                    Dim4 := DimVal.Name
            end;
        }
        field(83; "Dim3"; Text[250])
        {

        }
        field(84; "Dim4"; Text[250]) { }
        field(85; "Responsibility Center"; Code[10])
        {
            TableRelation = "Responsibility Center";

            trigger
            OnValidate()
            begin
                TESTFIELD(Status, Status::Open);

                IF PayLinesExist() THEN BEGIN
                    ERROR('You first need to delete the existing Payment lines before changing the Responsibility Center');
                END ELSE BEGIN
                    "Currency Code" := '';
                    VALIDATE("Currency Code");
                    "Paying Bank Account" := '';
                    VALIDATE("Paying Bank Account");
                END;
            end;
        }
        field(86; "Cheque Type"; Option)
        {

            OptionMembers = " ","Computer Check","Manual Check";
        }
        field(87; "Total Retention Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Pv Lines Table"."Retention Amount" WHERE(No = FIELD("No.")));
            Editable = false;
        }
        field(88; "Payment Narration"; Text[50])
        {

        }

        field(90; "Paying Vendor Account"; Code[20])
        {
            TableRelation = IF ("Paying Type" = FILTER(Vendor)) Vendor."No." ELSE IF ("Paying Type" = FILTER(Bank)) "Bank Account"."No.";
            trigger
            OnValidate()
            begin
                Vend.RESET();
                "Bank Name" := '';
                IF Vend.GET("Paying Vendor Account") THEN BEGIN
                    Payee := Vend.Name;
                END;
            end;
        }
        field(91; "Fosa Bank Account"; Code[20])
        {
            TableRelation = "Bank Account"."No.";
        }
        field(92; "Expense Account"; Code[20])
        {

            TableRelation = "G/L Account"."No.";
        }
        field(93; "Expense Type"; Option)
        {

            OptionMembers = " ",Normal,Director,Member;
        }
        field(94; "Refund Charge"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Sum("Pv Lines Table"."Refund Charge" WHERE(No = FIELD("No.")));
        }
        field(95; "Net Amount"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Sum("Pv Lines Table"."Net Amount" WHERE(No = FIELD("No.")));
        }

        field(96; "WithHolding Tax Amount"; Decimal)
        {

            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Sum("Pv Lines Table"."Withholding Tax Amount" WHERE(No = FIELD("No.")));
        }
        field(97; "Global Dimension 2 Code"; Code[20])
        {

        }
        field(98; "Bank Account Name"; Text[50]) { }
        field(99; "Invoice Number"; Code[25]) { }
        field(100; "Voucher Type"; Option)
        {

            OptionMembers = " ","General Expense","Funeral Expense";
        }
        field(101; "Invoice No."; Code[20]) { }
        field(105; "PAYE Code"; Code[20]) { }
        field(106; "Total PAYE Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Pv Lines Table"."PAYE Amount" WHERE(No = FIELD("No.")));
            Editable = false;
        }
        field(107; "Pending With"; Code[100]) { }
        field(108; "LPO/LSO No"; Code[20]) { }
        field(109; "LPO Date"; Date) { }
        field(110; "Budget Checked"; Boolean) { }

        field(147; "No Series"; Code[10])
        {
            DataClassification = ToBeClassified;
        }

        field(112; "Approval Date"; Date)
        {
            DataClassification = ToBeClassified;
        }

        field(114; "Approval By"; Code[40])
        {
            DataClassification = ToBeClassified;
        }

        field(115; "Bank Account No"; Code[40])
        {
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    var
        Setup: Record "Funds General Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        UserTemplate: Record "Funds User Setup";
        PLine: Record "Pv Lines Table";
        Paymentsvoucher: Record "Payment Voucher Header";
        PayLine: Record "Pv Lines Table";
        CurrencyDate: Date;
        CurrExchRate: Record "Currency Exchange Rate";
        BankAcc: Record "Bank Account";
        Vend: Record Vendor;
        DimVal: Record "Dimension Value";
        Text002: TextConst ENU = 'There is an Account number on the  payment lines the same as Paying Bank Account you are trying to select.';

    trigger OnInsert()
    begin

        if "No." = '' then begin
            if "Payment Type" = "Payment Type"::Normal then begin
                // Check Payments
                Setup.Get();
                Setup.TestField(Setup."Payment Voucher Nos");
                NoSeriesMgt.InitSeries(Setup."Payment Voucher Nos", xRec."No Series", 0D, "No.", "No Series");
            end;

            if "Payment Type" = "Payment Type"::"Petty Cash" then begin
                // PettyCash Payments
                Setup.Get();
                Setup.TestField(Setup."PettyCash Nos");
                NoSeriesMgt.InitSeries(Setup."PettyCash Nos", xRec."No Series", 0D, "No.", "No Series");
            end;

        end;


        UserTemplate.RESET();
        UserTemplate.SETRANGE(UserTemplate."User ID", USERID);
        IF UserTemplate.FINDFIRST() THEN BEGIN
            IF "Payment Type" = "Payment Type"::"Petty Cash" THEN BEGIN
                //UserTemplate.TESTFIELD(UserTemplate."Default Petty Cash Bank");
                //"Paying Bank Account":=UserTemplate."Default Petty Cash Bank";
            END ELSE BEGIN
                "Paying Bank Account" := UserTemplate."Default Payment Bank";
            END;
            VALIDATE("Paying Bank Account");
        END;

        Date := TODAY;
        "Payment Release Date" := TODAY;
        Cashier := USERID;
        VALIDATE(Cashier);
    end;

    trigger
    OnModify()
    begin
        IF Status = Status::Open THEN
            UpdateLines();
    end;

    procedure UpdateLines()
    begin


        PLine.RESET();
        PLine.SETRANGE(PLine.No, "No.");
        IF PLine.FINDFIRST() THEN BEGIN
            REPEAT
                PLine."Global Dimension 1 Code" := "Global Dimension 1 Code";
                PLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                PLine."Shortcut Dimension 3 Code" := "Shortcut Dimension 3 Code";
                PLine."Shortcut Dimension 4 Code" := "Shortcut Dimension 4 Code";
                PLine."Currency Factor" := "Currency Factor";
                PLine."Currency Code" := "Currency Code";
                PLine."Paying Bank Account" := "Paying Bank Account";
                PLine."Payment Type" := "Payment Type";
                PLine.VALIDATE("Currency Factor");
                PLine.MODIFY();
            UNTIL PLine.NEXT() = 0;
        END;
    end;

    procedure PayLinesExist(): Boolean
    begin
        PayLine.RESET();
        PayLine.SETRANGE("Payment Type", "Payment Type");
        PayLine.SETRANGE(No, "No.");
        EXIT(PayLine.FINDFIRST());
    end;

    procedure UpdateCurrencyFactor()

    begin


        IF "Currency Code" <> '' THEN BEGIN
            CurrencyDate := Date;
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        END ELSE
            "Currency Factor" := 0
    end;
}
