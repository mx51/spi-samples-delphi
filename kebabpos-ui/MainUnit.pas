unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  ComObj,
  ActionsUnit,
  ActiveX,
  SPIClient_TLB, Vcl.Menus;

type
  TfrmMain = class(TForm)
    pnlSettings: TPanel;
    lblSettings: TLabel;
    lblPosID: TLabel;
    edtPosID: TEdit;
    lblEftposAddress: TLabel;
    edtEftposAddress: TEdit;
    pnlStatus: TPanel;
    lblStatusHead: TLabel;
    lblStatus: TLabel;
    btnPair: TButton;
    pnlReceipt: TPanel;
    lblReceipt: TLabel;
    richEdtReceipt: TRichEdit;
    pnlTransActions: TPanel;
    btnPurchase: TButton;
    btnRefund: TButton;
    btnSettle: TButton;
    btnSettleEnq: TButton;
    lblReceiptFrom: TLabel;
    lblSignFrom: TLabel;
    btnMoto: TButton;
    btnCashOut: TButton;
    pnlOtherActions: TPanel;
    lblOtherActions: TLabel;
    btnRecover: TButton;
    btnLastTx: TButton;
    lblTransActions: TLabel;
    radioReceipt: TRadioGroup;
    radioSign: TRadioGroup;
    edtReference: TEdit;
    lblReference: TLabel;
    btnSecrets: TButton;
    btnSave: TButton;
    lblSecrets: TLabel;
    edtSecrets: TEdit;
    procedure btnPairClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRefundClick(Sender: TObject);
    procedure btnSettleClick(Sender: TObject);
    procedure btnPurchaseClick(Sender: TObject);
    procedure btnSettleEnqClick(Sender: TObject);
    procedure btnCashOutClick(Sender: TObject);
    procedure btnMotoClick(Sender: TObject);
    procedure btnLastTxClick(Sender: TObject);
    procedure btnRecoverClick(Sender: TObject);
    procedure btnSecretsClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private

  public

  end;

type
  TMyWorkerThread = class(TThread)
  public
    procedure Execute; override;
  end;

var
  frmMain: TfrmMain;
  frmActions: TfrmActions;
  ComWrapper: SPIClient_TLB.ComWrapper;
  Spi: SPIClient_TLB.Spi;
  _posId, _eftposAddress: WideString;
  SpiSecrets: SPIClient_TLB.Secrets;
  UseSynchronize, UseQueue: Boolean;

implementation

{$R *.dfm}

procedure Split(Delimiter: Char; Str: string; ListOfStrings: TStrings) ;
begin
   ListOfStrings.Clear;
   ListOfStrings.Delimiter       := Delimiter;
   ListOfStrings.StrictDelimiter := True; // Requires D2006 or newer.
   ListOfStrings.DelimitedText   := Str;
end;

function FormExists(apForm: TForm): boolean;
var
  i: Word;
begin
  Result := False;
  for i := 0 to Screen.FormCount - 1 do
    if (Screen.Forms[i] = apForm) then
    begin
      Result := True;
      Break;
    end;
end;

procedure LoadPersistedState;
var
  OutPutList: TStringList;
begin
  if (frmMain.edtSecrets.Text <> '') then
  begin
    OutPutList := TStringList.Create;
    Split(':', frmMain.edtSecrets.Text, OutPutList);
    SpiSecrets := ComWrapper.SecretsInit(OutPutList[0], OutPutList[1]);
  end
end;

procedure HandleFinishedGetLastTransaction(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  gltResponse: SPIClient_TLB.GetLastTransactionResponse;
  purchaseResponse: SPIClient_TLB.PurchaseResponse;
  success: SPIClient_TLB.SuccessState;
begin
  gltResponse := CreateComObject(CLASS_GetLastTransactionResponse)
    AS SPIClient_TLB.GetLastTransactionResponse;
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.PurchaseResponse;

  if (txFlowState.Response <> nil) then
  begin
  gltResponse := ComWrapper.GetLastTransactionResponseInit(
    txFlowState.Response);

    success := Spi.GltMatch(gltResponse, frmMain.edtReference.Text);
    if (success = SuccessState_Unknown) then
    begin
      frmActions.richEdtFlow.Lines.Add(
        '# Did not retrieve Expected Transaction. Here is what we got:');
    end
    else
    begin
      frmActions.richEdtFlow.Lines.Add(
      '# Tx Matched Expected Purchase Request.');
    end;

    purchaseResponse := ComWrapper.PurchaseResponseInit(txFlowState.Response);
      frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
      purchaseResponse.SchemeName);
    frmActions.richEdtFlow.Lines.Add('# Response: ' +
      purchaseResponse.GetResponseText);
    frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
    frmActions.richEdtFlow.Lines.Add('# Error: ' +
      txFlowState.Response.GetError);
    frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
    frmMain.richEdtReceipt.Lines.Add
      (TrimLeft(purchaseResponse.GetCustomerReceipt));
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could Not Retrieve Last Transaction.');
  end;

end;

