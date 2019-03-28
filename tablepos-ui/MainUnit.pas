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
    btnListTables: TButton;
    btnGetBill: TButton;
    btnSecrets: TButton;
    edtSecrets: TEdit;
    lblSecrets: TLabel;
    btnSave: TButton;
    pnlEftposSettings: TPanel;
    lblEftposSettings: TLabel;
    cboxReceiptFromEftpos: TCheckBox;
    cboxSignFromEftpos: TCheckBox;
    cboxPrintMerchantCopy: TCheckBox;
    btnLockTable: TButton;
    btnHeaderFooter: TButton;
    btnFreeformReceipt: TButton;
    btnTerminalStatus: TButton;
    btnTerminalSettings: TButton;
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
    procedure btnSecretsClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cboxReceiptFromEftposClick(Sender: TObject);
    procedure cboxSignFromEftposClick(Sender: TObject);
    procedure cboxPrintMerchantCopyClick(Sender: TObject);
    procedure btnTerminalStatusClick(Sender: TObject);
    procedure btnTerminalSettingsClick(Sender: TObject);
    procedure btnFreeformReceiptClick(Sender: TObject);
    procedure btnHeaderFooterClick(Sender: TObject);
    procedure btnLockTableClick(Sender: TObject);
  private

  public
    comWrapper: SPIClient_TLB.comWrapper;
    spi: SPIClient_TLB.spi;
    spiPayAtTable: SPIClient_TLB.spiPayAtTable;
    posId, eftposAddress, serialNumber: WideString;
    spiSecrets: SPIClient_TLB.Secrets;
    options: SPIClient_TLB.TransactionOptions;
    procedure OpenTable;
    procedure CloseTable;
    procedure AddToTable;
    procedure PrintBill(billId: WideString);
    procedure GetBill;
    procedure LockTable;
  end;

type
  TMyWorkerThread = class(TThread)
  public
    procedure Execute; override;
  end;

type
  TBill = class(TObject)
    billId: WideString;
    tableId: WideString;
    operatorId: WideString;
    tableLabel: WideString;
    totalAmount: Integer;
    outstandingAmount: Integer;
    tippedAmount: Integer;
    locked: Boolean;
  end;

type
  TBillsStore = record
    billId: string[255];
    Bill: TBill;
  end;

type
  TTableToBillMapping = record
    tableId: string[255];
    billId: string[255];
  end;

type
  TAssemblyBillDataStore = record
    billId: string[255];
    BillData: string[255];
  end;

var
  frmMain: TfrmMain;
  frmActions: TfrmActions;
  useSynchronize, useQueue: Boolean;
  billsStoreDict: TDictionary<WideString, TBill>;
  tableToBillMappingDict: TDictionary<WideString, WideString>;
  assemblyBillDataStoreDict: TDictionary<WideString, WideString>;
  delegationPointers: SPIClient_TLB.delegationPointers;

implementation

{$R *.dfm}

uses ComponentNames;

function BillToString(newBill: TBill): WideString;
var
  totalAmount, outstandingAmount, tippedAmount: Single;
begin
  totalAmount := newBill.totalAmount / 100;
  outstandingAmount := newBill.outstandingAmount / 100;
  tippedAmount := newBill.tippedAmount / 100;

  Result := newBill.billId + ' - Table:' + newBill.tableId + ' Oeprator Id:' +
    newBill.operatorId + ' Label:' + newBill.tableLabel + 'Total:$' +
    CurrToStr(totalAmount) + ' Outstanding:$' + CurrToStr(outstandingAmount) +
    ' Tips:$' + CurrToStr(tippedAmount) + ' Locked:' +
    BoolToStr(newBill.locked);
end;

procedure Split(Delimiter: Char; Str: string; ListOfStrings: TStrings);
begin
  ListOfStrings.Clear;
  ListOfStrings.Delimiter := Delimiter;
  ListOfStrings.StrictDelimiter := True; // Requires D2006 or newer.
  ListOfStrings.DelimitedText := Str;
end;

function FormExists(apForm: TForm): Boolean;
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
  if (billsStoreDict <> nil) Then
  begin
    AssignFile(billsStoreFile, 'billsStore.bin');
    ReWrite(billsStoreFile);
    for billRecordItem in billsStoreDict do
    begin
      billRecord.billId := ShortString(billRecordItem.Key);
      billRecord.Bill := billRecordItem.Value;
      Write(billsStoreFile, billRecord);
    end;
    CloseFile(billsStoreFile);

    AssignFile(tableToBillMappingFile, 'tableToBillMapping.bin');
    ReWrite(tableToBillMappingFile);
    for tableToBillMappingRecordItem in tableToBillMappingDict do
    begin
      tableToBillMappingRecord.tableId :=
        ShortString(tableToBillMappingRecordItem.Key);
      tableToBillMappingRecord.billId :=
        ShortString(tableToBillMappingRecordItem.Value);
      Write(tableToBillMappingFile, tableToBillMappingRecord);
    end;
    CloseFile(tableToBillMappingFile);

    AssignFile(assemblyBillDataStoreFile, 'assemblyBillDataStore.bin');
    ReWrite(assemblyBillDataStoreFile);
    for assemblyBillDataRecordItem in assemblyBillDataStoreDict do
    begin
      assemblyBillDataRecord.billId :=
        ShortString(assemblyBillDataRecordItem.Key);
      assemblyBillDataRecord.BillData :=
        ShortString(assemblyBillDataRecordItem.Value);
      Write(assemblyBillDataStoreFile, assemblyBillDataRecord);
    end;
    CloseFile(assemblyBillDataStoreFile);
  end;
end;

procedure LoadPersistedState;
var
  billsStoreFile: File of TBillsStore;
  tableToBillMappingFile: File of TTableToBillMapping;
  assemblyBillDataStoreFile: File of TAssemblyBillDataStore;
  billsStore: TBillsStore;
  tableToBillMapping: TTableToBillMapping;
  assemblyBillDataStore: TAssemblyBillDataStore;
  OutPutList: TStringList;
