unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, System.Generics.Collections,
  ComObj, ActionsUnit, ActiveX, SPIClient_TLB, Vcl.Menus;

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
    btnRefund: TButton;
    pnlTableActions: TPanel;
    pnlOtherActions: TPanel;
    radioReceipt: TRadioGroup;
    radioSign: TRadioGroup;
    btnListTables: TButton;
    btnGetBill: TButton;
    procedure btnPairClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRefundClick(Sender: TObject);
    procedure btnSettleClick(Sender: TObject);
    procedure btnPurchaseClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnPrintBillClick(Sender: TObject);
    procedure btnListTablesClick(Sender: TObject);
    procedure btnGetBillClick(Sender: TObject);
  private

  public
    procedure DPrintStatusAndActions;
    procedure OpenTable;
    procedure CloseTable;
    procedure AddToTable;
    procedure PrintBill(billId: WideString);
    procedure GetBill;
  end;

type
  TMyWorkerThread = class(TThread)
  public
    procedure Execute; override;
  end;

type
  TBill = class(TObject)
    BillId: WideString;
    TableId: WideString;
    TotalAmount: Integer;
    OutstandingAmount: Integer;
    tippedAmount: Integer;
  end;

type
  TBillsStore = record
    BillId: string[255];
    Bill: TBill;
  end;

type
  TTableToBillMapping = record
    TableId: string[255];
    BillId: string[255];
  end;

type
  TAssemblyBillDataStore = record
    BillId: string[255];
    BillData: string[255];
  end;
var
  frmMain: TfrmMain;
  frmActions: TfrmActions;
  ComWrapper: SPIClient_TLB.ComWrapper;
  Spi: SPIClient_TLB.Spi;
  _posId, _eftposAddress, EncKey, HmacKey: WideString;
  SpiSecrets: SPIClient_TLB.Secrets;
  UseSynchronize, UseQueue, Init: Boolean;
  SpiPayAtTable: SPIClient_TLB.SpiPayAtTable;
  billsStoreDict: TDictionary<WideString, TBill>;
  tableToBillMappingDict: TDictionary<WideString, Widestring>;
  assemblyBillDataStoreDict: TDictionary<WideString, Widestring>;

implementation

{$R *.dfm}

function BillToString(newBill: TBill): WideString;
var
  totalAmount, outstandingAmount, tippedAmount: Single;
begin
  totalAmount :=  newBill.TotalAmount / 100;
  outstandingAmount := newBill.OutstandingAmount / 100;
  tippedAmount := newBill.tippedAmount / 100;

  Result := newBill.BillId + ' - Table:' + newBill.TableId + 'Total:$' +
    CurrToStr(totalAmount) + ' Outstanding:$' +
    CurrToStr(outstandingAmount) + ' Tips:$' + CurrToStr(tippedAmount);
end;

function FormExists(apForm: TForm): boolean;
var
  i: Word;
begin
  Result := False;
  for i := 0 to Screen.FormCount - 1 do
    if Screen.Forms[i] = apForm then
    begin
      Result := True;
      Break;
    end;
end;

procedure PersistState;
var
  billsStoreFile: File of TBillsStore;
  tableToBillMappingFile: File of TTableToBillMapping;
  assemblyBillDataStoreFile: File of TAssemblyBillDataStore;
  billRecord: TBillsStore;
  tableToBillMappingRecord: TTableToBillMapping;
  assemblyBillDataRecord: TAssemblyBillDataStore;
  billRecordItem: TPair<WideString, TBill>;
  tableToBillMappingRecordItem: TPair<WideString, WideString>;
  assemblyBillDataRecordItem: TPair<WideString, WideString>;