procedure HandleFinishedSettlementEnquiry(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  settleResponse: SPIClient_TLB.Settlement;
  schemeEntry: SPIClient_TLB.SchemeSettlementEntry;
  schemeList: PSafeArray;
  LBound, UBound, I: LongInt;
begin
  settleResponse := CreateComObject(CLASS_Settlement)
    AS SPIClient_TLB.Settlement;

  schemeEntry := CreateComObject(CLASS_SchemeSettlementEntry)
    AS SPIClient_TLB.SchemeSettlementEntry;

  case txFlowState.Success  of
    SuccessState_Success:
	  begin
      frmActions.richEdtFlow.Lines.Add('# SETTLEMENT ENQUIRY SUCCESSFUL!');
      settleResponse := ComWrapper.SettlementInit(txFlowState.Response);
      frmActions.richEdtFlow.Lines.Add('# Response: ' +
			  settleResponse.GetResponseText);
      frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
      frmMain.richEdtReceipt.Lines.Add
        (TrimLeft(settleResponse.GetReceipt));
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

      schemeList := ComWrapper.GetSchemeSettlementEntries(txFlowState);

      SafeArrayGetLBound(schemeList, 1, LBound);
      SafeArrayGetUBound(schemeList, 1, UBound);
      for I := LBound to UBound do
      begin
        SafeArrayGetElement(schemeList, I, schemeEntry);
        frmActions.richEdtFlow.Lines.Add('# ' + schemeEntry.ToString);
      end;
    end;

    SuccessState_Failed:
	  begin
      frmActions.richEdtFlow.Lines.Add('# SETTLEMENT ENQUIRY FAILED!');

      if (txFlowState.Response <> nil) then
      begin
        settleResponse := ComWrapper.SettlementInit(txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add('# Response: ' +
			    settleResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# Error: ' +
			    txFlowState.Response.GetError);
        frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
        frmMain.richEdtReceipt.Lines.Add(
          TrimLeft(settleResponse.GetReceipt));
      end;
    end;

    SuccessState_Unknown:
	  begin
      frmActions.richEdtFlow.Lines.Add('# SETTLEMENT ENQUIRY RESULT UNKNOWN!');
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
  LBound, UBound, I: LongInt;
begin
  settleResponse := CreateComObject(CLASS_Settlement)
    AS SPIClient_TLB.Settlement;

  schemeEntry := CreateComObject(CLASS_SchemeSettlementEntry)
    AS SPIClient_TLB.SchemeSettlementEntry;

  case txFlowState.Success  of
    SuccessState_Success:
	  begin
      frmActions.richEdtFlow.Lines.Add('# SETTLEMENT SUCCESSFUL!');
      settleResponse := ComWrapper.SettlementInit(txFlowState.Response);
      frmActions.richEdtFlow.Lines.Add('# Response: ' +
			  settleResponse.GetResponseText);
      frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
      frmMain.richEdtReceipt.Lines.Add
        (TrimLeft(settleResponse.GetReceipt));
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

      schemeList := ComWrapper.GetSchemeSettlementEntries(txFlowState);
      SafeArrayGetLBound(schemeList, 1, LBound);
      SafeArrayGetUBound(schemeList, 1, UBound);
      for I := LBound to UBound do
      begin
        SafeArrayGetElement(schemeList, I, schemeEntry);
        frmActions.richEdtFlow.Lines.Add('# ' + schemeEntry.ToString);
      end;
	  end;

    SuccessState_Failed:
	  begin
      frmActions.richEdtFlow.Lines.Add('# SETTLEMENT FAILED!');

      if (txFlowState.Response <> nil) then
      begin
        settleResponse := ComWrapper.SettlementInit(txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add('# Response: ' +
			    settleResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# Error: ' +
			    txFlowState.Response.GetError);
        frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
        frmMain.richEdtReceipt.Lines.Add(
          TrimLeft(settleResponse.GetReceipt));
      end;
    end;

    SuccessState_Unknown:
	  begin
      frmActions.richEdtFlow.Lines.Add('# SETTLEMENT ENQUIRY RESULT UNKNOWN!');
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
  purchaseResponse: SPIClient_TLB.PurchaseResponse;
begin
  motoResponse := CreateComObject(CLASS_MotoPurchaseResponse)
    AS SPIClient_TLB.MotoPurchaseResponse;
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.PurchaseResponse;

  case txFlowState.Success  of
    SuccessState_Success:
	  begin
      frmActions.richEdtFlow.Lines.Add('# WOOHOO - WE GOT MOTO-PAID!');
      motoResponse := ComWrapper.MotoPurchaseResponseInit(txFlowState.Response);
      purchaseResponse := motoResponse.PurchaseResponse;
      frmActions.richEdtFlow.Lines.Add('# Response: ' +
			  purchaseResponse.GetResponseText);
      frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
      frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
        purchaseResponse.SchemeName);
      frmActions.richEdtFlow.Lines.Add('# Card Entry: ' + purchaseResponse.GetCardEntry);
      frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');

      if (not purchaseResponse.WasCustomerReceiptPrinted) then
      begin
        frmMain.richEdtReceipt.Lines.Add
			    (TrimLeft(purchaseResponse.GetCustomerReceipt));
      end
      else
      begin
        frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
      end;

      frmActions.richEdtFlow.Lines.Add('# PURCHASE: ' +
        IntToStr(purchaseResponse.GetCashoutAmount));
      frmActions.richEdtFlow.Lines.Add('# BANKED NON-CASH AMOUNT: ' +
        IntToStr(purchaseResponse.GetBankNonCashAmount));
      frmActions.richEdtFlow.Lines.Add('# BANKED CASH AMOUNT: ' +
        IntToStr(purchaseResponse.GetBankCashAmount));
	  end;

    SuccessState_Failed:
	  begin
      frmActions.richEdtFlow.Lines.Add('# WE DID NOT GET MOTO-PAID :(');
      frmActions.richEdtFlow.Lines.Add('# Error: ' +
			    txFlowState.Response.GetError);
      frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
			    txFlowState.Response.GetErrorDetail);

      if (txFlowState.Response <> nil) then
      begin
        motoResponse := ComWrapper.MotoPurchaseResponseInit(txFlowState.Response);
        purchaseResponse := motoResponse.PurchaseResponse;
        frmActions.richEdtFlow.Lines.Add('# Response: ' +
			    purchaseResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
        frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
          purchaseResponse.SchemeName);
        frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
        frmMain.richEdtReceipt.Lines.Add
			      (TrimLeft(purchaseResponse.GetCustomerReceipt));
      end;
    end;

    SuccessState_Unknown:
	  begin
      frmActions.richEdtFlow.Lines.Add('# WE''RE NOT QUITE SURE WHETHER THE MOTO WENT THROUGH OR NOT :/');
      frmActions.richEdtFlow.Lines.Add('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
      frmActions.richEdtFlow.Lines.Add('# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
    end;

    else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure HandleFinishedCashout(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  cashoutResponse: SPIClient_TLB.CashoutOnlyResponse;
begin
  cashoutResponse := CreateComObject(CLASS_CashoutOnlyResponse)
    AS SPIClient_TLB.CashoutOnlyResponse;

  case txFlowState.Success  of
    SuccessState_Success:
	  begin
      frmActions.richEdtFlow.Lines.Add('# CASH-OUT SUCCESSFUL - HAND THEM THE CASH!');
      cashoutResponse := ComWrapper.CashoutOnlyResponseInit(txFlowState.Response);
      frmActions.richEdtFlow.Lines.Add('# Response: ' +
			  cashoutResponse.GetResponseText);
      frmActions.richEdtFlow.Lines.Add('# RRN: ' + cashoutResponse.GetRRN);
      frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
        cashoutResponse.SchemeName);
      frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');

      if (not cashoutResponse.WasCustomerReceiptPrinted) then
      begin
        frmMain.richEdtReceipt.Lines.Add
			    (TrimLeft(cashoutResponse.GetCustomerReceipt));
      end
      else
      begin
        frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
      end;

      frmActions.richEdtFlow.Lines.Add('# CASHOUT: ' +
        IntToStr(cashoutResponse.GetCashoutAmount));
      frmActions.richEdtFlow.Lines.Add('# BANKED NON-CASH AMOUNT: ' +
        IntToStr(cashoutResponse.GetBankNonCashAmount));
      frmActions.richEdtFlow.Lines.Add('# BANKED CASH AMOUNT: ' +
        IntToStr(cashoutResponse.GetBankCashAmount));
	  end;

    SuccessState_Failed:
	  begin
      frmActions.richEdtFlow.Lines.Add('# CASHOUT FAILED!');
      frmActions.richEdtFlow.Lines.Add('# Error: ' +
			    txFlowState.Response.GetError);
      frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
			    txFlowState.Response.GetErrorDetail);

      if (txFlowState.Response <> nil) then
      begin
        cashoutResponse := ComWrapper.CashoutOnlyResponseInit(
          txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add('# Response: ' +
			    cashoutResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# RRN: ' + cashoutResponse.GetRRN);
        frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
          cashoutResponse.SchemeName);
        frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
        frmMain.richEdtReceipt.Lines.Add
			      (TrimLeft(cashoutResponse.GetCustomerReceipt));
      end;
    end;

    SuccessState_Unknown:
	  begin
      frmActions.richEdtFlow.Lines.Add('# WE''RE NOT QUITE SURE WHETHER THE CASHOUT WENT THROUGH OR NOT :/');
      frmActions.richEdtFlow.Lines.Add('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
      frmActions.richEdtFlow.Lines.Add('# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
    end;

    else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure HandleFinishedRefund(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  refundResponse: SPIClient_TLB.RefundResponse;
begin
  refundResponse := CreateComObject(CLASS_RefundResponse)
    AS SPIClient_TLB.RefundResponse;

  case txFlowState.Success  of
    SuccessState_Success:
	  begin
      frmActions.richEdtFlow.Lines.Add('# REFUND GIVEN- OH WELL!');
      refundResponse := ComWrapper.RefundResponseInit(txFlowState.Response);
      frmActions.richEdtFlow.Lines.Add('# Response: ' +
			  refundResponse.GetResponseText);
      frmActions.richEdtFlow.Lines.Add('# RRN: ' + refundResponse.GetRRN);
      frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
        refundResponse.SchemeName);
      frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');

      if (not refundResponse.WasCustomerReceiptPrinted) then
      begin
        frmMain.richEdtReceipt.Lines.Add
			    (TrimLeft(refundResponse.GetCustomerReceipt));
      end
      else
      begin
        frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
      end;

      frmActions.richEdtFlow.Lines.Add('# REFUNDED AMOUNT: ' +
        IntToStr(refundResponse.GetRefundAmount));
	  end;

    SuccessState_Failed:
	  begin
      frmActions.richEdtFlow.Lines.Add('# REFUND FAILED!');
      frmActions.richEdtFlow.Lines.Add('# Error: ' +
			    txFlowState.Response.GetError);
      frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
			    txFlowState.Response.GetErrorDetail);

      if (txFlowState.Response <> nil) then
      begin
        refundResponse := ComWrapper.RefundResponseInit (
          txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add('# Response: ' +
			    refundResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# RRN: ' + refundResponse.GetRRN);
        frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
          refundResponse.SchemeName);
        frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');

        if (not refundResponse.WasCustomerReceiptPrinted) then
        begin
          frmMain.richEdtReceipt.Lines.Add
			      (TrimLeft(refundResponse.GetCustomerReceipt));
        end
        else
        begin
          frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
        end;
      end;
    end;

    SuccessState_Unknown:
	  begin
      frmActions.richEdtFlow.Lines.Add('# WE''RE NOT QUITE SURE WHETHER THE REFUND WENT THROUGH OR NOT :/');
      frmActions.richEdtFlow.Lines.Add('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
      frmActions.richEdtFlow.Lines.Add('# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
    end;

    else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure HandleFinishedPurchase(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  purchaseResponse: SPIClient_TLB.PurchaseResponse;
begin
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.PurchaseResponse;

  case txFlowState.Success  of
    SuccessState_Success:
	  begin
      frmActions.richEdtFlow.Lines.Add('# WOOHOO - WE GOT PAID!');
      purchaseResponse := ComWrapper.PurchaseResponseInit(txFlowState.Response);
      frmActions.richEdtFlow.Lines.Add('# Response: ' +
			  purchaseResponse.GetResponseText);
      frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
      frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
        purchaseResponse.SchemeName);
      frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');

      if (not purchaseResponse.WasCustomerReceiptPrinted) then
      begin
        frmMain.richEdtReceipt.Lines.Add
			    (TrimLeft(purchaseResponse.GetCustomerReceipt));
      end
      else
      begin
        frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
      end;

      frmActions.richEdtFlow.Lines.Add('# PURCHASE: ' +
        IntToStr(purchaseResponse.GetPurchaseAmount));
      frmActions.richEdtFlow.Lines.Add('# TIP: ' +
        IntToStr(purchaseResponse.GetTipAmount));
      frmActions.richEdtFlow.Lines.Add('# CASHOUT: ' +
        IntToStr(purchaseResponse.GetCashoutAmount));
      frmActions.richEdtFlow.Lines.Add('# BANKED NON-CASH AMOUNT: ' +
        IntToStr(purchaseResponse.GetBankNonCashAmount));
      frmActions.richEdtFlow.Lines.Add('# BANKED CASH AMOUNT: ' +
        IntToStr(purchaseResponse.GetBankCashAmount));
	  end;

    SuccessState_Failed:
	  begin
      frmActions.richEdtFlow.Lines.Add('# WE DID NOT GET PAID :(');
      frmActions.richEdtFlow.Lines.Add('# Error: ' +
			    txFlowState.Response.GetError);
      frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
			    txFlowState.Response.GetErrorDetail);

      if (txFlowState.Response <> nil) then
      begin
        purchaseResponse := ComWrapper.PurchaseResponseInit(
          txFlowState.Response);
        frmActions.richEdtFlow.Lines.Add('# Response: ' +
			    purchaseResponse.GetResponseText);
        frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN);
        frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
          purchaseResponse.SchemeName);
        frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');

        if (not purchaseResponse.WasCustomerReceiptPrinted) then
        begin
          frmMain.richEdtReceipt.Lines.Add
			      (TrimLeft(purchaseResponse.GetCustomerReceipt));
        end
        else
        begin
          frmActions.richEdtFlow.Lines.Add('# PRINTED FROM EFTPOS');
        end;
      end;
    end;

    SuccessState_Unknown:
	  begin
      frmActions.richEdtFlow.Lines.Add('# WE''RE NOT QUITE SURE WHETHER WE GOT PAID OR NOT :/');
      frmActions.richEdtFlow.Lines.Add('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
      frmActions.richEdtFlow.Lines.Add('# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.');
      frmActions.richEdtFlow.Lines.Add('# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.');
    end;

    else
    begin
      raise Exception.Create('Argument Out Of Range Exception');
    end;
  end;
end;

procedure PrintFlowInfo;
var
  txFlowState: SPIClient_TLB.TransactionFlowState;
begin
  case Spi.CurrentFlow of
    SpiFlow_Pairing:
    begin
      frmActions.lblFlowMessage.Caption := spi.CurrentPairingFlowState.Message;
      frmActions.richEdtFlow.Lines.Add('### PAIRING PROCESS UPDATE ###');
      frmActions.richEdtFlow.Lines.Add('# ' +
        spi.CurrentPairingFlowState.Message);
      frmActions.richEdtFlow.Lines.Add('# Finished? ' +
        BoolToStr(spi.CurrentPairingFlowState.Finished));
      frmActions.richEdtFlow.Lines.Add('# Successful? ' +
        BoolToStr(spi.CurrentPairingFlowState.Successful));
      frmActions.richEdtFlow.Lines.Add('# Confirmation Code: ' +
        spi.CurrentPairingFlowState.ConfirmationCode);
      frmActions.richEdtFlow.Lines.Add('# Waiting Confirm from Eftpos? ' +
        BoolToStr(spi.CurrentPairingFlowState.AwaitingCheckFromEftpos));
      frmActions.richEdtFlow.Lines.Add('# Waiting Confirm from POS? ' +
        BoolToStr(spi.CurrentPairingFlowState.AwaitingCheckFromPos));
    end;

    SpiFlow_Transaction:
    begin
      txFlowState := spi.CurrentTxFlowState;
      frmActions.lblFlowMessage.Caption :=
        spi.CurrentTxFlowState.DisplayMessage;
      frmActions.richEdtFlow.Lines.Add('### TX PROCESS UPDATE ###');
      frmActions.richEdtFlow.Lines.Add('# ' +
        spi.CurrentTxFlowState.DisplayMessage);
      frmActions.richEdtFlow.Lines.Add('# Id: ' + txFlowState.PosRefId);
      frmActions.richEdtFlow.Lines.Add('# Type: ' +
        ComWrapper.GetTransactionTypeEnumName(txFlowState.type_));
      frmActions.richEdtFlow.Lines.Add('# Amount: ' +
        inttostr(txFlowState.amountCents div 100));
      frmActions.richEdtFlow.Lines.Add('# WaitingForSignature: ' +
        BoolToStr(txFlowState.AwaitingSignatureCheck));
      frmActions.richEdtFlow.Lines.Add('# Attempting to Cancel : ' +
        BoolToStr(txFlowState.AttemptingToCancel));
      frmActions.richEdtFlow.Lines.Add('# Finished: ' +
        BoolToStr(txFlowState.Finished));
      frmActions.richEdtFlow.Lines.Add('# Success: ' +
        ComWrapper.GetSuccessStateEnumName(txFlowState.Success));

      if (txFlowState.AwaitingSignatureCheck) then
      begin
        //We need to print the receipt for the customer to sign.
        frmActions.richEdtFlow.Lines.Add('# RECEIPT TO PRINT FOR SIGNATURE');
        frmMain.richEdtReceipt.Lines.Add
          (TrimLeft(txFlowState.SignatureRequiredMessage.GetMerchantReceipt));
      end;

      if (txFlowState.AwaitingPhoneForAuth) then
      begin
        //We need to print the receipt for the customer to sign.
        frmActions.richEdtFlow.Lines.Add('# RECEIPT TO PRINT FOR SIGNATURE');
        frmMain.richEdtReceipt.Lines.Add('# CALL: ' +
          txFlowState.PhoneForAuthRequiredMessage.GetPhoneNumber);
        frmMain.richEdtReceipt.Lines.Add('# QUOTE: Merchant Id: ' +
          txFlowState.PhoneForAuthRequiredMessage.GetMerchantId);
      end;

      //If the transaction is finished, we take some extra steps.
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
              ComWrapper.GetTransactionTypeEnumName(txFlowState.type_));
          end;
        end;
		  end;
    end;

    SpiFlow_Idle:
  end;

  frmActions.richEdtFlow.Lines.Add(
    '# --------------- STATUS ------------------');
  frmActions.richEdtFlow.Lines.Add(
    '# ' + _posId + ' <-> Eftpos: ' + _eftposAddress + ' #');
  frmActions.richEdtFlow.Lines.Add(
    '# SPI STATUS: ' + ComWrapper.GetSpiStatusEnumName(Spi.CurrentStatus) +
    '     FLOW:' + ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow) + ' #');
  frmActions.richEdtFlow.Lines.Add(
    '# -----------------------------------------');
  frmActions.richEdtFlow.Lines.Add(
    '# POS: v' + ComWrapper.GetPosVersion + ' Spi: v' +
    ComWrapper.GetSpiVersion);
end;

procedure PrintStatusAndActions();
begin
  frmMain.lblStatus.Caption := ComWrapper.GetSpiStatusEnumName
    (Spi.CurrentStatus) + ':' + ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow);

  case Spi.CurrentStatus of
    SpiStatus_Unpaired:
      case Spi.CurrentFlow of
        SpiFlow_Idle:
          begin
            if Assigned(frmActions) then
            begin
              frmActions.lblFlowMessage.Caption := 'Unpaired';
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := 'OK-Unpaired';
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              frmActions.lblAmount.Visible := False;
              frmActions.lblTipAmount.Visible := False;
              frmActions.lblCashoutAmount.Visible := False;
              frmActions.lblPrompt.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.edtTipAmount.Visible := False;
              frmActions.edtCashoutAmount.Visible := False;
              frmActions.radioPrompt.Visible := False;
              exit;
            end;
          end;
        SpiFlow_Pairing:
          begin
            if (Spi.CurrentPairingFlowState.AwaitingCheckFromPos) then
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := 'Confirm Code';
              frmActions.btnAction2.Visible := True;
              frmActions.btnAction2.Caption := 'Cancel Pairing';
              frmActions.btnAction3.Visible := False;
              frmActions.lblAmount.Visible := False;
              frmActions.lblTipAmount.Visible := False;
              frmActions.lblCashoutAmount.Visible := False;
              frmActions.lblPrompt.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.edtTipAmount.Visible := False;
              frmActions.edtCashoutAmount.Visible := False;
              frmActions.radioPrompt.Visible := False;
              exit;
            end
            else if (not Spi.CurrentPairingFlowState.Finished) then
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := 'Cancel Pairing';
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              frmActions.lblAmount.Visible := False;
              frmActions.lblTipAmount.Visible := False;
              frmActions.lblCashoutAmount.Visible := False;
              frmActions.lblPrompt.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.edtTipAmount.Visible := False;
              frmActions.edtCashoutAmount.Visible := False;
              frmActions.radioPrompt.Visible := False;
              exit;
            end
            else
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := 'OK';
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              frmActions.lblAmount.Visible := False;
              frmActions.lblTipAmount.Visible := False;
              frmActions.lblCashoutAmount.Visible := False;
              frmActions.lblPrompt.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.edtTipAmount.Visible := False;
              frmActions.edtCashoutAmount.Visible := False;
              frmActions.radioPrompt.Visible := False;
            end;
          end;

        SpiFlow_Transaction:
          begin
            exit;
          end;

        else
        begin
          frmActions.btnAction1.Visible := True;
          frmActions.btnAction1.Caption := 'OK';
          frmActions.btnAction2.Visible := False;
          frmActions.btnAction3.Visible := False;
          frmActions.lblAmount.Visible := False;
          frmActions.lblTipAmount.Visible := False;
          frmActions.lblCashoutAmount.Visible := False;
          frmActions.lblPrompt.Visible := False;
          frmActions.edtAmount.Visible := False;
          frmActions.edtTipAmount.Visible := False;
          frmActions.edtCashoutAmount.Visible := False;
          frmActions.radioPrompt.Visible := False;
          frmActions.richEdtFlow.Lines.Clear;
          frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
            ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow));
          exit;
        end;
      end;

    SpiStatus_PairedConnecting:
      case Spi.CurrentFlow of
        SpiFlow_Idle:
        begin
          frmMain.btnPair.Caption := 'UnPair';
          frmMain.pnlTransActions.Visible := True;
          frmMain.pnlOtherActions.Visible := True;
          frmMain.lblStatus.Color := clGreen;
          frmActions.lblFlowMessage.Caption := '# --> SPI Status Changed: ' +
            ComWrapper.GetSpiStatusEnumName(spi.CurrentStatus);
          frmActions.btnAction1.Visible := True;
          frmActions.btnAction1.Caption := 'OK';
          frmActions.btnAction2.Visible := False;
          frmActions.btnAction3.Visible := False;
          frmActions.lblAmount.Visible := False;
          frmActions.lblTipAmount.Visible := False;
          frmActions.lblCashoutAmount.Visible := False;
          frmActions.lblPrompt.Visible := False;
          frmActions.edtAmount.Visible := False;
          frmActions.edtTipAmount.Visible := False;
          frmActions.edtCashoutAmount.Visible := False;
          frmActions.radioPrompt.Visible := False;
          exit;
        end;

        SpiFlow_Transaction:
        begin
          if (Spi.CurrentTxFlowState.AwaitingSignatureCheck) then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'Accept Signature';
            frmActions.btnAction2.Visible := True;
            frmActions.btnAction2.Caption := 'Decline Signature';
            frmActions.btnAction3.Visible := True;
            frmActions.btnAction3.Caption := 'Cancel';
            frmActions.lblAmount.Visible := False;
            frmActions.lblTipAmount.Visible := False;
            frmActions.lblCashoutAmount.Visible := False;
            frmActions.lblPrompt.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtTipAmount.Visible := False;
            frmActions.edtCashoutAmount.Visible := False;
            frmActions.radioPrompt.Visible := False;
            exit;
          end
          else if (not Spi.CurrentTxFlowState.Finished) then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'Cancel';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.lblTipAmount.Visible := False;
            frmActions.lblCashoutAmount.Visible := False;
            frmActions.lblPrompt.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtTipAmount.Visible := False;
            frmActions.edtCashoutAmount.Visible := False;
            frmActions.radioPrompt.Visible := False;
            exit;
          end
          else
          begin
            case Spi.CurrentTxFlowState.Success of
              SuccessState_Success:
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'OK';
                frmActions.btnAction2.Visible := False;
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.lblTipAmount.Visible := False;
                frmActions.lblCashoutAmount.Visible := False;
                frmActions.lblPrompt.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtTipAmount.Visible := False;
                frmActions.edtCashoutAmount.Visible := False;
                frmActions.radioPrompt.Visible := False;
                exit;
              end;

              SuccessState_Failed:
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'Retry';
                frmActions.btnAction2.Visible := True;
                frmActions.btnAction2.Caption := 'Cancel';
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.lblTipAmount.Visible := False;
                frmActions.lblCashoutAmount.Visible := False;
                frmActions.lblPrompt.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtTipAmount.Visible := False;
                frmActions.edtCashoutAmount.Visible := False;
                frmActions.radioPrompt.Visible := False;
                exit;
              end;
              else
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'OK';
                frmActions.btnAction2.Visible := False;
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.lblTipAmount.Visible := False;
                frmActions.lblCashoutAmount.Visible := False;
                frmActions.lblPrompt.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtTipAmount.Visible := False;
                frmActions.edtCashoutAmount.Visible := False;
                frmActions.radioPrompt.Visible := False;
                exit;
              end;
            end;
          end;
        end;

        SpiFlow_Pairing:
        begin
          frmActions.btnAction1.Visible := True;
          frmActions.btnAction1.Caption := 'OK';
          frmActions.btnAction2.Visible := False;
          frmActions.btnAction3.Visible := False;
          frmActions.lblAmount.Visible := False;
          frmActions.lblTipAmount.Visible := False;
          frmActions.lblCashoutAmount.Visible := False;
          frmActions.lblPrompt.Visible := False;
          frmActions.edtAmount.Visible := False;
          frmActions.edtTipAmount.Visible := False;
          frmActions.edtCashoutAmount.Visible := False;
          frmActions.radioPrompt.Visible := False;
          exit;
        end;

      else
        frmActions.btnAction1.Visible := True;
        frmActions.btnAction1.Caption := 'OK';
        frmActions.btnAction2.Visible := False;
        frmActions.btnAction3.Visible := False;
        frmActions.lblAmount.Visible := False;
        frmActions.lblTipAmount.Visible := False;
        frmActions.lblCashoutAmount.Visible := False;
        frmActions.lblPrompt.Visible := False;
        frmActions.edtAmount.Visible := False;
        frmActions.edtTipAmount.Visible := False;
        frmActions.edtCashoutAmount.Visible := False;
        frmActions.radioPrompt.Visible := False;
        frmActions.richEdtFlow.Lines.Clear;
        frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
          ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow));
        exit;
      end;

    SpiStatus_PairedConnected:
      case Spi.CurrentFlow of
        SpiFlow_Idle:
        begin
          frmMain.btnPair.Caption := 'UnPair';
          frmMain.pnlTransActions.Visible := True;
          frmMain.pnlOtherActions.Visible := True;
          frmMain.lblStatus.Color := clGreen;

          if (frmActions.btnAction1.Caption = 'Retry') then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'OK';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.lblTipAmount.Visible := False;
            frmActions.lblCashoutAmount.Visible := False;
            frmActions.lblPrompt.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtTipAmount.Visible := False;
            frmActions.edtCashoutAmount.Visible := False;
            frmActions.radioPrompt.Visible := False;
          end;
          exit;
        end;

        SpiFlow_Transaction:
        begin
          if (Spi.CurrentTxFlowState.AwaitingSignatureCheck) then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'Accept Signature';
            frmActions.btnAction2.Visible := True;
            frmActions.btnAction2.Caption := 'Decline Signature';
            frmActions.btnAction3.Visible := True;
            frmActions.btnAction3.Caption := 'Cancel';
            frmActions.lblAmount.Visible := False;
            frmActions.lblTipAmount.Visible := False;
            frmActions.lblCashoutAmount.Visible := False;
            frmActions.lblPrompt.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtTipAmount.Visible := False;
            frmActions.edtCashoutAmount.Visible := False;
            frmActions.radioPrompt.Visible := False;
            exit;
          end
          else if (not Spi.CurrentTxFlowState.Finished) then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'Cancel';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.lblTipAmount.Visible := False;
            frmActions.lblCashoutAmount.Visible := False;
            frmActions.lblPrompt.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtTipAmount.Visible := False;
            frmActions.edtCashoutAmount.Visible := False;
            frmActions.radioPrompt.Visible := False;
            exit;
          end
          else
          begin
            case Spi.CurrentTxFlowState.Success of
              SuccessState_Success:
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'OK';
                frmActions.btnAction2.Visible := False;
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.lblTipAmount.Visible := False;
                frmActions.lblCashoutAmount.Visible := False;
                frmActions.lblPrompt.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtTipAmount.Visible := False;
                frmActions.edtCashoutAmount.Visible := False;
                frmActions.radioPrompt.Visible := False;
                exit;
              end;

              SuccessState_Failed:
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'Retry';
                frmActions.btnAction2.Visible := True;
                frmActions.btnAction2.Caption := 'Cancel';
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.lblTipAmount.Visible := False;
                frmActions.lblCashoutAmount.Visible := False;
                frmActions.lblPrompt.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtTipAmount.Visible := False;
                frmActions.edtCashoutAmount.Visible := False;
                frmActions.radioPrompt.Visible := False;
                exit;
              end;
              else
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'OK';
                frmActions.btnAction2.Visible := False;
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.lblTipAmount.Visible := False;
                frmActions.lblCashoutAmount.Visible := False;
                frmActions.lblPrompt.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtTipAmount.Visible := False;
                frmActions.edtCashoutAmount.Visible := False;
                frmActions.radioPrompt.Visible := False;
                exit;
              end;
            end;
          end;
        end;

        SpiFlow_Pairing:
        begin
          frmActions.btnAction1.Visible := True;
          frmActions.btnAction1.Caption := 'OK';
          frmActions.btnAction2.Visible := False;
          frmActions.btnAction3.Visible := False;
          frmActions.lblAmount.Visible := False;
          frmActions.lblTipAmount.Visible := False;
          frmActions.lblCashoutAmount.Visible := False;
          frmActions.lblPrompt.Visible := False;
          frmActions.edtAmount.Visible := False;
          frmActions.edtTipAmount.Visible := False;
          frmActions.edtCashoutAmount.Visible := False;
          frmActions.radioPrompt.Visible := False;
          exit;
        end;

      else
        frmActions.btnAction1.Visible := True;
        frmActions.btnAction1.Caption := 'OK';
        frmActions.btnAction2.Visible := False;
        frmActions.btnAction3.Visible := False;
        frmActions.lblAmount.Visible := False;
        frmActions.lblTipAmount.Visible := False;
        frmActions.lblCashoutAmount.Visible := False;
        frmActions.lblPrompt.Visible := False;
        frmActions.edtAmount.Visible := False;
        frmActions.edtTipAmount.Visible := False;
        frmActions.edtCashoutAmount.Visible := False;
        frmActions.radioPrompt.Visible := False;
        frmActions.richEdtFlow.Lines.Clear;
        frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
          ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow));
        exit;
      end;
  else
    frmActions.btnAction1.Visible := True;
    frmActions.btnAction1.Caption := 'OK';
    frmActions.btnAction2.Visible := False;
    frmActions.btnAction3.Visible := False;
    frmActions.lblAmount.Visible := False;
    frmActions.lblTipAmount.Visible := False;
    frmActions.lblCashoutAmount.Visible := False;
    frmActions.lblPrompt.Visible := False;
    frmActions.edtAmount.Visible := False;
    frmActions.edtTipAmount.Visible := False;
    frmActions.edtCashoutAmount.Visible := False;
    frmActions.radioPrompt.Visible := False;
    frmActions.richEdtFlow.Lines.Clear;
    frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
      ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow));
    exit;
  end;