begin

  billsStoreDict := TDictionary<WideString, TBill>.Create;
  tableToBillMappingDict := TDictionary<WideString, WideString>.Create;
  assemblyBillDataStoreDict := TDictionary<WideString, WideString>.Create;

  if (frmMain.edtSecrets.Text <> '') then
  begin
    OutPutList := TStringList.Create;
    Split(':', frmMain.edtSecrets.Text, OutPutList);
    frmMain.spiSecrets := frmMain.comWrapper.SecretsInit(OutPutList[0],
      OutPutList[1]);

    if (FileExists('tableToBillMapping.bin')) then
    begin
      AssignFile(billsStoreFile, 'billsStore.bin');
      FileMode := fmOpenRead;
      Reset(billsStoreFile);
      while not Eof(billsStoreFile) do
      begin
        Read(billsStoreFile, billsStore);
        billsStoreDict.Add(WideString(billsStore.billId), billsStore.Bill);
      end;
      CloseFile(billsStoreFile);

      AssignFile(tableToBillMappingFile, 'tableToBillMapping.bin');
      FileMode := fmOpenRead;
      Reset(tableToBillMappingFile);
      while not Eof(tableToBillMappingFile) do
      begin
        Read(tableToBillMappingFile, tableToBillMapping);
        tableToBillMappingDict.Add(WideString(tableToBillMapping.tableId),
          WideString(tableToBillMapping.billId));
      end;
      CloseFile(tableToBillMappingFile);

      AssignFile(assemblyBillDataStoreFile, 'assemblyBillDataStore.bin');
      FileMode := fmOpenRead;
      Reset(assemblyBillDataStoreFile);
      while not Eof(assemblyBillDataStoreFile) do
      begin
        Read(assemblyBillDataStoreFile, assemblyBillDataStore);
        assemblyBillDataStoreDict.Add(WideString(assemblyBillDataStore.billId),
          WideString(assemblyBillDataStore.BillData));
      end;
      CloseFile(assemblyBillDataStoreFile);
    end;
  end;
end;

procedure SpiPrintFlowInfo;
var
  purchaseResponse: SPIClient_TLB.purchaseResponse;
  refundResponse: SPIClient_TLB.refundResponse;
  settleResponse: SPIClient_TLB.Settlement;
  amountCents: Single;