begin
  AssignFile(billsStoreFile, 'billsStore.bin');
  ReWrite(billsStoreFile);
  for billRecordItem in billsStoreDict do
  begin
    billRecord.BillId := billRecordItem.Key;
    billRecord.Bill := billRecordItem.Value;
    Write(billsStoreFile, billRecord);
  end;
  CloseFile(billsStoreFile);

  AssignFile(tableToBillMappingFile, 'tableToBillMapping.bin');
  ReWrite(tableToBillMappingFile);
  for tableToBillMappingRecordItem in tableToBillMappingDict do
  begin
    tableToBillMappingRecord.TableId := tableToBillMappingRecordItem.Key;
    tableToBillMappingRecord.BillId := tableToBillMappingRecordItem.Value;
    Write(tableToBillMappingFile, tableToBillMappingRecord);
  end;
  CloseFile(tableToBillMappingFile);

  AssignFile(assemblyBillDataStoreFile, 'assemblyBillDataStore.bin');
  ReWrite(assemblyBillDataStoreFile);
  for assemblyBillDataRecordItem in assemblyBillDataStoreDict do
  begin
    assemblyBillDataRecord.BillId := assemblyBillDataRecordItem.Key;
    assemblyBillDataRecord.BillData:= assemblyBillDataRecordItem.Value;
    Write(assemblyBillDataStoreFile, assemblyBillDataRecord);
  end;
  CloseFile(assemblyBillDataStoreFile);
end;

procedure LoadPersistedState;
var
  billsStoreFile: File of  TBillsStore;
  tableToBillMappingFile: File of TTableToBillMapping;
  assemblyBillDataStoreFile: File of TAssemblyBillDataStore;
  billsStore: TBillsStore;
  tableToBillMapping: TTableToBillMapping;
  assemblyBillDataStore: TAssemblyBillDataStore;
begin
  Init := False;
  _posId := 'DELPHIPOS';

  billsStoreDict := TDictionary<WideString, TBill>.Create;
  tableToBillMappingDict := TDictionary<WideString, WideString>.Create;
  assemblyBillDataStoreDict := TDictionary<WideString, WideString>.Create;

  frmMain.edtPosID.Text := _posId;
  frmMain.edtEftposAddress.Text := _eftposAddress;
  if (EncKey <> '') and (HmacKey <> '') then
  begin
    SpiSecrets := ComWrapper.SecretsInit(EncKey, HmacKey);
    Init := True;

    if (FileExists('tableToBillMapping.bin')) then
    begin
      AssignFile(billsStoreFile, 'billsStore.bin');
      FileMode := fmOpenRead;
      Reset(billsStoreFile);
      while not Eof(billsStoreFile) do
      begin
        Read(billsStoreFile, billsStore);
        billsStoreDict.Add(billsStore.BillId, billsStore.Bill);
      end;
      CloseFile(billsStoreFile);

      AssignFile(tableToBillMappingFile, 'tableToBillMapping.bin');
      FileMode := fmOpenRead;
      Reset(billsStoreFile);
      while not Eof(tableToBillMappingFile) do
      begin
        Read(tableToBillMappingFile, tableToBillMapping);
        tableToBillMappingDict.Add(tableToBillMapping.TableId,
          tableToBillMapping.BillId);
      end;
      CloseFile(tableToBillMappingFile);

      AssignFile(assemblyBillDataStoreFile, 'assemblyBillDataStore.bin');
      FileMode := fmOpenRead;
      Reset(billsStoreFile);
      while not Eof(assemblyBillDataStoreFile) do
      begin
        Read(assemblyBillDataStoreFile, assemblyBillDataStore);
        assemblyBillDataStoreDict.Add(assemblyBillDataStore.BillId,
          assemblyBillDataStore.BillData);
      end;
      CloseFile(assemblyBillDataStoreFile);
    end;
  end;
end;

procedure PrintFlowInfo(txFlowState: SPIClient_TLB.TransactionFlowState);
var
  purchaseResponse: SPIClient_TLB.PurchaseResponse;
  refundResponse: SPIClient_TLB.RefundResponse;
  settleResponse: SPIClient_TLB.Settlement;
  amountCents: Single;