end;

procedure TxFlowStateChanged(e: SPIClient_TLB.TransactionFlowState); stdcall;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
      frmMain.Enabled := False;
  end;

  frmActions.Show;
  PrintFlowInfo;
  TMyWorkerThread.Create(false);
end;

procedure PairingFlowStateChanged(e: SPIClient_TLB.PairingFlowState); stdcall;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := TfrmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption := e.Message;

  if (e.ConfirmationCode  <> '') then
  begin
    frmActions.richEdtFlow.Lines.Add('# Confirmation Code: ' +
      e.ConfirmationCode);
  end;

  PrintFlowInfo;
  TMyWorkerThread.Create(false);
end;

procedure SecretsChanged(e: SPIClient_TLB.Secrets); stdcall;
begin
  SpiSecrets := e;
end;

procedure SpiStatusChanged(e: SPIClient_TLB.SpiStatusEventArgs); stdcall;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := TfrmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption := 'It''s trying to connect';

  if (Spi.CurrentFlow = SpiFlow_Idle) then
    frmActions.richEdtFlow.Lines.Clear();

  PrintFlowInfo;
  TMyWorkerThread.Create(false);
end;

procedure TMyWorkerThread.Execute;
begin
  Synchronize(procedure begin
     PrintStatusAndActions;
  end
  );
