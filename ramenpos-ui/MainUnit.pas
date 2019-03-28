unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  ComObj,
  ActionsUnit,
  TransactionsUnit,
  ComponentNames,
  ActiveX,
  SPIClient_TLB, Vcl.Menus;

type
  TfrmMain = class(TForm)
    pnlSettings: TPanel;
    lblSettings: TLabel;
    lblPosID: TLabel;
    lblSerialNumber: TLabel;
    lblDeviceAddress: TLabel;
    edtPosID: TEdit;
    edtSerialNumber: TEdit;
    edtDeviceAddress: TEdit;
    pnlAutoAddressResolution: TPanel;
    lblAutoAddressResolution: TLabel;
    btnSave: TButton;
    chkTestMode: TCheckBox;
    chkAutoAddress: TCheckBox;
    pnlSecrets: TPanel;
    lblSecrets: TLabel;
    chkSecrets: TCheckBox;
    edtSecrets: TEdit;
    pnlPairing: TPanel;
    lblPairing: TLabel;
    btnMain: TButton;
    lblPairingStatus: TLabel;
    mainMenuMain: TMainMenu;
    menuItemTransactions: TMenuItem;
    procedure btnSaveClick(Sender: TObject);
    procedure chkAutoAddressClick(Sender: TObject);
    procedure menuItemTransactionsClick(Sender: TObject);
    procedure chkSecretsClick(Sender: TObject);
    procedure btnMainClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CheckFormActions;
  private
    { Private declarations }
  public
    comWrapper: SPIClient_TLB.comWrapper;
    spi: SPIClient_TLB.spi;
    posId, eftposAddress, serialNumber: WideString;
    spiSecrets: SPIClient_TLB.Secrets;
    options: SPIClient_TLB.TransactionOptions;
  end;

type
  TMyWorkerThread = class(TThread)
  public
    procedure Execute; override;
  end;

var
  frmMain: TfrmMain;
  frmTransactions: TfrmTransactions;
  frmActions: TfrmActions;
  useSynchronize, UseQueue: Boolean;
  autoAdressEnabled: Boolean;
  delegationPointers: SPIClient_TLB.delegationPointers;

const
  APIKEY = 'RamenPosDeviceAddressApiKey';
  ACQUIRERCODE = 'wbc';

implementation

{$R *.dfm}

procedure TfrmMain.CheckFormActions;
begin
  if (not Assigned(frmActions)) then
  begin
    if (frmMain.Visible) then
    begin
      frmActions := TfrmActions.Create(frmMain);
      frmActions.PopupParent := frmMain;
      frmMain.Enabled := false;
    end
    else
    begin
      frmActions := TfrmActions.Create(frmTransactions);
      frmActions.PopupParent := frmTransactions;
      frmTransactions.Enabled := false;
    end;
  end;
  frmActions.Show;
end;

procedure Split(Delimiter: Char; Str: string; ListOfStrings: TStrings);
begin
  ListOfStrings.Clear;
  ListOfStrings.Delimiter := Delimiter;
  ListOfStrings.StrictDelimiter := True; // Requires D2006 or newer.
  ListOfStrings.DelimitedText := Str;
end;

procedure HandleFinishedGetLastTransaction(txFlowState
  : SPIClient_TLB.TransactionFlowState);
var
  gltResponse: SPIClient_TLB.GetLastTransactionResponse;
  purchaseResponse: SPIClient_TLB.purchaseResponse;
  success: SPIClient_TLB.SuccessState;
begin
  gltResponse := CreateComObject(CLASS_GetLastTransactionResponse)
    AS SPIClient_TLB.GetLastTransactionResponse;
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.purchaseResponse;

  if (txFlowState.Response <> nil) then
  begin
    gltResponse := frmMain.comWrapper.GetLastTransactionResponseInit
      (txFlowState.Response);

    success := frmMain.spi.GltMatch(gltResponse, frmActions.edtAction1.Text);
    if (success = SuccessState_Unknown) then
    begin
      frmActions.richEdtFlow.Lines.Add
        ('# Did not retrieve Expected Transaction. Here is what we got:');
    end
    else
    begin
      frmActions.richEdtFlow.Lines.Add
        ('# Tx Matched Expected Purchase Request.');
    end;

    purchaseResponse := frmMain.comWrapper.PurchaseResponseInit
      (txFlowState.Response);
    frmActions.richEdtFlow.Lines.Add
      ('# Scheme: ' + purchaseResponse.SchemeName);
    frmActions.richEdtFlow.Lines.Add('# Response: ' +
      purchaseResponse.GetResponseText);
    frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
    frmActions.richEdtFlow.Lines.Add
      ('# Error: ' + txFlowState.Response.GetError);
    frmTransactions.richEdtReceipt.Lines.Add
      (TrimLeft(purchaseResponse.GetCustomerReceipt));
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could Not Retrieve Last Transaction.');
  end;

end;

procedure HandleFinishedSettlementEnquiry(txFlowState
  : SPIClient_TLB.TransactionFlowState);
var
  settleResponse: SPIClient_TLB.Settlement;
  schemeEntry: SPIClient_TLB.SchemeSettlementEntry;
  schemeList: PSafeArray;
  LBound, UBound, i: LongInt;