begin
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.PurchaseResponse;
  refundResponse := CreateComObject(CLASS_RefundResponse)
    AS SPIClient_TLB.RefundResponse;
  settleResponse := CreateComObject(CLASS_Settlement)
    AS SPIClient_TLB.Settlement;

  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption := txFlowState.DisplayMessage;

  if (Spi.CurrentFlow = SpiFlow_Pairing) then
  begin
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

  if (Spi.CurrentFlow = SpiFlow_Transaction) then
  begin
    frmActions.richEdtFlow.Lines.Add('### TX PROCESS UPDATE ###');
    frmActions.richEdtFlow.Lines.Add('# ' + txFlowState.DisplayMessage);
    frmActions.richEdtFlow.Lines.Add('# Id: ' + txFlowState.PosRefId);
    frmActions.richEdtFlow.Lines.Add('# Type: ' +
      ComWrapper.GetTransactionTypeEnumName(txFlowState.type_));
    amountCents := txFlowState.amountCents / 100;
    frmActions.richEdtFlow.Lines.Add('# Request Amount: ' +
      CurrToStr(amountCents));
    frmActions.richEdtFlow.Lines.Add('# Waiting For Signature: ' +
      BoolToStr(txFlowState.AwaitingSignatureCheck));
    frmActions.richEdtFlow.Lines.Add('# Attempting to Cancel : ' +
      BoolToStr(txFlowState.AttemptingToCancel));
    frmActions.richEdtFlow.Lines.Add('# Finished: ' +
      BoolToStr(txFlowState.Finished));
    frmActions.richEdtFlow.Lines.Add('# Success: ' +
      ComWrapper.GetSuccessStateEnumName(txFlowState.Success));

    If (txFlowState.Finished) then
    begin
      case txFlowState.Success of
        SuccessState_Success:
        case txFlowState.type_ of
          TransactionType_Purchase:
          begin
            frmActions.richEdtFlow.Lines.Add('# WOOHOO - WE GOT PAID!');
            purchaseResponse := ComWrapper.PurchaseResponseInit(
              txFlowState.Response);
            frmActions.richEdtFlow.Lines.Add('# Response: ' +
              purchaseResponse.GetResponseText);
            frmActions.richEdtFlow.Lines.Add('# RRN: ' +
              purchaseResponse.GetRRN);
            frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
              purchaseResponse.SchemeName);
            frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
            frmMain.richEdtReceipt.Lines.Add
              (TrimLeft(purchaseResponse.GetCustomerReceipt));

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

          TransactionType_Refund:
          begin
            frmActions.richEdtFlow.Lines.Add('# REFUND GIVEN- OH WELL!');
            refundResponse := ComWrapper.RefundResponseInit(
              txFlowState.Response);
            frmActions.richEdtFlow.Lines.Add('# Response: ' +
              refundResponse.GetResponseText);
            frmActions.richEdtFlow.Lines.Add('# RRN: ' +
              refundResponse.GetRRN);
            frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
              refundResponse.SchemeName);
            frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
            frmMain.richEdtReceipt.Lines.Add
              (TrimLeft(refundResponse.GetCustomerReceipt));
          end;

          TransactionType_Settle:
          begin
            frmActions.richEdtFlow.Lines.Add('# SETTLEMENT SUCCESSFUL!');

            if (txFlowState.Response <> nil) then
            begin
              settleResponse := ComWrapper.SettlementInit(
                txFlowState.Response);
              frmActions.richEdtFlow.Lines.Add('# Response: ' +
                settleResponse.GetResponseText);
              frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
              frmMain.richEdtReceipt.Lines.Add
                (TrimLeft(settleResponse.GetReceipt));
            end;
          end;
        end;

        SuccessState_Failed:
        case txFlowState.type_ of
          TransactionType_Purchase:
          begin
            frmActions.richEdtFlow.Lines.Add('# WE DID NOT GET PAID :(');
            if (txFlowState.Response <> nil) then
            begin
              purchaseResponse := ComWrapper.PurchaseResponseInit(
                txFlowState.Response);
              frmActions.richEdtFlow.Lines.Add('# Error: ' +
                txFlowState.Response.GetError);
              frmActions.richEdtFlow.Lines.Add('# Response: ' +
                purchaseResponse.GetResponseText);
              frmActions.richEdtFlow.Lines.Add('# RRN: ' +
                purchaseResponse.GetRRN);
              frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
                purchaseResponse.SchemeName);
              frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
              frmMain.richEdtReceipt.Lines.Add
                (TrimLeft(purchaseResponse.GetCustomerReceipt));
            end;
          end;

          TransactionType_Refund:
          begin
            frmActions.richEdtFlow.Lines.Add('# REFUND FAILED!');
            if (txFlowState.Response <> nil) then
            begin
              frmActions.richEdtFlow.Lines.Add('# Error: ' +
                txFlowState.Response.GetError);
              refundResponse := ComWrapper.RefundResponseInit(
                txFlowState.Response);
              frmActions.richEdtFlow.Lines.Add('# Response: ' +
                refundResponse.GetResponseText);
              frmActions.richEdtFlow.Lines.Add('# RRN: ' +
                refundResponse.GetRRN);
              frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
                refundResponse.SchemeName);
              frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
              frmMain.richEdtReceipt.Lines.Add
                (TrimLeft(refundResponse.GetCustomerReceipt));
            end;
          end;

          TransactionType_Settle:
          begin
            frmActions.richEdtFlow.Lines.Add('# SETTLEMENT FAILED!');

            if (txFlowState.Response <> nil) then
            begin
              settleResponse := ComWrapper.SettlementInit(
                txFlowState.Response);
              frmActions.richEdtFlow.Lines.Add('# Response: ' +
                settleResponse.GetResponseText);
              frmActions.richEdtFlow.Lines.Add('# Error: ' +
                txFlowState.Response.GetError);
              frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
              frmMain.richEdtReceipt.Lines.Add(
                TrimLeft(settleResponse.GetReceipt));
            end;
          end;
        end;

        SuccessState_Unknown:
        case txFlowState.type_ of
          TransactionType_Purchase:
          begin
            frmActions.richEdtFlow.Lines.Add(
              '# WE''RE NOT QUITE SURE WHETHER WE GOT PAID OR NOT :/');
            frmActions.richEdtFlow.Lines.Add(
              '# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
            frmActions.richEdtFlow.Lines.Add(
              '# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.');
            frmActions.richEdtFlow.Lines.Add(
              '# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.');
          end;

          TransactionType_Refund:
          begin
            frmActions.richEdtFlow.Lines.Add(
              '# WE''RE NOT QUITE SURE WHETHER THE REFUND WENT THROUGH OR NOT :/');
            frmActions.richEdtFlow.Lines.Add(
              '# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
            frmActions.richEdtFlow.Lines.Add(
              '# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
          end;
        end;
      end;
    end;
  end;

  frmActions.richEdtFlow.Lines.Add(
    '# --------------- STATUS ------------------');
  frmActions.richEdtFlow.Lines.Add(
    '# ' + _posId + ' <-> Eftpos: ' + _eftposAddress + ' #');
  frmActions.richEdtFlow.Lines.Add(
    '# SPI STATUS: ' + ComWrapper.GetSpiStatusEnumName(Spi.CurrentStatus) +
    '     FLOW: ' + ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow) + ' #');
  frmActions.richEdtFlow.Lines.Add(
    '# ----------------TABLES-------------------');
  frmActions.richEdtFlow.Lines.Add(
    '#    Open Tables: ' + IntToStr(tableToBillMappingDict.Count));
  frmActions.richEdtFlow.Lines.Add(
    '# Bills in Store: ' + IntToStr(billsStoreDict.Count));
  frmActions.richEdtFlow.Lines.Add(
    '# Assembly Bills: ' + IntToStr(assemblyBillDataStoreDict.Count));
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
              frmActions.edtAmount.Visible := False;
              frmActions.lblTableId.Visible := False;
              frmActions.edtTableId.Visible := False;
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
              frmActions.edtAmount.Visible := False;
              frmActions.lblTableId.Visible := False;
              frmActions.edtTableId.Visible := False;
              exit;
            end
            else if (not Spi.CurrentPairingFlowState.Finished) then
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := 'Cancel Pairing';
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              frmActions.lblAmount.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.lblTableId.Visible := False;
              frmActions.edtTableId.Visible := False;
              exit;
            end
            else
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := 'OK';
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              frmActions.lblAmount.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.lblTableId.Visible := False;
              frmActions.edtTableId.Visible := False;
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
          frmActions.edtAmount.Visible := False;
          frmActions.lblTableId.Visible := False;
          frmActions.edtTableId.Visible := False;
          frmActions.richEdtFlow.Lines.Clear;
          frmActions.richEdtFlow.Lines.Add('# .. Unexpected Flow .. ' +
            ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow));
          exit;
        end;
      end;

    SpiStatus_PairedConnecting: exit;

    SpiStatus_PairedConnected:
      case Spi.CurrentFlow of
        SpiFlow_Idle:
        begin
          frmMain.btnPair.Caption := 'UnPair';
          frmMain.pnlTableActions.Visible := True;
          frmMain.pnlOtherActions.Visible := True;
          frmMain.lblStatus.Color := clGreen;

          if (frmActions.btnAction1.Caption = 'Retry') then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'OK';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.lblTableId.Visible := False;
            frmActions.edtTableId.Visible := False;
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
            frmActions.edtAmount.Visible := False;
            frmActions.lblTableId.Visible := False;
            frmActions.edtTableId.Visible := False;
            exit;
          end
          else if (not Spi.CurrentTxFlowState.Finished) then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'Cancel';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.lblTableId.Visible := False;
            frmActions.edtTableId.Visible := False;
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
                frmActions.edtAmount.Visible := False;
                frmActions.lblTableId.Visible := False;
                frmActions.edtTableId.Visible := False;
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
                frmActions.edtAmount.Visible := False;
                frmActions.lblTableId.Visible := False;
                frmActions.edtTableId.Visible := False;
                exit;
              end;
              else
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'OK';
                frmActions.btnAction2.Visible := False;
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.lblTableId.Visible := False;
                frmActions.edtTableId.Visible := False;
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
          frmActions.edtAmount.Visible := False;
          frmActions.lblTableId.Visible := False;
          frmActions.edtTableId.Visible := False;
          exit;
        end;

      else
        frmActions.btnAction1.Visible := True;
        frmActions.btnAction1.Caption := 'OK';
        frmActions.btnAction2.Visible := False;
        frmActions.btnAction3.Visible := False;
        frmActions.lblAmount.Visible := False;
        frmActions.edtAmount.Visible := False;
        frmActions.lblTableId.Visible := False;
        frmActions.edtTableId.Visible := False;
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
    frmActions.edtAmount.Visible := False;
    frmActions.lblTableId.Visible := False;
    frmActions.edtTableId.Visible := False;
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
  PrintFlowInfo(e);
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
    if (not Init) then
    begin
      frmActions := TfrmActions.Create(frmMain, Spi);
      frmActions.PopupParent := frmMain;
      frmMain.Enabled := False;
    end;
  end;

  if (not Init) then
  begin
    frmActions.Show;
    frmActions.lblFlowMessage.Caption := 'It''s trying to connect';

    if (Spi.CurrentFlow = SpiFlow_Idle) then
      frmActions.richEdtFlow.Lines.Clear();

    Init := False;
  end;

  TMyWorkerThread.Create(false);
end;

procedure TMyWorkerThread.Execute;
begin
  Synchronize(procedure begin
     PrintStatusAndActions;
  end
  );
end;

procedure PayAtTableGetBillDetails(billStatusInfo: SPIClient_TLB.BillStatusInfo;
  out billStatus: SPIClient_TLB.BillStatusResponse) stdcall;
var
  billData, billIdStr, tableIdStr, operatorIdStr: WideString;
  exit1: Boolean;
begin
  billStatus := CreateComObject(CLASS_BillStatusResponse)
    AS SPIClient_TLB.BillStatusResponse;

  exit1 := False;
  billIdStr := billStatusInfo.BillId;
  tableIdStr := billStatusInfo.TableId;
  operatorIdStr := billStatusInfo.OperatorId;

  if (billIdStr = '') then
  begin
    //We were not given a billId, just a tableId.
    //This means that we are being asked for the bill by its table number.

    //Let's see if we have it.
    if (not tableToBillMappingDict.ContainsKey(tableIdStr)) then
    begin
      //We didn't find a bill for this table.
      //We just tell the Eftpos that.
      billStatus.Result := BillRetrievalResult_INVALID_TABLE_ID;
      exit1 := True;
    end
    else
    begin
      //We have a billId for this Table.
      //et's set it so we can retrieve it.
      billIdStr := tableToBillMappingDict[tableIdStr];
    end;
  end;

  if (not exit1) then
  begin
    if (not billsStoreDict.ContainsKey(billIdStr)) then
    begin
      //We could not find the billId that was asked for.
      //We just tell the Eftpos that.
      billStatus.Result := BillRetrievalResult_INVALID_BILL_ID;
    end
    else
    begin
      billStatus.Result := BillRetrievalResult_SUCCESS;
      billStatus.BillId := billIdStr;
      billStatus.TableId := tableIdStr;
      billStatus.TotalAmount := billsStoreDict[billIdStr].TotalAmount;
      billStatus.OutstandingAmount :=
        billsStoreDict[billIdStr].OutstandingAmount;

      assemblyBillDataStoreDict.TryGetValue(billIdStr, billData);
      billStatus.BillData := billData;
    end;
  end;
end;

procedure PayAtTableBillPaymentReceived(billPaymentInfo:
  SPIClient_TLB.BillPaymentInfo; out billStatus:
  SPIClient_TLB.BillStatusResponse) stdcall;
var
  updatedBillDataStr: WideString;
  billPayment: SPIClient_TLB.BillPayment;
  totalAmount, outstandingAmount, tippedAmount: Single;
begin
  billStatus := CreateComObject(CLASS_BillStatusResponse)
    AS SPIClient_TLB.BillStatusResponse;
  billPayment := CreateComObject(CLASS_BillPayment)
    AS SPIClient_TLB.BillPayment;
  billPayment := billPaymentInfo.BillPayment;
  updatedBillDataStr := billPaymentInfo.UpdatedBillData;

  if (not billsStoreDict.ContainsKey(billPayment.BillId)) then
  begin
    billStatus.Result := BillRetrievalResult_INVALID_BILL_ID;
  end
  else
  begin
    if (not Assigned(frmActions)) then
    begin
      if (not Init) then
      begin
        frmActions := TfrmActions.Create(frmMain, Spi);
        frmActions.PopupParent := frmMain;
        frmMain.Enabled := False;
      end;
    end;

    frmActions.richEdtFlow.Lines.Add('# Got a ' +
      ComWrapper.GetPaymentTypeEnumName(billPayment.PaymentType) +
      ' Payment against bill ' +  billPayment.BillId + ' for table ' +
      billPayment.TableId);

    billsStoreDict[billPayment.BillId].OutstandingAmount :=
      billsStoreDict[billPayment.BillId].OutstandingAmount -
        billPayment.PurchaseAmount;
    billsStoreDict[billPayment.BillId].tippedAmount :=
      billsStoreDict[billPayment.BillId].tippedAmount + billPayment.TipAmount;

    totalAmount := billsStoreDict[billPayment.BillId].TotalAmount / 100;
    outstandingAmount :=
      billsStoreDict[billPayment.BillId].OutstandingAmount / 100;
    tippedAmount := billsStoreDict[billPayment.BillId].tippedAmount / 100;

    frmActions.richEdtFlow.Lines.Add('Updated Bill: ' +
      billsStoreDict[billPayment.BillId].BillId + ' - Table:$' +
      billsStoreDict[billPayment.BillId].TableId + ' Total:$' +
      CurrToStr(totalAmount) + ' Outstanding:$' + CurrToStr(outstandingAmount) +
      ' Tips:$' + CurrToStr(tippedAmount));

    if(not assemblyBillDataStoreDict.ContainsKey(billPayment.BillId)) Then
    begin
      assemblyBillDataStoreDict.Add(billPayment.BillId, updatedBillDataStr);
    end
    else
    begin
      assemblyBillDataStoreDict[billPayment.BillId] := updatedBillDataStr;
    end;

    billStatus.Result := BillRetrievalResult_SUCCESS;
    billStatus.TotalAmount := billsStoreDict[billPayment.BillId].TotalAmount;
    billStatus.OutstandingAmount :=
      billsStoreDict[billPayment.BillId].OutstandingAmount;

    frmActions.Show;
    frmActions.btnAction1.Visible := True;
    frmActions.btnAction1.Caption := 'OK';
    frmActions.btnAction2.Visible := False;
    frmActions.btnAction3.Visible := False;
    frmActions.lblAmount.Visible := False;
    frmActions.edtAmount.Visible := False;
    frmActions.lblTableId.Visible := False;
    frmActions.edtTableId.Visible := False;
    frmMain.Enabled := False;
  end;
end;

procedure Start;
begin
  ComWrapper := CreateComObject(CLASS_ComWrapper) AS SPIClient_TLB.ComWrapper;
  Spi := CreateComObject(CLASS_Spi) AS SPIClient_TLB.Spi;
  SpiSecrets := CreateComObject(CLASS_Secrets) AS SPIClient_TLB.Secrets;
  SpiPayAtTable := CreateComObject(CLASS_SpiPayAtTable)
    AS SPIClient_TLB.SpiPayAtTable;
  SpiSecrets := nil;

  LoadPersistedState;

  Spi := ComWrapper.SpiInit(_posId, _eftposAddress, SpiSecrets);
  SpiPayAtTable := Spi.EnablePayAtTable;
  SpiPayAtTable.Config.LabelTableId := 'Table Number';

  ComWrapper.Main_2(Spi, SpiPayAtTable, LongInt(@TxFlowStateChanged),
    LongInt(@PairingFlowStateChanged), LongInt(@SecretsChanged),
    LongInt(@SpiStatusChanged), LongInt(@PayAtTableGetBillDetails),
    LongInt(@PayAtTableBillPaymentReceived));

  Spi.Start;

  TMyWorkerThread.Create(false);
end;

procedure TfrmMain.DPrintStatusAndActions;
begin
  TMyWorkerThread.Create(false);
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to open';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Open';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := True;
  frmActions.lblTableId.Caption := 'Table Id:';
  frmActions.edtTableId.Visible := True;
  frmActions.edtTableId.Text := '';
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to close';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Close';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := True;
  frmActions.lblTableId.Caption := 'Table Id:';
  frmActions.edtTableId.Visible := True;
  frmActions.edtTableId.Text := '';
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnGetBillClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to print bill';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Get Bill';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := True;
  frmActions.lblTableId.Caption := 'Table Id:';
  frmActions.edtTableId.Visible := True;
  frmActions.edtTableId.Text := '';
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnListTablesClick(Sender: TObject);
var
  i: Integer;
  openTables, openBills, openAssemblyBill: WideString;
  Key: WideString;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption := 'List of Tables';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'OK';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
  frmMain.Enabled := False;

  if (tableToBillMappingDict.Count > 0) then
  begin
    for Key in tableToBillMappingDict.Keys do
    begin
      if (openTables <> '') then
      begin
        openTables := opentables + ',';
      end;

      openTables := openTables + Key;
    end;
    frmActions.richEdtFlow.Lines.Add('#    Open Tables: ' + openTables);
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# No Open Tables.');
  end;

  if (billsStoreDict.Count > 0) then
  begin
    for Key in billsStoreDict.Keys do
    begin
      if (openBills <> '') then
      begin
        openBills := openBills + ',';
      end;

      openBills := openBills + Key;
    end;
    frmActions.richEdtFlow.Lines.Add('# My Bills Store: ' + openBills);
  end;

  if (assemblyBillDataStoreDict.Count > 0) then
  begin
    for Key in assemblyBillDataStoreDict.Keys do
    begin
      if (openAssemblyBill <> '') then
      begin
        openAssemblyBill := openAssemblyBill + ',';
      end;

      openAssemblyBill := openAssemblyBill + Key;
    end;
    frmActions.richEdtFlow.Lines.Add('# Assembly Bills Data: ' +
      openAssemblyBill);
  end;
end;

procedure TfrmMain.btnAddClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to add';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Add';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.edtAmount.Visible := True;
  frmActions.lblTableId.Visible := True;
  frmActions.lblTableId.Caption := 'Table Id:';
  frmActions.edtTableId.Text := '';
  frmActions.edtTableId.Visible := True;
  frmActions.edtTableId.Text := '';
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnPrintBillClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    'Please enter the bill id you would like to print bill for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Print Bill';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := True;
  frmActions.lblTableId.Caption := 'Bill Id:';
  frmActions.edtTableId.Visible := True;
  frmActions.edtTableId.Text := '';
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnPairClick(Sender: TObject);
begin
  if (btnPair.Caption = 'Pair') then
  begin
    if (edtPosID.Text = '') or (edtEftposAddress.Text = '') then
    begin
      showmessage('Please fill the parameters');
      exit;
    end;

    _posId := edtPosID.Text;
    _eftposAddress := edtEftposAddress.Text;
    Spi.SetPosId(_posId);
    Spi.SetEftposAddress(_eftposAddress);
    edtPosID.Enabled := False;
    edtEftposAddress.Enabled := False;
    frmMain.lblStatus.Color := clYellow;
    Spi.Pair;
  end
  else if (btnPair.Caption = 'UnPair') then
  begin
    frmMain.btnPair.Caption := 'Pair';
    frmMain.pnlTableActions.Visible := False;
    frmMain.pnlOtherActions.Visible := False;
    lblStatus.Color := clRed;
    Spi.Unpair;
  end;

  frmMain.btnPair.Enabled := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if (FormExists(frmActions)) then
  begin
    frmActions.Close;
  end;

  PersistState;
  Action := caFree;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  lblStatus.Color := clRed;
  Start;
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
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to purchase for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Purchase';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
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
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to refund for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Refund';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.edtAmount.Visible := True;
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnSettleClick(Sender: TObject);
var
  settleres: SPIClient_TLB.InitiateTxResult;
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear();
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Cancel';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
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

procedure TfrmMain.OpenTable;
var
  newBill: TBill;
  billId, tableId: WideString;
begin
  frmActions.richEdtFlow.Lines.Clear();
  tableId := frmActions.edtTableId.Text;
  if (tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    billId := tableToBillMappingDict[tableId];
    frmActions.richEdtFlow.Lines.Add('Table Already Open: ' +
      BillToString(billsStoreDict[billId]));
  end
  else
  begin
    newBill := TBill.Create;
    newBill.BillId := ComWrapper.NewBillId;
    newBill.TableId := frmActions.edtTableId.Text;
    billsStoreDict.Add(newBill.BillId, newBill);
    tableToBillMappingDict.Add(newBill.TableId, newBill.BillId);
    frmActions.richEdtFlow.Lines.Add('Opened: ' + BillToString(newBill));
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'OK';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.CloseTable;
var
  billId, tableId: WideString;
begin
  frmActions.richEdtFlow.Lines.Clear();
  tableId := frmActions.edtTableId.Text;
  if (not tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Table not Open.');
  end
  else
  begin
    billId := tableToBillMappingDict[tableId];

    if (billsStoreDict[billId].OutstandingAmount > 0) then
    begin
      frmActions.richEdtFlow.Lines.Add('Bill not Paid Yet: ' +
        BillToString(billsStoreDict[billId]));
    end
    else
    begin
      tableToBillMappingDict.Remove(tableId);
      assemblyBillDataStoreDict.Remove(tableId);
      frmActions.richEdtFlow.Lines.Add('Closed: ' +
        BillToString(billsStoreDict[billId]));
    end;
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'OK';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.AddToTable;
var
  billId, tableId: WideString;
  amountCents: Integer;
begin
  frmActions.richEdtFlow.Lines.Clear();
  tableId := frmActions.edtTableId.Text;
  integer.TryParse(frmActions.edtAmount.Text, amountCents);
  if (not tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Table not Open.');
  end
  else
  begin
    billId := tableToBillMappingDict[tableId];
    billsStoreDict[billId].TotalAmount := billsStoreDict[billId].TotalAmount +
      amountCents;
    billsStoreDict[billId].OutstandingAmount :=
      billsStoreDict[billId].OutstandingAmount + amountCents;
    frmActions.richEdtFlow.Lines.Add('Updated: ' +
      BillToString(billsStoreDict[billId]));
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'OK';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.PrintBill(billId: WideString);
begin
  frmActions.richEdtFlow.Lines.Clear();
  if (billId = '') then
  begin
    billId := frmActions.edtTableId.Text;
  end;

  if (not billsStoreDict.ContainsKey(billId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Bill not Open.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('Bill: ' +
      BillToString(billsStoreDict[billId]));
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'OK';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.GetBill;
var
  tableId: WideString;
begin
  frmActions.richEdtFlow.Lines.Clear();
  tableId := frmActions.edtTableId.Text;
  if (not tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Table not Open.');
  end
  else
  begin
    PrintBill(tableToBillMappingDict[tableId]);
  end;

  frmActions.Show;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'OK';
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.lblTableId.Visible := False;
  frmActions.edtTableId.Visible := False;
  frmMain.Enabled := False;
end;

end.