end;

procedure Start;
begin
  LoadPersistedState;

  _posId := frmMain.edtPosID.Text;
  _eftposAddress := frmMain.edtEftposAddress.Text;

  Spi := ComWrapper.SpiInit(_posId, _eftposAddress, SpiSecrets);

  ComWrapper.Main(Spi, LongInt(@TxFlowStateChanged),
    LongInt(@PairingFlowStateChanged), LongInt(@SecretsChanged),
    LongInt(@SpiStatusChanged));

  Spi.Start;

  TMyWorkerThread.Create(false);
end;

procedure TfrmMain.btnPairClick(Sender: TObject);
begin
  if (btnPair.Caption = 'Pair') then
  begin
    Spi.Pair;
    btnSecrets.Visible := True;
    edtPosID.Enabled := False;
    edtEftposAddress.Enabled := False;
    frmMain.lblStatus.Color := clYellow;
  end
  else if (btnPair.Caption = 'UnPair') then
  begin
    Spi.Unpair;
    frmMain.btnPair.Caption := 'Pair';
    frmMain.pnlTransActions.Visible := False;
    frmMain.pnlOtherActions.Visible := False;
    edtSecrets.Text := '';
    lblStatus.Color := clRed;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (FormExists(frmActions)) then
  begin
    frmActions.Close;
  end;

  Action := caFree;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ComWrapper := CreateComObject(CLASS_ComWrapper) AS SPIClient_TLB.ComWrapper;
  Spi := CreateComObject(CLASS_Spi) AS SPIClient_TLB.Spi;
  SpiSecrets := CreateComObject(CLASS_Secrets) AS SPIClient_TLB.Secrets;
  SpiSecrets := nil;

  frmMain.edtPosID.Text := 'DELPHIPOS';
  lblStatus.Color := clRed;