begin
  settleResponse := CreateComObject(CLASS_Settlement)
    AS SPIClient_TLB.Settlement;

  schemeEntry := CreateComObject(CLASS_SchemeSettlementEntry)
    AS SPIClient_TLB.SchemeSettlementEntry;

  case txFlowState.success of
    SuccessState_Success:
      begin
        frmActions.richEdtFlow.Lines.Add('# SETTLEMENT ENQUIRY SUCCESSFUL!');
        settleResponse := frmMain.comWrapper.SettlementInit
          (txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add
          ('# Response: ' + settleResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# Period Start: ' +
          DateToStr(settleResponse.GetPeriodStartTime));
        frmActions.richEdtFlow.Lines.Add('# Period End: ' +
          DateToStr(settleResponse.GetPeriodEndTime));
        frmActions.richEdtFlow.Lines.Add('# Settlement Time: ' +
          DateToStr(settleResponse.GetTriggeredTime));
        frmActions.richEdtFlow.Lines.Add('# Transaction Range: ' +
          settleResponse.GetTransactionRange);
        frmActions.richEdtFlow.Lines.Add('# Terminal Id:' +
          settleResponse.GetTerminalId);
        frmActions.richEdtFlow.Lines.Add('# Total TX Count: ' +
          IntToStr(settleResponse.GetTotalCount));
        frmActions.richEdtFlow.Lines.Add('# Total TX Value: ' +
          IntToStr(settleResponse.GetTotalValue div 100));
        frmActions.richEdtFlow.Lines.Add('# By Aquirer TX Count: ' +
          IntToStr(settleResponse.GetSettleByAcquirerCount));
        frmActions.richEdtFlow.Lines.Add('# By Aquirer TX Value: ' +
          IntToStr(settleResponse.GetSettleByAcquirerValue div 100));
        frmActions.richEdtFlow.Lines.Add('# SCHEME SETTLEMENTS:');

        schemeList := frmMain.comWrapper.GetSchemeSettlementEntries
          (txFlowState);

        SafeArrayGetLBound(schemeList, 1, LBound);
        SafeArrayGetUBound(schemeList, 1, UBound);
        for i := LBound to UBound do
        begin
          SafeArrayGetElement(schemeList, i, schemeEntry);
          frmActions.richEdtFlow.Lines.Add('# ' + schemeEntry.ToString);
        end;

        if (not settleResponse.WasMerchantReceiptPrinted) then
        begin
          frmTransactions.richEdtReceipt.Lines.Add
            (TrimLeft(settleResponse.GetReceipt));
        end
        else
        begin
          frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
          frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
        end;
      end;

    SuccessState_Failed:
      begin
        frmActions.richEdtFlow.Lines.Add('# SETTLEMENT ENQUIRY FAILED!');

        if (txFlowState.Response <> nil) then
        begin
          settleResponse := frmMain.comWrapper.SettlementInit
            (txFlowState.Response);
          frmActions.richEdtFlow.Lines.Add
            ('# Response: ' + settleResponse.GetResponseText);
          frmActions.richEdtFlow.Lines.Add
            ('# Error: ' + txFlowState.Response.GetError);
          frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
          frmTransactions.richEdtReceipt.Lines.Add
            (TrimLeft(settleResponse.GetReceipt));
        end;

        if (not settleResponse.WasMerchantReceiptPrinted) then
        begin
          frmTransactions.richEdtReceipt.Lines.Add
            (TrimLeft(settleResponse.GetReceipt));
        end
        else
        begin
          frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
          frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
        end;
      end;

    SuccessState_Unknown:
      begin
        frmActions.richEdtFlow.Lines.Add
          ('# SETTLEMENT ENQUIRY RESULT UNKNOWN!');
      end;

  else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure HandleFinishedSettle(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  settleResponse: SPIClient_TLB.Settlement;
  schemeEntry: SPIClient_TLB.SchemeSettlementEntry;
  schemeList: PSafeArray;
  LBound, UBound, i: LongInt;
begin
  settleResponse := CreateComObject(CLASS_Settlement)
    AS SPIClient_TLB.Settlement;

  schemeEntry := CreateComObject(CLASS_SchemeSettlementEntry)
    AS SPIClient_TLB.SchemeSettlementEntry;

  case txFlowState.success of
    SuccessState_Success:
      begin
        frmActions.richEdtFlow.Lines.Add('# SETTLEMENT SUCCESSFUL!');
        if (txFlowState.Response <> nil) then
        begin
          settleResponse := frmMain.comWrapper.SettlementInit
            (txFlowState.Response);
          frmActions.richEdtFlow.Lines.Add
            ('# Response: ' + settleResponse.GetResponseText);
          frmActions.richEdtFlow.Lines.Add('# Period Start: ' +
            DateToStr(settleResponse.GetPeriodStartTime));
          frmActions.richEdtFlow.Lines.Add('# Period End: ' +
            DateToStr(settleResponse.GetPeriodEndTime));
          frmActions.richEdtFlow.Lines.Add('# Settlement Time: ' +
            DateToStr(settleResponse.GetTriggeredTime));
          frmActions.richEdtFlow.Lines.Add('# Transaction Range: ' +
            settleResponse.GetTransactionRange);
          frmActions.richEdtFlow.Lines.Add('# Terminal Id:' +
            settleResponse.GetTerminalId);
          frmActions.richEdtFlow.Lines.Add('# Total TX Count: ' +
            IntToStr(settleResponse.GetTotalCount));
          frmActions.richEdtFlow.Lines.Add('# Total TX Value: ' +
            IntToStr(settleResponse.GetTotalValue div 100));
          frmActions.richEdtFlow.Lines.Add('# By Aquirer TX Count: ' +
            IntToStr(settleResponse.GetSettleByAcquirerCount));
          frmActions.richEdtFlow.Lines.Add('# By Aquirer TX Value: ' +
            IntToStr(settleResponse.GetSettleByAcquirerValue div 100));
          frmActions.richEdtFlow.Lines.Add('# SCHEME SETTLEMENTS:');

          schemeList := frmMain.comWrapper.GetSchemeSettlementEntries
            (txFlowState);
          SafeArrayGetLBound(schemeList, 1, LBound);
          SafeArrayGetUBound(schemeList, 1, UBound);
          for i := LBound to UBound do
          begin
            SafeArrayGetElement(schemeList, i, schemeEntry);
            frmActions.richEdtFlow.Lines.Add('# ' + schemeEntry.ToString);
          end;

          if (not settleResponse.WasMerchantReceiptPrinted) then
          begin
            frmTransactions.richEdtReceipt.Lines.Add
              (TrimLeft(settleResponse.GetReceipt));
          end
          else
          begin
            frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
            frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
          end;
        end;
      end;

    SuccessState_Failed:
      begin
        frmActions.richEdtFlow.Lines.Add('# SETTLEMENT FAILED!');

        if (txFlowState.Response <> nil) then
        begin
          settleResponse := frmMain.comWrapper.SettlementInit
            (txFlowState.Response);
          frmActions.richEdtFlow.Lines.Add
            ('# Response: ' + settleResponse.GetResponseText);
          frmActions.richEdtFlow.Lines.Add
            ('# Error: ' + txFlowState.Response.GetError);
          if (not settleResponse.WasMerchantReceiptPrinted) then
          begin
            frmTransactions.richEdtReceipt.Lines.Add
              (TrimLeft(settleResponse.GetReceipt));
          end
          else
          begin
            frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
            frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
          end;
        end;
      end;

    SuccessState_Unknown:
      begin
        frmActions.richEdtFlow.Lines.Add
          ('# SETTLEMENT ENQUIRY RESULT UNKNOWN!');
      end;

  else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure HandleFinishedMoto(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  motoResponse: SPIClient_TLB.MotoPurchaseResponse;
  purchaseResponse: SPIClient_TLB.purchaseResponse;
begin
  motoResponse := CreateComObject(CLASS_MotoPurchaseResponse)
    AS SPIClient_TLB.MotoPurchaseResponse;
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.purchaseResponse;

  case txFlowState.success of
    SuccessState_Success:
      begin
        frmActions.richEdtFlow.Lines.Add('# WOOHOO - WE GOT MOTO-PAID!');
        motoResponse := frmMain.comWrapper.MotoPurchaseResponseInit
          (txFlowState.Response);
        purchaseResponse := motoResponse.purchaseResponse;
        frmActions.richEdtFlow.Lines.Add
          ('# Response: ' + purchaseResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
        frmActions.richEdtFlow.Lines.Add
          ('# Scheme: ' + purchaseResponse.SchemeName);
        frmActions.richEdtFlow.Lines.Add('# Card Entry: ' +
          purchaseResponse.GetCardEntry);
        frmActions.richEdtFlow.Lines.Add
          ('# PURCHASE: ' + IntToStr(purchaseResponse.GetCashoutAmount));
        frmActions.richEdtFlow.Lines.Add('# BANKED NON-CASH AMOUNT: ' +
          IntToStr(purchaseResponse.GetBankNonCashAmount));
        frmActions.richEdtFlow.Lines.Add('# BANKED CASH AMOUNT: ' +
          IntToStr(purchaseResponse.GetBankCashAmount));
        frmActions.richEdtFlow.Lines.Add('# SURCHARGE AMOUNT: ' +
          IntToStr(purchaseResponse.GetSurchargeAmount));

        if (not purchaseResponse.WasCustomerReceiptPrinted) then
        begin
          frmTransactions.richEdtReceipt.Lines.Add
            (TrimLeft(purchaseResponse.GetCustomerReceipt));
        end
        else
        begin
          frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
          frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
        end;
      end;

    SuccessState_Failed:
      begin
        frmActions.richEdtFlow.Lines.Add('# WE DID NOT GET MOTO-PAID :(');
        if (txFlowState.Response <> nil) then
        begin
          frmActions.richEdtFlow.Lines.Add
            ('# Error: ' + txFlowState.Response.GetError);
          frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
            txFlowState.Response.GetErrorDetail);
          motoResponse := frmMain.comWrapper.MotoPurchaseResponseInit
            (txFlowState.Response);
          purchaseResponse := motoResponse.purchaseResponse;
          frmActions.richEdtFlow.Lines.Add
            ('# Response: ' + purchaseResponse.GetResponseText);
          frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
          frmActions.richEdtFlow.Lines.Add
            ('# Scheme: ' + purchaseResponse.SchemeName);
          if (not purchaseResponse.WasCustomerReceiptPrinted) then
          begin
            frmTransactions.richEdtReceipt.Lines.Add
              (TrimLeft(purchaseResponse.GetCustomerReceipt));
          end
          else
          begin
            frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
            frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
          end;
        end;
      end;

    SuccessState_Unknown:
      begin
        frmActions.richEdtFlow.Lines.Add
          ('# WE''RE NOT QUITE SURE WHETHER THE MOTO WENT THROUGH OR NOT :/');
        frmActions.richEdtFlow.Lines.Add
          ('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
        frmActions.richEdtFlow.Lines.Add
          ('# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
      end;

  else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure HandleFinishedCashout(txFlowState
  : SPIClient_TLB.TransactionFlowState);
var
  cashoutResponse: SPIClient_TLB.CashoutOnlyResponse;
begin
  cashoutResponse := CreateComObject(CLASS_CashoutOnlyResponse)
    AS SPIClient_TLB.CashoutOnlyResponse;

  case txFlowState.success of
    SuccessState_Success:
      begin
        frmActions.richEdtFlow.Lines.Add
          ('# CASH-OUT SUCCESSFUL - HAND THEM THE CASH!');
        cashoutResponse := frmMain.comWrapper.CashoutOnlyResponseInit
          (txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add
          ('# Response: ' + cashoutResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# RRN: ' + cashoutResponse.GetRRN);
        frmActions.richEdtFlow.Lines.Add
          ('# Scheme: ' + cashoutResponse.SchemeName);
        frmActions.richEdtFlow.Lines.Add
          ('# CASHOUT: ' + IntToStr(cashoutResponse.GetCashoutAmount));
        frmActions.richEdtFlow.Lines.Add('# SURCHARGE: ' +
          IntToStr(cashoutResponse.GetSurchargeAmount));
        frmActions.richEdtFlow.Lines.Add('# BANKED NON-CASH AMOUNT: ' +
          IntToStr(cashoutResponse.GetBankNonCashAmount));
        frmActions.richEdtFlow.Lines.Add('# BANKED CASH AMOUNT: ' +
          IntToStr(cashoutResponse.GetBankCashAmount));

        if (not cashoutResponse.WasCustomerReceiptPrinted) then
        begin
          frmTransactions.richEdtReceipt.Lines.Add
            (TrimLeft(cashoutResponse.GetCustomerReceipt));
        end
        else
        begin
          frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
          frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
        end;
      end;

    SuccessState_Failed:
      begin
        frmActions.richEdtFlow.Lines.Add('# CASHOUT FAILED!');
        if (txFlowState.Response <> nil) then
        begin
          frmActions.richEdtFlow.Lines.Add
            ('# Error: ' + txFlowState.Response.GetError);
          frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
            txFlowState.Response.GetErrorDetail);
          cashoutResponse := frmMain.comWrapper.CashoutOnlyResponseInit
            (txFlowState.Response);
          frmActions.richEdtFlow.Lines.Add
            ('# Response: ' + cashoutResponse.GetResponseText);
          frmActions.richEdtFlow.Lines.Add('# RRN: ' + cashoutResponse.GetRRN);
          frmActions.richEdtFlow.Lines.Add
            ('# Scheme: ' + cashoutResponse.SchemeName);

          if (not cashoutResponse.WasCustomerReceiptPrinted) then
          begin
            frmTransactions.richEdtReceipt.Lines.Add
              (TrimLeft(cashoutResponse.GetCustomerReceipt));
          end
          else
          begin
            frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
            frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
          end;
        end;
      end;

    SuccessState_Unknown:
      begin
        frmActions.richEdtFlow.Lines.Add
          ('# WE''RE NOT QUITE SURE WHETHER THE CASHOUT WENT THROUGH OR NOT :/');
        frmActions.richEdtFlow.Lines.Add
          ('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
        frmActions.richEdtFlow.Lines.Add
          ('# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
      end;

  else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure HandleFinishedRefund(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  refundResponse: SPIClient_TLB.refundResponse;
begin
  refundResponse := CreateComObject(CLASS_RefundResponse)
    AS SPIClient_TLB.refundResponse;

  case txFlowState.success of
    SuccessState_Success:
      begin
        frmActions.richEdtFlow.Lines.Add('# REFUND GIVEN- OH WELL!');
        refundResponse := frmMain.comWrapper.RefundResponseInit
          (txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add
          ('# Response: ' + refundResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# RRN: ' + refundResponse.GetRRN);
        frmActions.richEdtFlow.Lines.Add
          ('# Scheme: ' + refundResponse.SchemeName);
        frmActions.richEdtFlow.Lines.Add('# REFUNDED AMOUNT: ' +
          IntToStr(refundResponse.GetRefundAmount));

        if (not refundResponse.WasCustomerReceiptPrinted) then
        begin
          frmTransactions.richEdtReceipt.Lines.Add
            (TrimLeft(refundResponse.GetCustomerReceipt));
        end
        else
        begin
          frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
          frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
        end;
      end;

    SuccessState_Failed:
      begin
        frmActions.richEdtFlow.Lines.Add('# REFUND FAILED!');
        if (txFlowState.Response <> nil) then
        begin
          frmActions.richEdtFlow.Lines.Add
            ('# Error: ' + txFlowState.Response.GetError);
          frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
            txFlowState.Response.GetErrorDetail);
          refundResponse := frmMain.comWrapper.RefundResponseInit
            (txFlowState.Response);
          frmActions.richEdtFlow.Lines.Add
            ('# Response: ' + refundResponse.GetResponseText);
          frmActions.richEdtFlow.Lines.Add('# RRN: ' + refundResponse.GetRRN);
          frmActions.richEdtFlow.Lines.Add
            ('# Scheme: ' + refundResponse.SchemeName);

          if (not refundResponse.WasCustomerReceiptPrinted) then
          begin
            frmTransactions.richEdtReceipt.Lines.Add
              (TrimLeft(refundResponse.GetCustomerReceipt));
          end
          else
          begin
            frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
            frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
          end;
        end;
      end;

    SuccessState_Unknown:
      begin
        frmActions.richEdtFlow.Lines.Add
          ('# WE''RE NOT QUITE SURE WHETHER THE REFUND WENT THROUGH OR NOT :/');
        frmActions.richEdtFlow.Lines.Add
          ('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
        frmActions.richEdtFlow.Lines.Add
          ('# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
      end;

  else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure HandleFinishedPurchase(txFlowState
  : SPIClient_TLB.TransactionFlowState);
var
  purchaseResponse: SPIClient_TLB.purchaseResponse;
begin
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.purchaseResponse;

  case txFlowState.success of
    SuccessState_Success:
      begin
        frmActions.richEdtFlow.Lines.Add('# WOOHOO - WE GOT PAID!');
        purchaseResponse := frmMain.comWrapper.PurchaseResponseInit
          (txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add
          ('# Response: ' + purchaseResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
        frmActions.richEdtFlow.Lines.Add
          ('# Scheme: ' + purchaseResponse.SchemeName);

        if (not purchaseResponse.WasCustomerReceiptPrinted) then
        begin
          frmTransactions.richEdtReceipt.Lines.Add
            (TrimLeft(purchaseResponse.GetCustomerReceipt));
        end
        else
        begin
          frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
          frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
        end;

        frmActions.richEdtFlow.Lines.Add
          ('# PURCHASE: ' + IntToStr(purchaseResponse.GetPurchaseAmount));
        frmActions.richEdtFlow.Lines.Add
          ('# TIP: ' + IntToStr(purchaseResponse.GetTipAmount));
        frmActions.richEdtFlow.Lines.Add
          ('# CASHOUT: ' + IntToStr(purchaseResponse.GetCashoutAmount));
        frmActions.richEdtFlow.Lines.Add('# SURCHARGE AMOUNT: ' +
          IntToStr(purchaseResponse.GetSurchargeAmount));
        frmActions.richEdtFlow.Lines.Add('# BANKED NON-CASH AMOUNT: ' +
          IntToStr(purchaseResponse.GetBankNonCashAmount));
        frmActions.richEdtFlow.Lines.Add('# BANKED CASH AMOUNT: ' +
          IntToStr(purchaseResponse.GetBankCashAmount));
      end;

    SuccessState_Failed:
      begin
        frmActions.richEdtFlow.Lines.Add('# WE DID NOT GET PAID :(');
        if (txFlowState.Response <> nil) then
        begin
          frmActions.richEdtFlow.Lines.Add
            ('# Error: ' + txFlowState.Response.GetError);
          frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
            txFlowState.Response.GetErrorDetail);
          purchaseResponse := frmMain.comWrapper.PurchaseResponseInit
            (txFlowState.Response);
          frmActions.richEdtFlow.Lines.Add
            ('# Response: ' + purchaseResponse.GetResponseText);
          frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
          frmActions.richEdtFlow.Lines.Add
            ('# Scheme: ' + purchaseResponse.SchemeName);
          if (not purchaseResponse.WasCustomerReceiptPrinted) then
          begin
            frmTransactions.richEdtReceipt.Lines.Add
              (TrimLeft(purchaseResponse.GetCustomerReceipt));
          end
          else
          begin
            frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
            frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
          end;
        end;
      end;

    SuccessState_Unknown:
      begin
        frmActions.richEdtFlow.Lines.Add
          ('# WE''RE NOT QUITE SURE WHETHER WE GOT PAID OR NOT :/');
        frmActions.richEdtFlow.Lines.Add
          ('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
        frmActions.richEdtFlow.Lines.Add
          ('# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.');
        frmActions.richEdtFlow.Lines.Add
          ('# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.');
      end;

  else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure SpiPrintFlowInfo;
var
  txFlowState: SPIClient_TLB.TransactionFlowState;
begin
  frmActions.richEdtFlow.Lines.Clear;

  case frmMain.spi.CurrentFlow of
    SpiFlow_Pairing:
      begin
        frmActions.lblFlowMessage.Caption :=
          frmMain.spi.CurrentPairingFlowState.Message;
        frmActions.richEdtFlow.Lines.Add('### PAIRING PROCESS UPDATE ###');
        frmActions.richEdtFlow.Lines.Add
          ('# ' + frmMain.spi.CurrentPairingFlowState.Message);
        frmActions.richEdtFlow.Lines.Add
          ('# Finished? ' + BoolToStr(frmMain.spi.CurrentPairingFlowState.
          Finished));
        frmActions.richEdtFlow.Lines.Add('# Successful? ' +
          BoolToStr(frmMain.spi.CurrentPairingFlowState.Successful));
        frmActions.richEdtFlow.Lines.Add('# Confirmation Code: ' +
          frmMain.spi.CurrentPairingFlowState.ConfirmationCode);
        frmActions.richEdtFlow.Lines.Add('# Waiting Confirm from Eftpos? ' +
          BoolToStr(frmMain.spi.CurrentPairingFlowState.
          AwaitingCheckFromEftpos));
        frmActions.richEdtFlow.Lines.Add('# Waiting Confirm from POS? ' +
          BoolToStr(frmMain.spi.CurrentPairingFlowState.AwaitingCheckFromPos));
      end;

    SpiFlow_Transaction:
      begin
        txFlowState := frmMain.spi.CurrentTxFlowState;
        frmActions.lblFlowMessage.Caption :=
          frmMain.spi.CurrentTxFlowState.DisplayMessage;
        frmActions.richEdtFlow.Lines.Add('### TX PROCESS UPDATE ###');
        frmActions.richEdtFlow.Lines.Add
          ('# ' + frmMain.spi.CurrentTxFlowState.DisplayMessage);
        frmActions.richEdtFlow.Lines.Add('# Id: ' + txFlowState.PosRefId);
        frmActions.richEdtFlow.Lines.Add
          ('# Type: ' + frmMain.comWrapper.GetTransactionTypeEnumName
          (txFlowState.type_));
        frmActions.richEdtFlow.Lines.Add
          ('# Amount: ' + IntToStr(txFlowState.amountCents div 100));
        frmActions.richEdtFlow.Lines.Add('# WaitingForSignature: ' +
          BoolToStr(txFlowState.AwaitingSignatureCheck));
        frmActions.richEdtFlow.Lines.Add('# Attempting to Cancel : ' +
          BoolToStr(txFlowState.AttemptingToCancel));
        frmActions.richEdtFlow.Lines.Add
          ('# Finished: ' + BoolToStr(txFlowState.Finished));
        frmActions.richEdtFlow.Lines.Add
          ('# Success: ' + frmMain.comWrapper.GetSuccessStateEnumName
          (txFlowState.success));
        frmActions.richEdtFlow.Lines.Add('# Last GLT Request Id: ' +
          txFlowState.LastGltRequestId);

        if (txFlowState.AwaitingSignatureCheck) then
        begin
          // We need to print the receipt for the customer to sign.
          frmActions.richEdtFlow.Lines.Add('# RECEIPT TO PRINT FOR SIGNATURE');
          frmTransactions.richEdtReceipt.Lines.Add
            (TrimLeft(txFlowState.SignatureRequiredMessage.GetMerchantReceipt));
        end;

        if (txFlowState.AwaitingPhoneForAuth) then
        begin
          // We need to print the receipt for the customer to sign.
          frmActions.richEdtFlow.Lines.Add('# PHONE FOR AUTH DETAILS:');
          frmTransactions.richEdtReceipt.Lines.Add
            ('# CALL: ' + txFlowState.PhoneForAuthRequiredMessage.
            GetPhoneNumber);
          frmTransactions.richEdtReceipt.Lines.Add('# QUOTE: Merchant Id: ' +
            txFlowState.PhoneForAuthRequiredMessage.GetMerchantId);
        end;

        // If the transaction is finished, we take some extra steps.
        If (txFlowState.Finished) then
        begin
          case txFlowState.type_ of
            TransactionType_Purchase:
              HandleFinishedPurchase(txFlowState);
            TransactionType_Refund:
              HandleFinishedRefund(txFlowState);
            TransactionType_CashoutOnly:
              HandleFinishedCashout(txFlowState);
            TransactionType_MOTO:
              HandleFinishedMoto(txFlowState);
            TransactionType_Settle:
              HandleFinishedSettle(txFlowState);
            TransactionType_SettlementEnquiry:
              HandleFinishedSettlementEnquiry(txFlowState);
            TransactionType_GetLastTransaction:
              HandleFinishedGetLastTransaction(txFlowState);
          else
            begin
              frmActions.richEdtFlow.Lines.Add('# CAN''T HANDLE TX TYPE: ' +
                frmMain.comWrapper.GetTransactionTypeEnumName
                (txFlowState.type_));
            end;
          end;
        end;
      end;

    SpiFlow_Idle:
      exit;

  else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;

  frmActions.richEdtFlow.Lines.Add
    ('# --------------- STATUS ------------------');
  frmActions.richEdtFlow.Lines.Add('# ' + frmMain.posId + ' <-> Eftpos: ' +
    frmMain.eftposAddress + ' #');
  frmActions.richEdtFlow.Lines.Add('# SPI STATUS: ' +
    frmMain.comWrapper.GetSpiStatusEnumName(frmMain.spi.CurrentStatus) +
    '     FLOW:' + frmMain.comWrapper.GetSpiFlowEnumName
    (frmMain.spi.CurrentFlow) + ' #');
  frmActions.richEdtFlow.Lines.Add
    ('# -----------------------------------------');
  frmActions.richEdtFlow.Lines.Add('# POS: v' + frmMain.comWrapper.GetPosVersion
    + ' Spi: v' + frmMain.comWrapper.GetSpiVersion);
end;

procedure GetUnvisibleActionComponents;
begin
  frmActions.lblAction1.Visible := false;
  frmActions.lblAction2.Visible := false;
  frmActions.lblAction3.Visible := false;
  frmActions.lblAction4.Visible := false;
  frmActions.edtAction1.Visible := false;
  frmActions.edtAction2.Visible := false;
  frmActions.edtAction3.Visible := false;
  frmActions.edtAction4.Visible := false;
  frmActions.cboxAction1.Visible := false;
end;

procedure GetOKActionComponents;
begin
  frmActions.btnAction1.Enabled := True;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.OK;
  frmActions.btnAction2.Visible := false;
  frmActions.btnAction3.Visible := false;
  GetUnvisibleActionComponents;
end;

procedure SpiActions;
begin
  frmActions.lblFlowStatus.Caption := frmMain.comWrapper.GetSpiFlowEnumName
    (frmMain.spi.CurrentFlow);
  frmTransactions.lblStatus.Caption := frmMain.comWrapper.GetSpiStatusEnumName
    (frmMain.spi.CurrentStatus) + ':' + frmMain.comWrapper.GetSpiFlowEnumName
    (frmMain.spi.CurrentFlow);

  case frmMain.spi.CurrentStatus of
    SpiStatus_Unpaired:
      case frmMain.spi.CurrentFlow of
        SpiFlow_Idle:
          begin
            frmActions.lblFlowMessage.Caption := 'Unpaired';
            frmActions.btnAction1.Enabled := True;
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := ComponentNames.OKUNPAIRED;
            frmActions.btnAction2.Visible := false;
            frmActions.btnAction3.Visible := false;
            frmMain.menuItemTransactions.Visible := false;
            GetUnvisibleActionComponents;
            frmTransactions.lblStatus.Color := clRed;
            exit
          end;
        SpiFlow_Pairing:
          begin
            if (frmMain.spi.CurrentPairingFlowState.AwaitingCheckFromPos) then
            begin
              frmActions.btnAction1.Enabled := True;
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := ComponentNames.CONFIRMCODE;
              frmActions.btnAction2.Visible := True;
              frmActions.btnAction2.Caption := ComponentNames.CANCELPAIRING;
              frmActions.btnAction3.Visible := false;
              GetUnvisibleActionComponents;
              exit
            end
            else if (not frmMain.spi.CurrentPairingFlowState.Finished) then
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := ComponentNames.CANCELPAIRING;
              frmActions.btnAction2.Visible := false;
              frmActions.btnAction3.Visible := false;
              GetUnvisibleActionComponents;
              exit
            end
            else
            begin
              GetOKActionComponents;
            end;
          end;

        SpiFlow_Transaction:
          begin
            frmActions.lblFlowMessage.Caption := 'Unpaired';
            frmActions.btnAction1.Enabled := True;
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := ComponentNames.OKUNPAIRED;
            frmActions.btnAction2.Visible := false;
            frmActions.btnAction3.Visible := false;
            frmMain.menuItemTransactions.Visible := false;
            GetUnvisibleActionComponents;
            frmTransactions.lblStatus.Color := clRed;
            exit
          end;

      else
        begin
          GetOKActionComponents;
          frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
            frmMain.comWrapper.GetSpiFlowEnumName(frmMain.spi.CurrentFlow));
          exit
        end;
      end;

    SpiStatus_PairedConnecting:
      case frmMain.spi.CurrentFlow of
        SpiFlow_Idle:
          begin
            frmMain.btnMain.Caption := ComponentNames.UNPAIR;
            frmTransactions.lblStatus.Color := clYellow;
            frmActions.lblFlowMessage.Caption := '# --> SPI Status Changed: ' +
              frmMain.comWrapper.GetSpiStatusEnumName
              (frmMain.spi.CurrentStatus);
            GetOKActionComponents;
            exit
          end;

        SpiFlow_Transaction:
          begin
            if (frmMain.spi.CurrentTxFlowState.AwaitingSignatureCheck) then
            begin
              frmActions.btnAction1.Enabled := True;
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := ComponentNames.ACCEPTSIGNATURE;
              frmActions.btnAction2.Visible := True;
              frmActions.btnAction2.Caption := ComponentNames.DECLINESIGNATURE;
              frmActions.btnAction3.Visible := True;
              frmActions.btnAction3.Caption := ComponentNames.CANCEL;
              GetUnvisibleActionComponents;
              exit
            end
            else if (not frmMain.spi.CurrentTxFlowState.Finished) then
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := ComponentNames.CANCEL;
              frmActions.btnAction2.Visible := false;
              frmActions.btnAction3.Visible := false;
              GetUnvisibleActionComponents;
              exit
            end
            else
            begin
              case frmMain.spi.CurrentTxFlowState.success of
                SuccessState_Success:
                  begin
                    GetOKActionComponents;
                    exit
                  end;

                SuccessState_Failed:
                  begin
                    frmActions.btnAction1.Enabled := True;
                    frmActions.btnAction1.Visible := True;
                    frmActions.btnAction1.Caption := ComponentNames.RETRY;
                    frmActions.btnAction2.Visible := True;
                    frmActions.btnAction2.Caption := ComponentNames.CANCEL;
                    frmActions.btnAction3.Visible := false;
                    GetUnvisibleActionComponents;
                    exit
                  end;
              else
                begin
                  frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
                    frmMain.comWrapper.GetSpiFlowEnumName
                    (frmMain.spi.CurrentFlow));
                  GetOKActionComponents;
                  exit
                end;
              end;
            end;
          end;

        SpiFlow_Pairing:
          begin
            GetOKActionComponents;
            exit
          end;

      else
        GetOKActionComponents;
        frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
          frmMain.comWrapper.GetSpiFlowEnumName(frmMain.spi.CurrentFlow));
        exit
      end;

    SpiStatus_PairedConnected:
      case frmMain.spi.CurrentFlow of
        SpiFlow_Idle:
          begin
            frmMain.btnMain.Caption := ComponentNames.UNPAIR;
            frmTransactions.lblStatus.Color := clGreen;
            frmActions.lblFlowMessage.Caption := '# --> SPI Status Changed: ' +
              frmMain.comWrapper.GetSpiStatusEnumName
              (frmMain.spi.CurrentStatus);
            frmMain.Hide;
            frmTransactions.Show;

            if (frmActions.btnAction1.Caption = ComponentNames.RETRY) then
            begin
              GetOKActionComponents;
            end;
            exit
          end;

        SpiFlow_Transaction:
          begin
            if (frmMain.spi.CurrentTxFlowState.AwaitingSignatureCheck) then
            begin
              frmActions.btnAction1.Enabled := True;
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := ComponentNames.ACCEPTSIGNATURE;
              frmActions.btnAction2.Visible := True;
              frmActions.btnAction2.Caption := ComponentNames.DECLINESIGNATURE;
              frmActions.btnAction3.Visible := True;
              frmActions.btnAction3.Caption := ComponentNames.CANCEL;
              GetUnvisibleActionComponents;
              exit
            end
            else if (not frmMain.spi.CurrentTxFlowState.Finished) then
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := ComponentNames.CANCEL;
              frmActions.btnAction2.Visible := false;
              frmActions.btnAction3.Visible := false;
              GetUnvisibleActionComponents;
              exit
            end
            else
            begin
              case frmMain.spi.CurrentTxFlowState.success of
                SuccessState_Success:
                  begin
                    GetOKActionComponents;
                    exit
                  end;

                SuccessState_Failed:
                  begin
                    frmActions.btnAction1.Enabled := True;
                    frmActions.btnAction1.Visible := True;
                    frmActions.btnAction1.Caption := ComponentNames.RETRY;
                    frmActions.btnAction2.Visible := True;
                    frmActions.btnAction2.Caption := ComponentNames.CANCEL;
                    frmActions.btnAction3.Visible := false;
                    GetUnvisibleActionComponents;
                    exit
                  end;
              else
                begin
                  frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
                    frmMain.comWrapper.GetSpiFlowEnumName
                    (frmMain.spi.CurrentFlow));
                  GetOKActionComponents;
                  exit
                end;
              end;
            end;
          end;

        SpiFlow_Pairing:
          begin
            GetOKActionComponents;
            exit
          end;

      else
        frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
          frmMain.comWrapper.GetSpiFlowEnumName(frmMain.spi.CurrentFlow));
        GetOKActionComponents;
        exit
      end;
  else
    frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
      frmMain.comWrapper.GetSpiFlowEnumName(frmMain.spi.CurrentFlow));
    GetOKActionComponents;
    exit
  end;
end;

procedure SpiPairingStatus;
begin
  frmMain.lblPairingStatus.Caption := frmMain.comWrapper.GetSpiStatusEnumName
    (frmMain.spi.CurrentStatus);
end;

procedure SpiStatusAndActions;
begin
  SpiPrintFlowInfo;
  SpiActions;
  SpiPairingStatus;
end;

procedure OnTransactionFlowStateChanged
  (e: SPIClient_TLB.TransactionFlowState); stdcall;
begin
  frmMain.CheckFormActions;
  TMyWorkerThread.Create(false);
end;

procedure OnPairingFlowStateChanged(e: SPIClient_TLB.PairingFlowState); stdcall;
begin
  frmMain.CheckFormActions;
  frmActions.lblFlowMessage.Caption := e.Message;

  if (e.ConfirmationCode <> '') then
  begin
    frmActions.richEdtFlow.Lines.Add('# Confirmation Code: ' +
      e.ConfirmationCode);
  end;

  TMyWorkerThread.Create(false);
end;

procedure OnSecretsChanged(e: SPIClient_TLB.Secrets); stdcall;
begin
  frmMain.spiSecrets := e;
//  frmTransactions(frmTransactions.btnSecrets);
  TMyWorkerThread.Create(false);
end;

procedure OnSpiStatusChanged(e: SPIClient_TLB.SpiStatusEventArgs); stdcall;
begin
  frmMain.CheckFormActions;
  frmActions.lblFlowMessage.Caption := 'It''s trying to connect';
  TMyWorkerThread.Create(false);
end;

procedure OnDeviceAddressStatusChanged
  (e: SPIClient_TLB.DeviceAddressStatus); stdcall;
begin
  frmMain.btnMain.Enabled := false;
  if (not string.IsNullOrWhiteSpace(e.Address)) then
  begin
    frmMain.edtDeviceAddress.Text := e.Address;
    frmMain.btnMain.Enabled := True;
    ShowMessage('Device Address has been updated to ' + e.Address);
  end;
end;

procedure HandlePrintingResponse(msg: SPIClient_TLB.Message); stdcall;

var
  printingResponse: SPIClient_TLB.printingResponse;
begin
  printingResponse := CreateComObject(CLASS_PrintingResponse)
    AS SPIClient_TLB.printingResponse;

  frmActions.richEdtFlow.Lines.Clear();
  printingResponse := frmMain.comWrapper.PrintingResponseInit(msg);

  if (printingResponse.IsSuccess) then
  begin
    frmActions.lblFlowMessage.Caption :=
      '# --> Printing Response: Printing Receipt Successful';
  end
  else
  begin
    frmActions.lblFlowMessage.Caption :=
      '# --> Printing Response: Printing Receipt failed: reason = ' +
      printingResponse.GetErrorReason + ', detail = ' +
      printingResponse.GetErrorDetail;
  end;

  frmMain.spi.AckFlowEndedAndBackToIdle;
  GetOKActionComponents;
  frmActions.Show;
end;

procedure HandleTerminalStatusResponse(msg: SPIClient_TLB.Message); stdcall;
var
  terminalStatusResponse: SPIClient_TLB.terminalStatusResponse;
begin
  terminalStatusResponse := CreateComObject(CLASS_TerminalStatusResponse)
    AS SPIClient_TLB.terminalStatusResponse;

  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    '# --> Terminal Status Response Successful';

  terminalStatusResponse := frmMain.comWrapper.TerminalStatusResponseInit(msg);
  frmActions.richEdtFlow.Lines.Add('# Terminal Status Response #');
  frmActions.richEdtFlow.Lines.Add('# Status: ' +
    terminalStatusResponse.GetStatus);
  frmActions.richEdtFlow.Lines.Add('# Battery Level: ' +
    StringReplace(terminalStatusResponse.GetBatteryLevel, 'd', '',
    [rfReplaceAll, rfIgnoreCase]) + '%');
  frmActions.richEdtFlow.Lines.Add('# Terminal Status Response #');

  frmMain.spi.AckFlowEndedAndBackToIdle;
  GetOKActionComponents;
  frmActions.Show;
end;

procedure HandleTerminalConfigurationResponse
  (msg: SPIClient_TLB.Message); stdcall;
var
  terminalConfigurationResponse: SPIClient_TLB.terminalConfigurationResponse;
begin
  terminalConfigurationResponse :=
    CreateComObject(CLASS_TerminalConfigurationResponse)
    AS SPIClient_TLB.terminalConfigurationResponse;

  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    '# --> Terminal Configuration Response Successful';

  terminalConfigurationResponse :=
    frmMain.comWrapper.TerminalConfigurationResponseInit(msg);
  frmActions.richEdtFlow.Lines.Add('# Terminal Configuration Response #');
  frmActions.richEdtFlow.Lines.Add('# Comms Selected: ' +
    terminalConfigurationResponse.GetCommsSelected);
  frmActions.richEdtFlow.Lines.Add('# Merchant Id: ' +
    terminalConfigurationResponse.GetMerchantId);
  frmActions.richEdtFlow.Lines.Add('# PA Version: ' +
    terminalConfigurationResponse.GetPAVersion);
  frmActions.richEdtFlow.Lines.Add('# Payment Interface Version: ' +
    terminalConfigurationResponse.GetPaymentInterfaceVersion);
  frmActions.richEdtFlow.Lines.Add('# Plugin Version: ' +
    terminalConfigurationResponse.GetPluginVersion);
  frmActions.richEdtFlow.Lines.Add('# Serial Number: ' +
    terminalConfigurationResponse.GetSerialNumber);
  frmActions.richEdtFlow.Lines.Add('# Terminal Id: ' +
    terminalConfigurationResponse.GetTerminalId);
  frmActions.richEdtFlow.Lines.Add('# Terminal Model: ' +
    terminalConfigurationResponse.GetTerminalModel);

  frmMain.spi.AckFlowEndedAndBackToIdle;
  GetOKActionComponents;
  frmActions.Show;
end;

procedure HandleBatteryLevelChanged(msg: SPIClient_TLB.Message); stdcall;
var
  terminalBattery: SPIClient_TLB.terminalBattery;
begin
  terminalBattery := CreateComObject(CLASS_TerminalBattery)
    AS SPIClient_TLB.terminalBattery;

  if (not frmActions.Visible) then
  begin

    frmActions.richEdtFlow.Lines.Clear();
    frmActions.lblFlowMessage.Caption :=
      '# --> Terminal Status Response Successful';

    terminalBattery := frmMain.comWrapper.TerminalBatteryInit(msg);
    frmActions.richEdtFlow.Lines.Add('"# --> Battery Level Changed Successful');
    frmActions.richEdtFlow.Lines.Add('# Battery Level: ' +
      StringReplace(terminalBattery.BatteryLevel, 'd', '',
      [rfReplaceAll, rfIgnoreCase]) + '%');
    frmActions.richEdtFlow.Lines.Add('# Terminal Status Response #');

    frmMain.spi.AckFlowEndedAndBackToIdle;
    frmActions.Show;
  end;
end;

procedure Start;
begin
  frmMain.spi := frmMain.comWrapper.SpiInit(frmMain.posId, '',
    frmMain.eftposAddress, frmMain.spiSecrets);
  frmMain.spi.SetPosInfo('assembly', '2.5.0');

  delegationPointers.CBTransactionStatePtr :=
    LongInt(@OnTransactionFlowStateChanged);
  delegationPointers.CBPairingFlowStatePtr :=
    LongInt(@OnPairingFlowStateChanged);
  delegationPointers.CBSecretsPtr := LongInt(@OnSecretsChanged);
  delegationPointers.CBStatusPtr := LongInt(@OnSpiStatusChanged);
  delegationPointers.CBDeviceAddressChangedPtr :=
    LongInt(@OnDeviceAddressStatusChanged);
  delegationPointers.CBPrintingResponsePtr := LongInt(@HandlePrintingResponse);
  delegationPointers.CBTerminalStatusResponsePtr :=
    LongInt(@HandleTerminalStatusResponse);
  delegationPointers.CBTerminalConfigurationResponsePtr :=
    LongInt(@HandleTerminalConfigurationResponse);
  delegationPointers.CBBatteryLevelChangedPtr :=
    LongInt(@HandleBatteryLevelChanged);

  frmMain.comWrapper.Main(frmMain.spi, delegationPointers);

  // initialise auto ip
  frmMain.spi.SetAcquirerCode(ACQUIRERCODE);
  frmMain.spi.SetDeviceApiKey(APIKEY);

  try
    frmMain.spi.Start;
  except
    on e: Exception do
    begin
      ShowMessage('SPI check failed: ' + e.Message +
        ', Please ensure you followed all the configuration steps on your machine');
      frmMain.pnlAutoAddressResolution.Enabled := false;
    end;
  end;
end;

function AreControlsValid(isPairing: Boolean): Boolean;
begin
  Result := True;

  autoAdressEnabled := frmMain.chkAutoAddress.Checked;
  frmMain.posId := frmMain.edtPosID.Text;
  frmMain.eftposAddress := frmMain.edtDeviceAddress.Text;
  frmMain.serialNumber := frmMain.edtSerialNumber.Text;

  if (isPairing and string.IsNullOrWhiteSpace(frmMain.eftposAddress)) then
  begin
    Result := false;
    ShowMessage
      ('Please enable auto address resolution or enter a device address');
    exit
  end;

  if (string.IsNullOrWhiteSpace(frmMain.posId)) then
  begin
    Result := false;
    ShowMessage('Please provide a Pos Id');
    exit
  end;

  if (frmMain.chkAutoAddress.Checked and string.IsNullOrWhiteSpace
    (frmMain.serialNumber)) then
  begin
    Result := false;
    ShowMessage('Please provide a Serial Number');
    exit
  end;
end;

function AreControlsValidForSecrets(): Boolean;
var
  OutPutList: TStringList;
begin
  frmMain.posId := frmMain.edtPosID.Text;
  frmMain.eftposAddress := frmMain.edtDeviceAddress.Text;

  if (string.IsNullOrWhiteSpace(frmMain.eftposAddress)) then
  begin
    Result := false;
    ShowMessage('Please provide a Eftpos address');
    exit
  end;

  if (string.IsNullOrWhiteSpace(frmMain.posId)) then
  begin
    Result := false;
    ShowMessage('Please provide a Pos Id');
    exit
  end;

  if (string.IsNullOrWhiteSpace(frmMain.edtSecrets.Text)) then
  begin
    Result := false;
    ShowMessage('Please provide Secrets');
    exit
  end;

  OutPutList := TStringList.Create;
  Split(':', frmMain.edtSecrets.Text, OutPutList);
  if (OutPutList.Count < 2) then
  begin
    ShowMessage('Please provide a valid Secrets');
    Result := false;
    exit
  end;

  Result := True;
end;

procedure TfrmMain.btnMainClick(Sender: TObject);
begin
  if (not Assigned(frmTransactions)) then
  begin
    frmTransactions := TfrmTransactions.Create(self);
    frmTransactions.Hide;
  end;

  if (btnMain.Caption = ComponentNames.Start) then
  begin
    if (not AreControlsValidForSecrets) then
    begin
      exit
    end;
  end
  else if (btnMain.Caption = ComponentNames.PAIR) then
  begin
    if (not AreControlsValid(True)) then
    begin
      exit
    end;

    spi.SetPosId(posId);
    spi.SetSerialNumber(serialNumber);
    spi.SetEftposAddress(eftposAddress);
    spi.PAIR;
    frmMain.Enabled := false;
  end
  else if (btnMain.Caption = ComponentNames.UNPAIR) then
  begin
    spi.UNPAIR;
    exit
  end
  else
  begin
    exit
  end;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  if (not AreControlsValid(false)) then
    exit;

  spi.SetTestMode(chkTestMode.Checked);
  spi.SetAutoAddressResolution(autoAdressEnabled); // trigger auto address
  spi.SetSerialNumber(serialNumber); // trigger auto address
end;

procedure TfrmMain.chkAutoAddressClick(Sender: TObject);
begin
  btnMain.Enabled := not chkAutoAddress.Checked;
  btnSave.Enabled := chkAutoAddress.Checked;
  chkTestMode.Checked := chkAutoAddress.Checked;
  chkTestMode.Enabled := chkAutoAddress.Checked;
  edtDeviceAddress.Enabled := not chkAutoAddress.Checked;
end;

procedure TfrmMain.chkSecretsClick(Sender: TObject);
begin
  edtSecrets.Enabled := chkSecrets.Checked;
  pnlAutoAddressResolution.Enabled := not chkSecrets.Checked;

  if (chkSecrets.Checked) then
  begin
    btnMain.Caption := ComponentNames.Start;
  end
  else
  begin
    btnMain.Caption := ComponentNames.PAIR;
    edtSecrets.Text := '';
  end;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  comWrapper := CreateComObject(CLASS_ComWrapper) AS SPIClient_TLB.comWrapper;
  spi := CreateComObject(CLASS_Spi) AS SPIClient_TLB.spi;
  spiSecrets := CreateComObject(CLASS_Secrets) AS SPIClient_TLB.Secrets;
  spiSecrets := nil;
  options := CreateComObject(CLASS_TransactionOptions)
    AS SPIClient_TLB.TransactionOptions;
  delegationPointers := CreateComObject(CLASS_DelegationPointers)
    AS SPIClient_TLB.delegationPointers;

  frmMain.edtPosID.Text := 'DELPHIPOS';
  frmMain.btnMain.Caption := ComponentNames.PAIR;
  edtDeviceAddress.Enabled := false;

  Start;
end;

procedure TfrmMain.menuItemTransactionsClick(Sender: TObject);
begin
  frmMain.Hide;
  frmMain.pnlAutoAddressResolution.Enabled := false;
  frmMain.pnlSettings.Enabled := false;
  frmTransactions.Show;
end;

procedure TMyWorkerThread.Execute;
begin
  Synchronize(
    procedure
    begin
      SpiStatusAndActions;
    end);
end;

end.
