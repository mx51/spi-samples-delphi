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
    pnlStatus: TPanel;
    lblStatusHead: TLabel;
    lblStatus: TLabel;
    btnPair: TButton;
    pnlReceipt: TPanel;
    lblReceipt: TLabel;
    richEdtReceipt: TRichEdit;
    btnVerify: TButton;
    btnExtend: TButton;
    btnTopDown: TButton;
    pnlOtherActions: TPanel;
    lblOtherActions: TLabel;
    pnlPreAuthActions: TPanel;
    lblPreAuthActions: TLabel;
    btnCancel: TButton;
    btnSecrets: TButton;
    pnlSettings: TPanel;
    lblSettings: TLabel;
    lblPosID: TLabel;
    lblEftposAddress: TLabel;
    lblSecrets: TLabel;
    edtPosID: TEdit;
    edtEftposAddress: TEdit;
    btnSave: TButton;
    edtSecrets: TEdit;
    pnlEftposSettings: TPanel;
    lblEftposSettings: TLabel;
    cboxReceiptFromEftpos: TCheckBox;
    cboxSignFromEftpos: TCheckBox;
    cboxPrintMerchantCopy: TCheckBox;
    btnRecovery: TButton;
    btnFreeformReceipt: TButton;
    btnTerminalStatus: TButton;
    btnTerminalSettings: TButton;
    btnHeaderFooter: TButton;
    procedure btnPairClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnExtendClick(Sender: TObject);
    procedure btnTopDownClick(Sender: TObject);
    procedure btnVerifyClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnTopUpClick(Sender: TObject);
    procedure btnCompleteClick(Sender: TObject);
    procedure btnRecoveryClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSecretsClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cboxReceiptFromEftposClick(Sender: TObject);
    procedure cboxSignFromEftposClick(Sender: TObject);
    procedure cboxPrintMerchantCopyClick(Sender: TObject);
    procedure btnTerminalStatusClick(Sender: TObject);
    procedure btnTerminalSettingsClick(Sender: TObject);
    procedure btnFreeformReceiptClick(Sender: TObject);
    procedure btnHeaderFooterClick(Sender: TObject);
  private

  public
    comWrapper: SPIClient_TLB.comWrapper;
    spi: SPIClient_TLB.spi;
    spiPreauth: SPIClient_TLB.spiPreauth;
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
  frmActions: TfrmActions;
  useSynchronize, useQueue: Boolean;
  delegationPointers: SPIClient_TLB.delegationPointers;

implementation

{$R *.dfm}

uses ComponentNames;

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

procedure LoadPersistedState;
var
  OutPutList: TStringList;
begin
  if (frmMain.edtSecrets.Text <> '') then
  begin
    OutPutList := TStringList.Create;
    Split(':', frmMain.edtSecrets.Text, OutPutList);
    frmMain.spiSecrets := frmMain.comWrapper.SecretsInit(OutPutList[0],
      OutPutList[1]);
  end
end;

procedure SpiPrintFlowInfo;
var
  preauthResponse: SPIClient_TLB.preauthResponse;
  acctVerifyResponse: SPIClient_TLB.AccountVerifyResponse;
  details: SPIClient_TLB.PurchaseResponse;
  txFlowState: SPIClient_TLB.TransactionFlowState;