end;

procedure TfrmMain.btnPurchaseClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption := 'Please enter the amount you would like to purchase for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Purchase';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.lblTipAmount.Visible := True;
  frmActions.lblCashoutAmount.Visible := True;
  frmActions.lblPrompt.Visible := True;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.edtTipAmount.Visible := True;
  frmActions.edtTipAmount.Text := '0';
  frmActions.edtCashoutAmount.Visible := True;
  frmActions.edtCashoutAmount.Text := '0';
  frmActions.radioPrompt.Visible := True;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnRefundClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption := 'Please enter the amount you would like to refund for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Refund';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.lblTipAmount.Visible := False;
  frmActions.lblCashoutAmount.Visible := False;
  frmActions.lblPrompt.Visible := False;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.edtTipAmount.Visible := False;
  frmActions.edtCashoutAmount.Visible := False;
  frmActions.radioPrompt.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnCashOutClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption := 'Please enter the amount you would like to cashout for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Cash Out';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.lblTipAmount.Visible := False;
  frmActions.lblCashoutAmount.Visible := False;
  frmActions.lblPrompt.Visible := False;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.edtTipAmount.Visible := False;
  frmActions.edtCashoutAmount.Visible := False;
  frmActions.radioPrompt.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnMotoClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption := 'Please enter the amount you would like to moto for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'MOTO';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.lblTipAmount.Visible := False;
  frmActions.lblCashoutAmount.Visible := False;
  frmActions.lblPrompt.Visible := False;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.edtTipAmount.Visible := False;
  frmActions.edtCashoutAmount.Visible := False;
  frmActions.radioPrompt.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  Start;

  btnSave.Enabled := False;
  if (edtPosID.Text = '') or (edtEftposAddress.Text = '') then
  begin
    showmessage('Please fill the parameters');
    exit;
  end;

  if (radioReceipt.ItemIndex = 0) then
  begin
    Spi.Config.PromptForCustomerCopyOnEftpos := True;
  end
  else
  begin
    Spi.Config.PromptForCustomerCopyOnEftpos := False;
  end;

  if (radioSign.ItemIndex = 0) then
  begin
    Spi.Config.SignatureFlowOnEftpos := True;
  end
  else
  begin
    Spi.Config.SignatureFlowOnEftpos := False;
  end;

  Spi.SetPosId(edtPosID.Text);
  Spi.SetEftposAddress(edtEftposAddress.Text);
  frmMain.pnlStatus.Visible := True;