begin
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.purchaseResponse;
  refundResponse := CreateComObject(CLASS_RefundResponse)
    AS SPIClient_TLB.refundResponse;
  settleResponse := CreateComObject(CLASS_Settlement)
    AS SPIClient_TLB.Settlement;

  frmActions.richEdtFlow.Lines.Clear;

  if (frmMain.spi.CurrentFlow = SpiFlow_Pairing) then
  begin
    frmActions.lblFlowMessage.Caption :=
      frmMain.spi.CurrentPairingFlowState.Message;
    frmActions.richEdtFlow.Lines.Add('### PAIRING PROCESS UPDATE ###');
    frmActions.richEdtFlow.Lines.Add
      ('# ' + frmMain.spi.CurrentPairingFlowState.Message);
    frmActions.richEdtFlow.Lines.Add('# Finished? ' +
      BoolToStr(frmMain.spi.CurrentPairingFlowState.Finished));
    frmActions.richEdtFlow.Lines.Add('# Successful? ' +
      BoolToStr(frmMain.spi.CurrentPairingFlowState.Successful));
    frmActions.richEdtFlow.Lines.Add('# Confirmation Code: ' +
      frmMain.spi.CurrentPairingFlowState.ConfirmationCode);
    frmActions.richEdtFlow.Lines.Add('# Waiting Confirm from Eftpos? ' +
      BoolToStr(frmMain.spi.CurrentPairingFlowState.AwaitingCheckFromEftpos));
    frmActions.richEdtFlow.Lines.Add('# Waiting Confirm from POS? ' +
      BoolToStr(frmMain.spi.CurrentPairingFlowState.AwaitingCheckFromPos));
  end;

  if (frmMain.spi.CurrentFlow = SpiFlow_Transaction) then
  begin
    frmActions.lblFlowMessage.Caption :=
      frmMain.spi.CurrentTxFlowState.DisplayMessage;
    frmActions.richEdtFlow.Lines.Add('### TX PROCESS UPDATE ###');
    frmActions.richEdtFlow.Lines.Add
      ('# ' + frmMain.spi.CurrentTxFlowState.DisplayMessage);
    frmActions.richEdtFlow.Lines.Add
      ('# Id: ' + frmMain.spi.CurrentTxFlowState.PosRefId);
    frmActions.richEdtFlow.Lines.Add
      ('# Type: ' + frmMain.comWrapper.GetTransactionTypeEnumName
      (frmMain.spi.CurrentTxFlowState.type_));
    amountCents := frmMain.spi.CurrentTxFlowState.amountCents / 100;
    frmActions.richEdtFlow.Lines.Add('# Request Amount: ' +
      CurrToStr(amountCents));
    frmActions.richEdtFlow.Lines.Add('# Waiting For Signature: ' +
      BoolToStr(frmMain.spi.CurrentTxFlowState.AwaitingSignatureCheck));
    frmActions.richEdtFlow.Lines.Add('# Attempting to Cancel : ' +
      BoolToStr(frmMain.spi.CurrentTxFlowState.AttemptingToCancel));
    frmActions.richEdtFlow.Lines.Add('# Finished: ' +
      BoolToStr(frmMain.spi.CurrentTxFlowState.Finished));
    frmActions.richEdtFlow.Lines.Add('# Success: ' +
      frmMain.comWrapper.GetSuccessStateEnumName
      (frmMain.spi.CurrentTxFlowState.Success));

    If (frmMain.spi.CurrentTxFlowState.Finished) then
    begin
      case frmMain.spi.CurrentTxFlowState.Success of
        SuccessState_Success:
          case frmMain.spi.CurrentTxFlowState.type_ of
            TransactionType_Purchase:
              begin
                frmActions.richEdtFlow.Lines.Add('# WOOHOO - WE GOT PAID!');
                purchaseResponse := frmMain.comWrapper.PurchaseResponseInit
                  (frmMain.spi.CurrentTxFlowState.Response);
                frmActions.richEdtFlow.Lines.Add
                  ('# Response: ' + purchaseResponse.GetResponseText);
                frmActions.richEdtFlow.Lines.Add
                  ('# RRN: ' + purchaseResponse.GetRRN);
                frmActions.richEdtFlow.Lines.Add
                  ('# Scheme: ' + purchaseResponse.SchemeName);
                frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                frmMain.richEdtReceipt.Lines.Add
                  (TrimLeft(purchaseResponse.GetCustomerReceipt));

                frmActions.richEdtFlow.Lines.Add
                  ('# PURCHASE: ' +
                  IntToStr(purchaseResponse.GetPurchaseAmount));
                frmActions.richEdtFlow.Lines.Add
                  ('# TIP: ' + IntToStr(purchaseResponse.GetTipAmount));
                frmActions.richEdtFlow.Lines.Add
                  ('# CASHOUT: ' + IntToStr(purchaseResponse.GetCashoutAmount));
                frmActions.richEdtFlow.Lines.Add('# BANKED NON-CASH AMOUNT: ' +
                  IntToStr(purchaseResponse.GetBankNonCashAmount));
                frmActions.richEdtFlow.Lines.Add('# BANKED CASH AMOUNT: ' +
                  IntToStr(purchaseResponse.GetBankCashAmount));
              end;

            TransactionType_Refund:
              begin
                frmActions.richEdtFlow.Lines.Add('# REFUND GIVEN- OH WELL!');
                refundResponse := frmMain.comWrapper.RefundResponseInit
                  (frmMain.spi.CurrentTxFlowState.Response);
                frmActions.richEdtFlow.Lines.Add
                  ('# Response: ' + refundResponse.GetResponseText);
                frmActions.richEdtFlow.Lines.Add
                  ('# RRN: ' + refundResponse.GetRRN);
                frmActions.richEdtFlow.Lines.Add
                  ('# Scheme: ' + refundResponse.SchemeName);
                frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                frmMain.richEdtReceipt.Lines.Add
                  (TrimLeft(refundResponse.GetCustomerReceipt));
              end;

            TransactionType_Settle:
              begin
                frmActions.richEdtFlow.Lines.Add('# SETTLEMENT SUCCESSFUL!');

                if (frmMain.spi.CurrentTxFlowState.Response <> nil) then
                begin
                  settleResponse := frmMain.comWrapper.SettlementInit
                    (frmMain.spi.CurrentTxFlowState.Response);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Response: ' + settleResponse.GetResponseText);
                  frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
                  frmMain.richEdtReceipt.Lines.Add
                    (TrimLeft(settleResponse.GetReceipt));
                end;
              end;
          end;

        SuccessState_Failed:
          case frmMain.spi.CurrentTxFlowState.type_ of
            TransactionType_Purchase:
              begin
                frmActions.richEdtFlow.Lines.Add('# WE DID NOT GET PAID :(');
                if (frmMain.spi.CurrentTxFlowState.Response <> nil) then
                begin
                  purchaseResponse := frmMain.comWrapper.PurchaseResponseInit
                    (frmMain.spi.CurrentTxFlowState.Response);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Error: ' + frmMain.spi.CurrentTxFlowState.
                    Response.GetError);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Response: ' + purchaseResponse.GetResponseText);
                  frmActions.richEdtFlow.Lines.Add
                    ('# RRN: ' + purchaseResponse.GetRRN);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Scheme: ' + purchaseResponse.SchemeName);
                  frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                  frmMain.richEdtReceipt.Lines.Add
                    (TrimLeft(purchaseResponse.GetCustomerReceipt));
                end;
              end;

            TransactionType_Refund:
              begin
                frmActions.richEdtFlow.Lines.Add('# REFUND FAILED!');
                if (frmMain.spi.CurrentTxFlowState.Response <> nil) then
                begin
                  frmActions.richEdtFlow.Lines.Add
                    ('# Error: ' + frmMain.spi.CurrentTxFlowState.
                    Response.GetError);
                  refundResponse := frmMain.comWrapper.RefundResponseInit
                    (frmMain.spi.CurrentTxFlowState.Response);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Response: ' + refundResponse.GetResponseText);
                  frmActions.richEdtFlow.Lines.Add
                    ('# RRN: ' + refundResponse.GetRRN);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Scheme: ' + refundResponse.SchemeName);
                  frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                  frmMain.richEdtReceipt.Lines.Add
                    (TrimLeft(refundResponse.GetCustomerReceipt));
                end;
              end;

            TransactionType_Settle:
              begin
                frmActions.richEdtFlow.Lines.Add('# SETTLEMENT FAILED!');

                if (frmMain.spi.CurrentTxFlowState.Response <> nil) then
                begin
                  settleResponse := frmMain.comWrapper.SettlementInit
                    (frmMain.spi.CurrentTxFlowState.Response);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Response: ' + settleResponse.GetResponseText);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Error: ' + frmMain.spi.CurrentTxFlowState.
                    Response.GetError);
                  frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
                  frmMain.richEdtReceipt.Lines.Add
                    (TrimLeft(settleResponse.GetReceipt));
                end;
              end;
          end;

        SuccessState_Unknown:
          case frmMain.spi.CurrentTxFlowState.type_ of
            TransactionType_Purchase:
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

            TransactionType_Refund:
              begin
                frmActions.richEdtFlow.Lines.Add
                  ('# WE''RE NOT QUITE SURE WHETHER THE REFUND WENT THROUGH OR NOT :/');
                frmActions.richEdtFlow.Lines.Add
                  ('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
                frmActions.richEdtFlow.Lines.Add
                  ('# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
              end;
          end;
      end;
    end;
  end;

  frmActions.richEdtFlow.Lines.Add
    ('# --------------- STATUS ------------------');
  frmActions.richEdtFlow.Lines.Add('# ' + frmMain.posId + ' <-> Eftpos: ' +
    frmMain.eftposAddress + ' #');
  frmActions.richEdtFlow.Lines.Add('# SPI STATUS: ' +
    frmMain.comWrapper.GetSpiStatusEnumName(frmMain.spi.CurrentStatus) +
    '     FLOW: ' + frmMain.comWrapper.GetSpiFlowEnumName
    (frmMain.spi.CurrentFlow) + ' #');
  frmActions.richEdtFlow.Lines.Add
    ('# ----------------TABLES-------------------');
  frmActions.richEdtFlow.Lines.Add('# Open Tables: ' +
    IntToStr(tableToBillMappingDict.Count));
  frmActions.richEdtFlow.Lines.Add('# Bills in Store: ' +
    IntToStr(billsStoreDict.Count));
  frmActions.richEdtFlow.Lines.Add('# Assembly Bills: ' +
    IntToStr(assemblyBillDataStoreDict.Count));
  frmActions.richEdtFlow.Lines.Add
    ('# -----------------------------------------');
  frmActions.richEdtFlow.Lines.Add('# POS: v' + frmMain.comWrapper.GetPosVersion
    + ' Spi: v' + frmMain.comWrapper.GetSpiVersion);
end;

procedure GetUnvisibleActionComponents;
begin
  frmActions.btnAction1.Enabled := True;
  frmActions.lblAction1.Visible := False;
  frmActions.lblAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction1.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
end;

procedure GetOKActionComponents;
begin
  frmActions.btnAction1.Enabled := True;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.OK;
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  GetUnvisibleActionComponents;
end;

procedure SpiActions;
begin
  frmActions.lblFlowStatus.Caption := frmMain.comWrapper.GetSpiFlowEnumName
    (frmMain.spi.CurrentFlow);
  frmMain.lblStatus.Caption := frmMain.comWrapper.GetSpiStatusEnumName
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
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            GetUnvisibleActionComponents;
            frmMain.lblStatus.Color := clRed;
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
              frmActions.btnAction3.Visible := False;
              GetUnvisibleActionComponents;
              exit
            end
            else if (not frmMain.spi.CurrentPairingFlowState.Finished) then
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := ComponentNames.CANCELPAIRING;
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
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
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;;
            GetUnvisibleActionComponents;
            frmMain.lblStatus.Color := clRed;
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
            frmMain.btnPair.Caption := ComponentNames.UNPAIR;
            frmMain.pnlTableActions.Visible := True;
            frmMain.pnlEftposSettings.Visible := True;
            frmMain.pnlOtherActions.Visible := True;
            frmMain.lblStatus.Color := clYellow;
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
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              GetUnvisibleActionComponents;
              exit
            end
            else
            begin
              case frmMain.spi.CurrentTxFlowState.Success of
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
                    frmActions.btnAction3.Visible := False;
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
            frmMain.btnPair.Caption := ComponentNames.UNPAIR;
            frmMain.pnlTableActions.Visible := True;
            frmMain.pnlEftposSettings.Visible := True;
            frmMain.pnlOtherActions.Visible := True;
            frmMain.lblStatus.Color := clGreen;
            frmActions.lblFlowMessage.Caption := '# --> SPI Status Changed: ' +
              frmMain.comWrapper.GetSpiStatusEnumName
              (frmMain.spi.CurrentStatus);

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
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              GetUnvisibleActionComponents;
              exit
            end
            else
            begin
              case frmMain.spi.CurrentTxFlowState.Success of
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
                    frmActions.btnAction3.Visible := False;
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
  frmMain.lblStatus.Caption := frmMain.comWrapper.GetSpiStatusEnumName
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
  frmActions.Show;
  frmMain.Enabled := False;
  TMyWorkerThread.Create(False);
end;

procedure OnPairingFlowStateChanged(e: SPIClient_TLB.PairingFlowState); stdcall;
begin
  frmActions.Show;
  frmMain.Enabled := False;
  frmActions.lblFlowMessage.Caption := e.Message;

  if (e.ConfirmationCode <> '') then
  begin
    frmActions.richEdtFlow.Lines.Add('# Confirmation Code: ' +
      e.ConfirmationCode);
  end;

  TMyWorkerThread.Create(False);
end;

procedure OnSecretsChanged(e: SPIClient_TLB.Secrets); stdcall;
begin
  frmMain.spiSecrets := e;
  frmMain.btnSecretsClick(frmMain.btnSecrets);
end;

procedure OnSpiStatusChanged(e: SPIClient_TLB.SpiStatusEventArgs); stdcall;
begin
  frmActions.Show;
  frmMain.Enabled := False;
  frmActions.lblFlowMessage.Caption := 'It''s trying to connect';
  TMyWorkerThread.Create(False);
end;

procedure TMyWorkerThread.Execute;
begin
  Synchronize(
    procedure
    begin
      SpiStatusAndActions;
    end);
end;

procedure HandlePrintingResponse(msg: SPIClient_TLB.Message); stdcall;

var
  printingResponse: SPIClient_TLB.printingResponse;
begin
  printingResponse := CreateComObject(CLASS_PrintingResponse)
    AS SPIClient_TLB.printingResponse;

  frmActions.richEdtFlow.Lines.Clear;
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
  frmMain.Enabled := False;
  frmActions.Show;
end;

procedure HandleTerminalStatusResponse(msg: SPIClient_TLB.Message); stdcall;
var
  terminalStatusResponse: SPIClient_TLB.terminalStatusResponse;
begin
  terminalStatusResponse := CreateComObject(CLASS_TerminalStatusResponse)
    AS SPIClient_TLB.terminalStatusResponse;

  frmActions.richEdtFlow.Lines.Clear;
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

  frmActions.richEdtFlow.Lines.Clear;
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

    frmActions.richEdtFlow.Lines.Clear;
    frmActions.lblFlowMessage.Caption :=
      '# --> Terminal Status Response Successful';

    terminalBattery := frmMain.comWrapper.TerminalBatteryInit(msg);
    frmActions.richEdtFlow.Lines.Add('"# --> Battery Level Changed Successful');
    frmActions.richEdtFlow.Lines.Add('# Battery Level: ' +
      StringReplace(terminalBattery.BatteryLevel, 'd', '',
      [rfReplaceAll, rfIgnoreCase]) + '%');
    frmActions.richEdtFlow.Lines.Add('# Terminal Status Response #');

    frmMain.spi.AckFlowEndedAndBackToIdle;
    frmMain.Enabled := False;
    frmActions.Show;
  end;
end;

procedure PayAtTableGetBillDetails(billStatusRequest
  : SPIClient_TLB.billStatusRequest;
out billStatus: SPIClient_TLB.BillStatusResponse)stdcall;
var
  BillData, billIdStr, tableIdStr, operatorIdStr: WideString;
  paymentFlowStarted: Boolean;
begin
  billStatus := CreateComObject(CLASS_BillStatusResponse)
    AS SPIClient_TLB.BillStatusResponse;

  billIdStr := billStatusRequest.billId;
  tableIdStr := billStatusRequest.tableId;
  operatorIdStr := billStatusRequest.operatorId;
  paymentFlowStarted := billStatusRequest.paymentFlowStarted;

  if (billIdStr = '') then
  begin
    // We were not given a billId, just a tableId.
    // This means that we are being asked for the bill by its table number.

    // Let's see if we have it.
    if (not tableToBillMappingDict.ContainsKey(tableIdStr)) then
    begin
      // We didn't find a bill for this table.
      // We just tell the Eftpos that.
      billStatus.Result := BillRetrievalResult_INVALID_TABLE_ID;
      exit;
    end;

    // We have a billId for this Table.
    // et's set it so we can retrieve it.
    billIdStr := tableToBillMappingDict[tableIdStr];

  end;

  if (not billsStoreDict.ContainsKey(billIdStr)) then
  begin
    // We could not find the billId that was asked for.
    // We just tell the Eftpos that.
    billStatus.Result := BillRetrievalResult_INVALID_BILL_ID;
    exit;
  end;

  if (billsStoreDict[billIdStr].locked and paymentFlowStarted) then
  begin
    // We could not find the billId that was asked for.
    // We just tell the Eftpos that.
    ShowMessage('Table is Locked.');
    billStatus.Result := BillRetrievalResult_INVALID_TABLE_ID;
    exit;
  end;

  billsStoreDict[billIdStr].locked := paymentFlowStarted;

  billStatus.Result := BillRetrievalResult_SUCCESS;
  billStatus.billId := billIdStr;
  billStatus.tableId := tableIdStr;
  billStatus.operatorId := operatorIdStr;
  billStatus.totalAmount := billsStoreDict[billIdStr].totalAmount;
  billStatus.outstandingAmount := billsStoreDict[billIdStr].outstandingAmount;

  assemblyBillDataStoreDict.TryGetValue(billIdStr, BillData);
  billStatus.BillData := BillData;
end;

procedure PayAtTableBillPaymentReceived(billPaymentInfo
  : SPIClient_TLB.billPaymentInfo;
out billStatus: SPIClient_TLB.BillStatusResponse)stdcall;
var
  updatedBillDataStr: WideString;
  billPayment: SPIClient_TLB.billPayment;
begin
  billStatus := CreateComObject(CLASS_BillStatusResponse)
    AS SPIClient_TLB.BillStatusResponse;
  billPayment := CreateComObject(CLASS_BillPayment)
    AS SPIClient_TLB.billPayment;
  billPayment := billPaymentInfo.billPayment;
  updatedBillDataStr := billPaymentInfo.UpdatedBillData;

  frmActions.richEdtFlow.Lines.Clear;
  frmActions.richEdtFlow.Lines.Add('#');

  if (not billsStoreDict.ContainsKey(billPayment.billId)) then
  begin
    billStatus.Result := BillRetrievalResult_INVALID_BILL_ID;
    frmActions.richEdtFlow.Lines.Add('Incorrect Bill Id!');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Got a ' + frmMain.comWrapper.GetPaymentTypeEnumName
      (billPayment.PaymentType) + ' Payment against bill ' + billPayment.billId
      + ' for table ' + billPayment.tableId);

    billsStoreDict[billPayment.billId].outstandingAmount :=
      billsStoreDict[billPayment.billId].outstandingAmount -
      billPayment.PurchaseAmount;
    billsStoreDict[billPayment.billId].tippedAmount :=
      billsStoreDict[billPayment.billId].tippedAmount + billPayment.TipAmount;
    billsStoreDict[billPayment.billId].locked :=
      not(billsStoreDict[billPayment.billId].outstandingAmount = 0);

    frmActions.richEdtFlow.Lines.Add('Updated Bill: ' +
      BillToString(billsStoreDict[billPayment.billId]));

    if (not assemblyBillDataStoreDict.ContainsKey(billPayment.billId)) Then
    begin
      assemblyBillDataStoreDict.Add(billPayment.billId, updatedBillDataStr);
    end
    else
    begin
      assemblyBillDataStoreDict[billPayment.billId] := updatedBillDataStr;
    end;

    billStatus.Result := BillRetrievalResult_SUCCESS;
    billStatus.totalAmount := billsStoreDict[billPayment.billId].totalAmount;
    billStatus.outstandingAmount := billsStoreDict[billPayment.billId]
      .outstandingAmount;

    frmMain.Enabled := False;
    frmActions.Show;
    GetOKActionComponents;
  end;
end;

procedure PayAtTableBillPaymentFlowEnded(msg: SPIClient_TLB.Message)stdcall;
var
  billPaymentFlowEndedResponse: SPIClient_TLB.billPaymentFlowEndedResponse;
begin
  billPaymentFlowEndedResponse :=
    CreateComObject(CLASS_BillPaymentFlowEndedResponse)
    AS SPIClient_TLB.billPaymentFlowEndedResponse;
  billPaymentFlowEndedResponse :=
    frmMain.comWrapper.BillPaymentFlowEndedResponseInit(msg);

  frmActions.richEdtFlow.Lines.Clear;
  frmActions.richEdtFlow.Lines.Add('#');

  if (not billsStoreDict.ContainsKey(billPaymentFlowEndedResponse.billId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Incorrect Bill Id!');
  end
  else
  begin
    billsStoreDict[billPaymentFlowEndedResponse.billId].locked := False;

    frmActions.richEdtFlow.Lines.Add
      ('Bill Id: ' + billPaymentFlowEndedResponse.billId);
    frmActions.richEdtFlow.Lines.Add
      ('Table: ' + billPaymentFlowEndedResponse.tableId);
    frmActions.richEdtFlow.Lines.Add('Operator Id: ' +
      billPaymentFlowEndedResponse.operatorId);
    frmActions.richEdtFlow.Lines.Add('Bill Outstanding Amount: $' +
      CurrToStr(billPaymentFlowEndedResponse.BillOutstandingAmount));
    frmActions.richEdtFlow.Lines.Add('Bill Total Amount: $' +
      CurrToStr(billPaymentFlowEndedResponse.BillTotalAmount));
    frmActions.richEdtFlow.Lines.Add('Card Total Count: ' +
      CurrToStr(billPaymentFlowEndedResponse.CardTotalCount));
    frmActions.richEdtFlow.Lines.Add('Card Total Amount: $' +
      CurrToStr(billPaymentFlowEndedResponse.CardTotalAmount));
    frmActions.richEdtFlow.Lines.Add('Cash Total Count: $' +
      CurrToStr(billPaymentFlowEndedResponse.CashTotalCount));
    frmActions.richEdtFlow.Lines.Add('Cash Total Amount: $' +
      CurrToStr(billPaymentFlowEndedResponse.CashTotalAmount));
    frmActions.richEdtFlow.Lines.Add
      ('Locked: ' + BoolToStr(billsStoreDict
      [billPaymentFlowEndedResponse.billId].locked));
  end;

  frmMain.Enabled := False;
  frmActions.Show;
  GetOKActionComponents;
end;

procedure PayAtTableGetOpenTables(billStatusRequest
  : SPIClient_TLB.billStatusRequest;
out getOpenTablesResponse: SPIClient_TLB.getOpenTablesResponse)stdcall;
var
  isOpenTables: Boolean;
  tableToBillMappingRecordItem: TPair<WideString, WideString>;
  openTablesItem: SPIClient_TLB.OpenTablesEntry;
  operatorIdStr: WideString;
  getOpenTablesCom: SPIClient_TLB.getOpenTablesCom;
begin
  operatorIdStr := billStatusRequest.operatorId;
  isOpenTables := False;

  getOpenTablesResponse := CreateComObject(CLASS_GetOpenTablesResponse)
    AS SPIClient_TLB.getOpenTablesResponse;
  getOpenTablesCom := CreateComObject(CLASS_GetOpenTablesCom)
    AS SPIClient_TLB.getOpenTablesCom;

  frmActions.richEdtFlow.Lines.Clear;
  frmActions.richEdtFlow.Lines.Add('#');

  if (tableToBillMappingDict.Count > 0) then
  begin
    for tableToBillMappingRecordItem in tableToBillMappingDict do
    begin
      if (billsStoreDict[tableToBillMappingRecordItem.Value]
        .operatorId = operatorIdStr) and
        (billsStoreDict[tableToBillMappingRecordItem.Value]
        .outstandingAmount > 0) then
      begin
        if (not isOpenTables) then
        begin
          frmActions.richEdtFlow.Lines.Add('# Open Tables:');
          isOpenTables := True;
        end;

        openTablesItem := CreateComObject(CLASS_OpenTablesEntry)
          AS SPIClient_TLB.OpenTablesEntry;
        openTablesItem.tableId := tableToBillMappingRecordItem.Key;
        openTablesItem.Label_ := billsStoreDict
          [tableToBillMappingRecordItem.Value].tableLabel;
        openTablesItem.BillOutstandingAmount :=
          billsStoreDict[tableToBillMappingRecordItem.Value].outstandingAmount;

        frmActions.richEdtFlow.Lines.Add
          ('Table: ' + tableToBillMappingRecordItem.Key);
        frmActions.richEdtFlow.Lines.Add('Bill Id: ' + billsStoreDict
          [tableToBillMappingRecordItem.Value].billId);
        frmActions.richEdtFlow.Lines.Add('Bill Outstanding Amount: $' +
          CurrToStr(billsStoreDict[tableToBillMappingRecordItem.Value]
          .outstandingAmount));

        getOpenTablesCom.AddToOpenTablesList(openTablesItem);
      end;
    end;
  end;

  if (not isOpenTables) then
  begin
    frmActions.richEdtFlow.Lines.Add('# No Open Tables!');
  end;

  getOpenTablesResponse.tableData := getOpenTablesCom.ToOpenTablesJson;

  frmMain.Enabled := False;
  frmActions.Show;
  GetOKActionComponents;
end;

procedure Start;
begin
  LoadPersistedState;

  frmMain.posId := frmMain.edtPosID.Text;
  frmMain.eftposAddress := frmMain.edtEftposAddress.Text;
  frmMain.serialNumber := '';

  frmMain.spi := frmMain.comWrapper.SpiInit(frmMain.posId, frmMain.serialNumber,
    frmMain.eftposAddress, frmMain.spiSecrets);
  frmMain.spi.SetPosInfo('assembly', '2.5.0');

  frmMain.spiPayAtTable := frmMain.spi.EnablePayAtTable;
  frmMain.spiPayAtTable.Config.LabelTableId := 'Table Number';

  delegationPointers.CBTransactionStatePtr :=
    LongInt(@OnTransactionFlowStateChanged);
  delegationPointers.CBPairingFlowStatePtr :=
    LongInt(@OnPairingFlowStateChanged);
  delegationPointers.CBSecretsPtr := LongInt(@OnSecretsChanged);
  delegationPointers.CBStatusPtr := LongInt(@OnSpiStatusChanged);
  delegationPointers.CBPrintingResponsePtr := LongInt(@HandlePrintingResponse);
  delegationPointers.CBTerminalStatusResponsePtr :=
    LongInt(@HandleTerminalStatusResponse);
  delegationPointers.CBTerminalConfigurationResponsePtr :=
    LongInt(@HandleTerminalConfigurationResponse);
  delegationPointers.CBBatteryLevelChangedPtr :=
    LongInt(@HandleBatteryLevelChanged);

  delegationPointers.CBPayAtTableGetBillDetailsPtr :=
    LongInt(@PayAtTableGetBillDetails);
  delegationPointers.CBPayAtTableBillPaymentReceivedPtr :=
    LongInt(@PayAtTableBillPaymentReceived);
  delegationPointers.CBPayAtTableBillPaymentFlowEndedResponsePtr :=
    LongInt(@PayAtTableBillPaymentFlowEnded);
  delegationPointers.CBPayAtTableGetOpenTablesPtr :=
    LongInt(@PayAtTableGetOpenTables);

  frmMain.comWrapper.Main_2(frmMain.spi, frmMain.spiPayAtTable,
    delegationPointers);

  try
    frmMain.spi.Start;
  except
    on e: Exception do
    begin
      ShowMessage('SPI check failed: ' + e.Message +
        ', Please ensure you followed all the configuration steps on your machine');
    end;
  end;

  TMyWorkerThread.Create(False);
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to open';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.OPEN;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Table Id:';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := 'Operator Id:';
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '';
  frmActions.lblAction3.Visible := True;
  frmActions.lblAction3.Caption := 'Label:';
  frmActions.edtAction3.Visible := True;
  frmActions.edtAction3.Text := '';
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
  frmActions.Show;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to close';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Close';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Table Id:';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
  frmActions.Show;
end;

procedure TfrmMain.btnFreeformReceiptClick(Sender: TObject);
begin
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the receipt header and footer you would like to print';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.PRINT;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := ComponentNames.PRINTTEXT;
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := ComponentNames.Key;
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '';
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
  frmActions.Show;
end;

procedure TfrmMain.btnGetBillClick(Sender: TObject);
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to print bill';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Get Bill';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Table Id:';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnHeaderFooterClick(Sender: TObject);
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the receipt header and footer you would like to print';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.SETPRINT;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := ComponentNames.RECEIPTHEADER;
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := ComponentNames.RECEPTFOOTER;
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '';
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnListTablesClick(Sender: TObject);
var
  openTables, openBills, openAssemblyBill: WideString;
  Key: WideString;
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption := 'List of Tables';
  GetOKActionComponents;
  frmMain.Enabled := False;

  if (tableToBillMappingDict.Count > 0) then
  begin
    for Key in tableToBillMappingDict.Keys do
    begin
      if (openTables <> '') then
      begin
        openTables := openTables + ',';
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

procedure TfrmMain.btnLockTableClick(Sender: TObject);
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to lock/unlock table';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.SETLOCK;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Table Id:';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := True;
  frmActions.cboxAction1.Caption := 'Locked:';
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnAddClick(Sender: TObject);
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to add';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.Add;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Table Id:';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := 'Amount:';
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '0';
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnPrintBillClick(Sender: TObject);
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the bill id you would like to print bill for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.PrintBill;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Bill Id:';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnPairClick(Sender: TObject);
begin
  if (btnPair.Caption = ComponentNames.PAIR) then
  begin
    spi.PAIR;
    btnSecrets.Visible := True;
    edtPosID.Enabled := False;
    edtEftposAddress.Enabled := False;
    frmMain.lblStatus.Color := clYellow;
  end
  else if (btnPair.Caption = ComponentNames.UNPAIR) then
  begin
    spi.UNPAIR;
    frmMain.btnPair.Caption := ComponentNames.PAIR;
    frmMain.pnlTableActions.Visible := False;
    frmMain.pnlEftposSettings.Visible := False;
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

  PersistState;
  Action := caFree;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  comWrapper := CreateComObject(CLASS_ComWrapper) AS SPIClient_TLB.comWrapper;
  spi := CreateComObject(CLASS_Spi) AS SPIClient_TLB.spi;
  spiSecrets := CreateComObject(CLASS_Secrets) AS SPIClient_TLB.Secrets;
  spiPayAtTable := CreateComObject(CLASS_SpiPayAtTable)
    AS SPIClient_TLB.spiPayAtTable;
  spiSecrets := nil;
  options := CreateComObject(CLASS_TransactionOptions)
    AS SPIClient_TLB.TransactionOptions;
  delegationPointers := CreateComObject(CLASS_DelegationPointers)
    AS SPIClient_TLB.delegationPointers;

  frmMain.edtPosID.Text := 'DELPHIPOS';
  lblStatus.Color := clRed;

  frmActions := TfrmActions.Create(frmMain);
  frmActions.PopupParent := frmMain;
  frmActions.Hide;
end;

procedure TfrmMain.btnPurchaseClick(Sender: TObject);
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to purchase for in cents';
  frmActions.btnAction1.Enabled := True;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.PURCHASE;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := ComponentNames.AMOUNT;
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '0';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := ComponentNames.TipAmount;
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '0';
  frmActions.lblAction3.Visible := True;
  frmActions.lblAction3.Caption := ComponentNames.CASHOUTAMOUNT;
  frmActions.edtAction3.Visible := True;
  frmActions.edtAction3.Text := '0';
  frmActions.lblAction4.Visible := True;
  frmActions.lblAction4.Caption := ComponentNames.SURCHARGEAMOUNT;
  frmActions.edtAction4.Visible := True;
  frmActions.edtAction4.Text := '0';
  frmActions.cboxAction1.Visible := True;
  frmActions.cboxAction1.Caption := ComponentNames.PROMPTCASHOUT;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnRefundClick(Sender: TObject);
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to refund for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.REFUND;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := ComponentNames.AMOUNT;
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '0';
  frmActions.lblAction2.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := True;
  frmActions.cboxAction1.Caption := ComponentNames.SUPPRESSMERCHANTPASSWORD;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  Start;

  btnSave.Enabled := False;
  if (edtPosID.Text = '') or (edtEftposAddress.Text = '') then
  begin
    ShowMessage('Please fill the parameters');
    exit;
  end;

  spi.SetPosId(edtPosID.Text);
  spi.SetEftposAddress(edtEftposAddress.Text);
  frmMain.pnlStatus.Visible := True;
end;

procedure TfrmMain.btnSecretsClick(Sender: TObject);
begin
  frmActions.Show;
  frmActions.richEdtFlow.Clear;

  if (spiSecrets <> nil) then
  begin
    frmActions.richEdtFlow.Lines.Add('Pos Id:');
    frmActions.richEdtFlow.Lines.Add(posId);
    frmActions.richEdtFlow.Lines.Add('Eftpos Address:');
    frmActions.richEdtFlow.Lines.Add(eftposAddress);
    frmActions.richEdtFlow.Lines.Add('Secrets:');
    frmActions.richEdtFlow.Lines.Add(spiSecrets.encKey + ':' +
      spiSecrets.hmacKey);
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('I have no secrets!');
  end;

  GetOKActionComponents;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnSettleClick(Sender: TObject);
var
  settleres: SPIClient_TLB.InitiateTxResult;
begin
  frmActions.Show;
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.btnAction1.Enabled := True;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.CANCEL;
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction2.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;

  settleres := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  settleres := spi.InitiateSettleTx_2(comWrapper.Get_Id('settle'),
    frmMain.options);

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

procedure TfrmMain.btnTerminalSettingsClick(Sender: TObject);
begin
  frmMain.spi.GetTerminalConfiguration;
end;

procedure TfrmMain.btnTerminalStatusClick(Sender: TObject);
begin
  frmMain.spi.GetTerminalStatus;
end;

procedure TfrmMain.cboxPrintMerchantCopyClick(Sender: TObject);
begin
  frmMain.spi.Config.PrintMerchantCopy := frmMain.cboxPrintMerchantCopy.Checked;
end;

procedure TfrmMain.cboxReceiptFromEftposClick(Sender: TObject);
begin
  frmMain.spi.Config.PromptForCustomerCopyOnEftpos :=
    frmMain.cboxReceiptFromEftpos.Checked;
end;

procedure TfrmMain.cboxSignFromEftposClick(Sender: TObject);
begin
  frmMain.spi.Config.SignatureFlowOnEftpos :=
    frmMain.cboxSignFromEftpos.Checked;
end;

procedure TfrmMain.LockTable;
var
  billId, tableId: WideString;
begin
  frmActions.richEdtFlow.Lines.Clear;
  tableId := frmActions.edtAction1.Text;
  if (not tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Table not Open.');
  end
  else
  begin
    billId := tableToBillMappingDict[tableId];
    billsStoreDict[billId].locked := frmActions.cboxAction1.Checked;
    if (billsStoreDict[billId].locked) then
    begin
      frmActions.richEdtFlow.Lines.Add
        ('Locked: ' + BillToString(billsStoreDict[billId]));
    end
    else
    begin
      frmActions.richEdtFlow.Lines.Add
        ('UnLocked: ' + BillToString(billsStoreDict[billId]));
    end;
  end;

  frmActions.Show;
  GetOKActionComponents;
end;

procedure TfrmMain.OpenTable;
var
  newBill: TBill;
  billId, tableId: WideString;
begin
  frmActions.richEdtFlow.Lines.Clear;
  tableId := frmActions.edtAction1.Text;
  if (tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    billId := tableToBillMappingDict[tableId];
    frmActions.richEdtFlow.Lines.Add('Table Already Open: ' +
      BillToString(billsStoreDict[billId]));
  end
  else
  begin
    newBill := TBill.Create;
    newBill.billId := comWrapper.NewBillId;
    newBill.tableId := frmActions.edtAction1.Text;
    newBill.operatorId := frmActions.edtAction2.Text;
    newBill.tableLabel := frmActions.edtAction3.Text;
    billsStoreDict.Add(newBill.billId, newBill);
    tableToBillMappingDict.Add(newBill.tableId, newBill.billId);
    frmActions.richEdtFlow.Lines.Add('Opened: ' + BillToString(newBill));
  end;

  frmActions.Show;
  GetOKActionComponents;
end;

procedure TfrmMain.CloseTable;
var
  billId, tableId: WideString;
begin
  frmActions.richEdtFlow.Lines.Clear;
  tableId := frmActions.edtAction1.Text;
  if (not tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Table not Open.');
  end
  else
  begin
    billId := tableToBillMappingDict[tableId];
    if (billsStoreDict[billId].locked) then
    begin
      frmActions.richEdtFlow.Lines.Add('Table is Locked!');
    end
    else
    begin
      if (billsStoreDict[billId].outstandingAmount > 0) then
      begin
        frmActions.richEdtFlow.Lines.Add('Bill not Paid Yet: ' +
          BillToString(billsStoreDict[billId]));
      end
      else
      begin
        tableToBillMappingDict.Remove(tableId);
        assemblyBillDataStoreDict.Remove(billId);
        frmActions.richEdtFlow.Lines.Add
          ('Closed: ' + BillToString(billsStoreDict[billId]));
      end;
    end;
  end;

  frmActions.Show;
  GetOKActionComponents;
end;

procedure TfrmMain.AddToTable;
var
  billId, tableId: WideString;
  amountCents: Integer;
begin
  frmActions.richEdtFlow.Lines.Clear;
  tableId := frmActions.edtAction1.Text;
  Integer.TryParse(frmActions.edtAction2.Text, amountCents);
  if (not tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Table not Open.');
  end
  else
  begin
    if (billsStoreDict[tableToBillMappingDict[tableId]].locked) then
    begin
      frmActions.richEdtFlow.Lines.Add('Table is Locked!');
    end
    else
    begin
      billId := tableToBillMappingDict[tableId];
      billsStoreDict[billId].totalAmount := billsStoreDict[billId].totalAmount +
        amountCents;
      billsStoreDict[billId].outstandingAmount := billsStoreDict[billId]
        .outstandingAmount + amountCents;
      frmActions.richEdtFlow.Lines.Add
        ('Updated: ' + BillToString(billsStoreDict[billId]));
    end;
  end;

  frmActions.Show;
  GetOKActionComponents;
end;

procedure TfrmMain.PrintBill(billId: WideString);
begin
  frmActions.richEdtFlow.Lines.Clear;
  if (billId = '') then
  begin
    billId := frmActions.edtAction1.Text;
  end;

  if (not billsStoreDict.ContainsKey(billId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Bill not Open.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add
      ('Bill: ' + BillToString(billsStoreDict[billId]));
  end;

  frmActions.Show;
  GetOKActionComponents;
end;

procedure TfrmMain.GetBill;
var
  tableId: WideString;
begin
  frmActions.richEdtFlow.Lines.Clear;
  tableId := frmActions.edtAction1.Text;
  if (not tableToBillMappingDict.ContainsKey(tableId)) then
  begin
    frmActions.richEdtFlow.Lines.Add('Table not Open.');
  end
  else
  begin
    PrintBill(tableToBillMappingDict[tableId]);
  end;

  frmActions.Show;
  GetOKActionComponents;
end;

end.