begin
  preauthResponse := CreateComObject(CLASS_PreauthResponse)
    AS SPIClient_TLB.preauthResponse;
  acctVerifyResponse := CreateComObject(CLASS_AccountVerifyResponse)
    AS SPIClient_TLB.AccountVerifyResponse;

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
    txFlowState := frmMain.spi.CurrentTxFlowState;
    frmActions.lblFlowMessage.Caption :=
      frmMain.spi.CurrentTxFlowState.DisplayMessage;
    frmActions.richEdtFlow.Lines.Add('### TX PROCESS UPDATE ###');
    frmActions.richEdtFlow.Lines.Add('# ' + txFlowState.DisplayMessage);
    frmActions.richEdtFlow.Lines.Add('# Id: ' + txFlowState.PosRefId);
    frmActions.richEdtFlow.Lines.Add
      ('# Type: ' + frmMain.comWrapper.GetTransactionTypeEnumName
      (txFlowState.type_));
    frmActions.richEdtFlow.Lines.Add('# Request Amount: ' +
      IntToStr(txFlowState.amountCents div 100));
    frmActions.richEdtFlow.Lines.Add('# Waiting For Signature: ' +
      BoolToStr(txFlowState.AwaitingSignatureCheck));
    frmActions.richEdtFlow.Lines.Add('# Attempting to Cancel : ' +
      BoolToStr(txFlowState.AttemptingToCancel));
    frmActions.richEdtFlow.Lines.Add('# Finished: ' +
      BoolToStr(txFlowState.Finished));
    frmActions.richEdtFlow.Lines.Add('# Success: ' +
      frmMain.comWrapper.GetSuccessStateEnumName(txFlowState.Success));

    if (txFlowState.AwaitingSignatureCheck) then
    begin
      frmMain.richEdtReceipt.Lines.Add
        (TrimLeft(txFlowState.SignatureRequiredMessage.GetMerchantReceipt));
    end;

    If (txFlowState.Finished) then
    begin
      case txFlowState.Success of
        SuccessState_Success:
          case txFlowState.type_ of
            TransactionType_Preauth:
              begin
                frmActions.richEdtFlow.Lines.Add('# PREAUTH RESULT - SUCCESS');
                preauthResponse := frmMain.comWrapper.PreauthResponseInit
                  (txFlowState.Response);
                frmActions.richEdtFlow.Lines.Add
                  ('# PREAUTH-ID: ' + preauthResponse.PreauthId);
                frmActions.richEdtFlow.Lines.Add('# NEW BALANCE AMOUNT: ' +
                  IntToStr(preauthResponse.GetBalanceAmount));
                frmActions.richEdtFlow.Lines.Add('# PREV BALANCE AMOUNT: ' +
                  IntToStr(preauthResponse.GetPreviousBalanceAmount));
                frmActions.richEdtFlow.Lines.Add('# COMPLETION AMOUNT: ' +
                  IntToStr(preauthResponse.GetCompletionAmount));

                details := preauthResponse.details;
                frmActions.richEdtFlow.Lines.Add
                  ('# Response: ' + details.GetResponseText);
                frmActions.richEdtFlow.Lines.Add('# RRN: ' + details.GetRRN);
                frmActions.richEdtFlow.Lines.Add
                  ('# Scheme: ' + details.SchemeName);
                frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                frmMain.richEdtReceipt.Lines.Add
                  (TrimLeft(details.GetCustomerReceipt));
              end;

            TransactionType_AccountVerify:
              begin
                frmActions.richEdtFlow.Lines.Add
                  ('# ACCOUNT VERIFICATION SUCCESS');
                acctVerifyResponse :=
                  frmMain.comWrapper.AccountVerifyResponseInit
                  (txFlowState.Response);
                details := acctVerifyResponse.details;

                frmActions.richEdtFlow.Lines.Add
                  ('# Response: ' + details.GetResponseText);
                frmActions.richEdtFlow.Lines.Add('# RRN: ' + details.GetRRN);
                frmActions.richEdtFlow.Lines.Add
                  ('# Scheme: ' + details.SchemeName);
                frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
                frmMain.richEdtReceipt.Lines.Add
                  (TrimLeft(details.GetCustomerReceipt));
              end;

          else
            begin
              frmActions.richEdtFlow.Lines.Add
                ('# MOTEL POS DOESN''T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT SUCCEEDS');
            end;
          end;

        SuccessState_Failed:
          case txFlowState.type_ of
            TransactionType_Preauth:
              begin
                frmActions.richEdtFlow.Lines.Add
                  ('# PREAUTH TRANSACTION FAILED :(');
                frmActions.richEdtFlow.Lines.Add
                  ('# Error: ' + txFlowState.Response.GetError);
                frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
                  txFlowState.Response.GetErrorDetail);

                if (txFlowState.Response <> nil) then
                begin
                  details := frmMain.comWrapper.PurchaseResponseInit
                    (txFlowState.Response);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Response: ' + details.GetResponseText);
                  frmActions.richEdtFlow.Lines.Add('# RRN: ' + details.GetRRN);
                  frmActions.richEdtFlow.Lines.Add
                    ('# Scheme: ' + details.SchemeName);
                  frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                  frmMain.richEdtReceipt.Lines.Add
                    (TrimLeft(details.GetCustomerReceipt));
                end;
              end;

            TransactionType_AccountVerify:
              begin
                frmActions.richEdtFlow.Lines.Add
                  ('# ACCOUNT VERIFICATION FAILED :(');
                frmActions.richEdtFlow.Lines.Add
                  ('# Error: ' + txFlowState.Response.GetError);
                frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
                  txFlowState.Response.GetErrorDetail);

                if (txFlowState.Response <> nil) then
                begin
                  acctVerifyResponse :=
                    frmMain.comWrapper.AccountVerifyResponseInit
                    (txFlowState.Response);
                  details := acctVerifyResponse.details;
                  frmMain.richEdtReceipt.Lines.Add
                    (TrimLeft(details.GetCustomerReceipt));
                end;
              end;

          else
            begin
              frmActions.richEdtFlow.Lines.Add
                ('# MOTEL POS DOESN''T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT FAILS');
            end;
          end;

        SuccessState_Unknown:
          case txFlowState.type_ of
            TransactionType_Preauth:
              begin
                frmActions.richEdtFlow.Lines.Add
                  ('# WE''RE NOT QUITE SURE WHETHER PREAUTH TRANSACTION WENT THROUGH OR NOT:/');
                frmActions.richEdtFlow.Lines.Add
                  ('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
                frmActions.richEdtFlow.Lines.Add
                  ('# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.');
                frmActions.richEdtFlow.Lines.Add
                  ('# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.');
              end;

            TransactionType_AccountVerify:
              begin
                frmActions.richEdtFlow.Lines.Add
                  ('# WE''RE NOT QUITE SURE WHETHER ACCOUNT VERIFICATION WENT THROUGH OR NOT:/');
                frmActions.richEdtFlow.Lines.Add
                  ('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
                frmActions.richEdtFlow.Lines.Add
                  ('# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.');
                frmActions.richEdtFlow.Lines.Add
                  ('# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.');
              end;

          else
            begin
              frmActions.richEdtFlow.Lines.Add
                ('# MOTEL POS DOESN''T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT''s UNKNOWN');
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
  frmActions.richEdtFlow.Lines.Add('# CASH ONLY! #');
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
            frmMain.pnlPreAuthActions.Visible := True;
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
            frmMain.pnlPreAuthActions.Visible := True;
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

procedure Start;
begin
  LoadPersistedState;

  frmMain.posId := frmMain.edtPosID.Text;
  frmMain.eftposAddress := frmMain.edtEftposAddress.Text;

  frmMain.spi := frmMain.comWrapper.SpiInit(frmMain.posId, frmMain.serialNumber,
    frmMain.eftposAddress, frmMain.spiSecrets);
  frmMain.spi.SetPosInfo('assembly', '2.5.0');

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

  frmMain.comWrapper.Main(frmMain.spi, delegationPointers);

  frmMain.spiPreauth := frmMain.spi.EnablePreauth;

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

procedure TfrmMain.btnPairClick(Sender: TObject);
begin
  if (btnPair.Caption = 'Pair') then
  begin
    spi.Pair;
    btnSecrets.Visible := True;
    edtPosID.Enabled := False;
    edtEftposAddress.Enabled := False;
    frmMain.lblStatus.Color := clYellow;
  end
  else if (btnPair.Caption = 'UnPair') then
  begin
    spi.UNPAIR;
    frmMain.btnPair.Caption := 'Pair';
    frmMain.pnlPreAuthActions.Visible := False;
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
  frmMain.comWrapper := CreateComObject(CLASS_ComWrapper)
    AS SPIClient_TLB.comWrapper;
  frmMain.spi := CreateComObject(CLASS_Spi) AS SPIClient_TLB.spi;
  frmMain.spiSecrets := CreateComObject(CLASS_Secrets) AS SPIClient_TLB.Secrets;
  frmMain.spiPreauth := CreateComObject(CLASS_SpiPreauth)
    AS SPIClient_TLB.spiPreauth;
  frmMain.spiSecrets := nil;
  frmMain.options := CreateComObject(CLASS_TransactionOptions)
    AS SPIClient_TLB.TransactionOptions;
  delegationPointers := CreateComObject(CLASS_DelegationPointers)
    AS SPIClient_TLB.delegationPointers;

  frmMain.edtPosID.Text := 'DELPHIPOS';
  lblStatus.Color := clRed;

  frmActions := TfrmActions.Create(frmMain);
  frmActions.PopupParent := frmMain;
  frmActions.Hide;
end;

procedure TfrmMain.btnVerifyClick(Sender: TObject);
var
  initRes: SPIClient_TLB.InitiateTxResult;
begin
  frmActions.richEdtFlow.Lines.Clear;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to open';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.CANCEL;
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := False;
  frmActions.edtAction1.Visible := False;
  frmActions.lblAction2.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
  frmActions.Show;

  initRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  initRes := spiPreauth.InitiateAccountVerifyTx
    ('actvfy-' + FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now));

  if (initRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('#Account verify request initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Could not initiate account verify request: ' + initRes.Message +
      '. Please Retry.');
  end;
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
  frmActions.lblAction1.Caption := 'Amount(cents):';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '0';
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

procedure TfrmMain.btnExtendClick(Sender: TObject);
begin
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to extend';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Extend';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Preauth Id';
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

procedure TfrmMain.btnTopUpClick(Sender: TObject);
begin
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to top up for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Top Up';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Preauth Id';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := 'Amount(cents):';
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '0';
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
  frmActions.Show;
end;

procedure TfrmMain.btnTopDownClick(Sender: TObject);
begin
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to top down for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Top Down';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Preauth Id';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := 'Amount(cents):';
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '0';
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
  frmActions.Show;
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to cancel';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'PreAuth Cancel';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Preauth Id';
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

procedure TfrmMain.btnCompleteClick(Sender: TObject);
begin
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to complete for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Complete';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Preauth Id';
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := 'Amount(cents):';
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '0';
  frmActions.lblAction3.Visible := True;
  frmActions.lblAction3.Caption := 'Surcharge Amount(cents):';
  frmActions.edtAction3.Visible := True;
  frmActions.edtAction3.Text := '0';
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmMain.Enabled := False;
  frmActions.Show;
end;

procedure TfrmMain.btnRecoveryClick(Sender: TObject);
begin
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Recovery';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := 'Reference';
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
  frmMain.spiPreauth.Config.PrintMerchantCopy := frmMain.cboxPrintMerchantCopy.Checked;
end;

procedure TfrmMain.cboxReceiptFromEftposClick(Sender: TObject);
begin
  frmMain.spiPreauth.Config.PromptForCustomerCopyOnEftpos :=
    frmMain.cboxReceiptFromEftpos.Checked;
end;

procedure TfrmMain.cboxSignFromEftposClick(Sender: TObject);
begin
  frmMain.spiPreauth.Config.SignatureFlowOnEftpos :=
    frmMain.cboxSignFromEftpos.Checked;
end;

end.