end;

procedure TfrmMain.btnSecretsClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.richEdtFlow.Clear;

  if (SpiSecrets <> nil) then
  begin
    frmActions.richEdtFlow.Lines.Add('Pos Id: ' + _posId);
    frmActions.richEdtFlow.Lines.Add('Eftpos Address: ' + _eftposAddress);
    frmActions.richEdtFlow.Lines.Add('Secrets: ' + SpiSecrets.encKey + ':' +
      SpiSecrets.hmacKey);
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('I have no secrets!');
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'OK';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.lblTipAmount.Visible := False;
  frmActions.lblCashoutAmount.Visible := False;
  frmActions.lblPrompt.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.edtTipAmount.Visible := False;
  frmActions.edtCashoutAmount.Visible := False;
  frmActions.radioPrompt.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnSettleClick(Sender: TObject);
var
  settleres: SPIClient_TLB.InitiateTxResult;
  amount: Integer;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Cancel';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.lblTipAmount.Visible := False;
  frmActions.lblCashoutAmount.Visible := False;
  frmActions.lblPrompt.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.edtTipAmount.Visible := False;
  frmActions.edtCashoutAmount.Visible := False;
  frmActions.radioPrompt.Visible := False;
  frmMain.Enabled := False;

  settleres := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  settleres := Spi.InitiateSettleTx(ComWrapper.Get_Id('settle'));

  if (settleres.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Settle Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate settlement: ' +
      settleres.Message + '. Please Retry.');
  end;
end;

procedure TfrmMain.btnSettleEnqClick(Sender: TObject);
var
  senqres: SPIClient_TLB.InitiateTxResult;
  amount: Integer;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Cancel';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.lblTipAmount.Visible := False;
  frmActions.lblCashoutAmount.Visible := False;
  frmActions.lblPrompt.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.edtTipAmount.Visible := False;
  frmActions.edtCashoutAmount.Visible := False;
  frmActions.radioPrompt.Visible := False;
  frmMain.Enabled := False;

  senqres := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  senqres := Spi.InitiateSettlementEnquiry(ComWrapper.Get_Id('stlenq'));

  if (senqres.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Settle Enquiry Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate settlement enquiry: ' +
      senqres.Message + '. Please Retry.');
  end;
end;

procedure TfrmMain.btnLastTxClick(Sender: TObject);
var
  gltres: SPIClient_TLB.InitiateTxResult;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Cancel';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.lblTipAmount.Visible := False;
  frmActions.lblCashoutAmount.Visible := False;
  frmActions.lblPrompt.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.edtTipAmount.Visible := False;
  frmActions.edtCashoutAmount.Visible := False;
  frmActions.radioPrompt.Visible := False;
  frmMain.Enabled := False;

  gltres := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  gltres := Spi.InitiateGetLastTx;

  if (gltres.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# GLT Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate GLT: ' +
      gltres.Message + '. Please Retry.');
  end;
end;

procedure TfrmMain.btnRecoverClick(Sender: TObject);
var
  rres: SPIClient_TLB.InitiateTxResult;
  amount: Integer;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  if (edtReference.Text = '') then
  begin
    ShowMessage('Please enter refence!');
  end
  else
  begin
    frmActions.Show;
    frmActions.btnAction1.Visible := True;
    frmActions.btnAction1.Caption := 'Cancel';
    frmActions.btnAction2.Visible := False;
    frmActions.btnAction3.Visible := False;
    frmActions.lblAmount.Visible := True;
    frmActions.lblTipAmount.Visible := False;
    frmActions.lblCashoutAmount.Visible := False;
    frmActions.lblPrompt.Visible := False;
    frmActions.edtAmount.Visible := False;
    frmActions.edtTipAmount.Visible := False;
    frmActions.edtCashoutAmount.Visible := False;
    frmActions.radioPrompt.Visible := False;
    frmMain.Enabled := False;

    rres := CreateComObject(CLASS_InitiateTxResult)
      AS SPIClient_TLB.InitiateTxResult;

    rres := Spi.InitiateRecovery(edtReference.Text, TransactionType_Purchase);

    if (rres.Initiated) then
    begin
      frmActions.richEdtFlow.Lines.Add
        ('# Recovery Initiated. Will be updated with Progress.');
    end
    else
    begin
      frmActions.richEdtFlow.Lines.Add('# Could not initiate recovery: ' +
        rres.Message + '. Please Retry.');
    end;
  end;
end;

end.
