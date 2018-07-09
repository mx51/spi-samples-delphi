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
    lblReference: TLabel;
    btnRecover: TButton;
    edtReference: TEdit;
    btnCancel: TButton;
    btnSecrets: TButton;
    pnlSettings: TPanel;
    lblSettings: TLabel;
    lblPosID: TLabel;
    lblEftposAddress: TLabel;
    lblReceiptFrom: TLabel;
    lblSignFrom: TLabel;
    lblSecrets: TLabel;
    edtPosID: TEdit;
    radioSign: TRadioGroup;
    radioReceipt: TRadioGroup;
    edtEftposAddress: TEdit;
    btnSave: TButton;
    edtSecrets: TEdit;
    procedure btnPairClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnExtendClick(Sender: TObject);
    procedure btnTopDownClick(Sender: TObject);
    procedure btnVerifyClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnTopUpClick(Sender: TObject);
    procedure btnCompleteClick(Sender: TObject);
    procedure btnRecoverClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
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
  SpiPreauth: SPIClient_TLB.SpiPreauth;

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
    SpiSecrets := ComWrapper.SecretsInit(OutPutList[0], OutPutList[1]);
  end
end;

procedure PrintFlowInfo;
var
  preauthResponse: SPIClient_TLB.PreauthResponse;
  acctVerifyResponse: SPIClient_TLB.AccountVerifyResponse;
  details: SPIClient_TLB.PurchaseResponse;
  txFlowState: SPIClient_TLB.TransactionFlowState;
begin
  preauthResponse := CreateComObject(CLASS_PreauthResponse)
    AS SPIClient_TLB.PreauthResponse;
  acctVerifyResponse := CreateComObject(CLASS_AccountVerifyResponse)
    AS SPIClient_TLB.AccountVerifyResponse;

  if (Spi.CurrentFlow = SpiFlow_Pairing) then
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

  if (Spi.CurrentFlow = SpiFlow_Transaction) then
  begin
    txFlowState := spi.CurrentTxFlowState;
    frmActions.lblFlowMessage.Caption :=
      spi.CurrentTxFlowState.DisplayMessage;
    frmActions.richEdtFlow.Lines.Add('### TX PROCESS UPDATE ###');
    frmActions.richEdtFlow.Lines.Add('# ' + txFlowState.DisplayMessage);
    frmActions.richEdtFlow.Lines.Add('# Id: ' + txFlowState.PosRefId);
    frmActions.richEdtFlow.Lines.Add('# Type: ' +
      ComWrapper.GetTransactionTypeEnumName(txFlowState.type_));
    frmActions.richEdtFlow.Lines.Add('# Request Amount: ' +
      IntToStr(txFlowState.amountCents div 100));
    frmActions.richEdtFlow.Lines.Add('# Waiting For Signature: ' +
      BoolToStr(txFlowState.AwaitingSignatureCheck));
    frmActions.richEdtFlow.Lines.Add('# Attempting to Cancel : ' +
      BoolToStr(txFlowState.AttemptingToCancel));
    frmActions.richEdtFlow.Lines.Add('# Finished: ' +
      BoolToStr(txFlowState.Finished));
    frmActions.richEdtFlow.Lines.Add('# Success: ' +
      ComWrapper.GetSuccessStateEnumName(txFlowState.Success));

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
            preauthResponse := ComWrapper.PreauthResponseInit(
              txFlowState.Response);
            frmActions.richEdtFlow.Lines.Add('# PREAUTH-ID: ' +
              preauthResponse.PreauthId);
            frmActions.richEdtFlow.Lines.Add('# NEW BALANCE AMOUNT: ' +
              IntToStr(preauthResponse.GetBalanceAmount));
            frmActions.richEdtFlow.Lines.Add('# PREV BALANCE AMOUNT: ' +
              IntToStr(preauthResponse.GetPreviousBalanceAmount));
            frmActions.richEdtFlow.Lines.Add('# COMPLETION AMOUNT: ' +
              IntToStr(preauthResponse.GetCompletionAmount));

            details := preauthResponse.Details;
            frmActions.richEdtFlow.Lines.Add('# Response: ' +
              details.GetResponseText);
            frmActions.richEdtFlow.Lines.Add('# RRN: ' + details.GetRRN);
            frmActions.richEdtFlow.Lines.Add('# Scheme: ' + details.SchemeName);
            frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
            frmMain.richEdtReceipt.Lines.Add
              (TrimLeft(details.GetCustomerReceipt));
          end;

          TransactionType_AccountVerify:
          begin
            frmActions.richEdtFlow.Lines.Add('# ACCOUNT VERIFICATION SUCCESS');
            acctVerifyResponse := ComWrapper.AccountVerifyResponseInit(
              txFlowState.Response);
            details := acctVerifyResponse.Details;

            frmActions.richEdtFlow.Lines.Add('# Response: ' +
              details.GetResponseText);
            frmActions.richEdtFlow.Lines.Add('# RRN: ' + details.GetRRN);
            frmActions.richEdtFlow.Lines.Add('# Scheme: ' + details.SchemeName);
            frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
            frmMain.richEdtReceipt.Lines.Add
              (TrimLeft(details.GetCustomerReceipt));
          end;

          else
          begin
            frmActions.richEdtFlow.Lines.Add(
              '# MOTEL POS DOESN''T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT SUCCEEDS');
          end;
        end;

        SuccessState_Failed:
        case txFlowState.type_ of
          TransactionType_Preauth:
          begin
            frmActions.richEdtFlow.Lines.Add('# PREAUTH TRANSACTION FAILED :(');
            frmActions.richEdtFlow.Lines.Add('# Error: ' +
			        txFlowState.Response.GetError);
            frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
			        txFlowState.Response.GetErrorDetail);

            if (txFlowState.Response <> nil) then
            begin
              details := ComWrapper.PurchaseResponseInit(txFlowState.Response);
              frmActions.richEdtFlow.Lines.Add('# Response: ' +
                details.GetResponseText);
              frmActions.richEdtFlow.Lines.Add('# RRN: ' + details.GetRRN);
              frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
                details.SchemeName);
              frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
              frmMain.richEdtReceipt.Lines.Add
                (TrimLeft(details.GetCustomerReceipt));
            end;
          end;

          TransactionType_AccountVerify:
          begin
            frmActions.richEdtFlow.Lines.Add(
              '# ACCOUNT VERIFICATION FAILED :(');
            frmActions.richEdtFlow.Lines.Add('# Error: ' +
			        txFlowState.Response.GetError);
            frmActions.richEdtFlow.Lines.Add('# Error Detail: ' +
			        txFlowState.Response.GetErrorDetail);

            if (txFlowState.Response <> nil) then
            begin
              acctVerifyResponse := ComWrapper.AccountVerifyResponseInit(
                txFlowState.Response);
              details := acctVerifyResponse.Details;
              frmMain.richEdtReceipt.Lines.Add
                (TrimLeft(details.GetCustomerReceipt));
            end;
          end;

          else
          begin
            frmActions.richEdtFlow.Lines.Add(
              '# MOTEL POS DOESN''T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT FAILS');
          end;
        end;

        SuccessState_Unknown:
        case txFlowState.type_ of
          TransactionType_Preauth:
          begin
            frmActions.richEdtFlow.Lines.Add(
              '# WE''RE NOT QUITE SURE WHETHER PREAUTH TRANSACTION WENT THROUGH OR NOT:/');
            frmActions.richEdtFlow.Lines.Add(
              '# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
            frmActions.richEdtFlow.Lines.Add(
              '# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.');
            frmActions.richEdtFlow.Lines.Add(
              '# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.');
          end;

          TransactionType_AccountVerify:
          begin
            frmActions.richEdtFlow.Lines.Add(
              '# WE''RE NOT QUITE SURE WHETHER ACCOUNT VERIFICATION WENT THROUGH OR NOT:/');
            frmActions.richEdtFlow.Lines.Add(
              '# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
            frmActions.richEdtFlow.Lines.Add(
              '# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.');
            frmActions.richEdtFlow.Lines.Add(
              '# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.');
          end;

          else
          begin
            frmActions.richEdtFlow.Lines.Add(
              '# MOTEL POS DOESN''T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT''s UNKNOWN');
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
  frmActions.richEdtFlow.Lines.Add('# CASH ONLY! #');
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
              frmActions.lblPreauthId.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.edtPreauthId.Visible := False;
              frmMain.lblStatus.Color := clRed;
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
              frmActions.lblPreauthId.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.edtPreauthId.Visible := False;
              exit;
            end
            else if (not Spi.CurrentPairingFlowState.Finished) then
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := 'Cancel Pairing';
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              frmActions.lblAmount.Visible := False;
              frmActions.lblPreauthId.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.edtPreauthId.Visible := False;
              exit;
            end
            else
            begin
              frmActions.btnAction1.Visible := True;
              frmActions.btnAction1.Caption := 'OK';
              frmActions.btnAction2.Visible := False;
              frmActions.btnAction3.Visible := False;
              frmActions.lblAmount.Visible := False;
              frmActions.lblPreauthId.Visible := False;
              frmActions.edtAmount.Visible := False;
              frmActions.edtPreauthId.Visible := False;
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
          frmActions.lblPreauthId.Visible := False;
          frmActions.edtAmount.Visible := False;
          frmActions.edtPreauthId.Visible := False;
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
          frmMain.pnlPreAuthActions.Visible := True;
          frmMain.pnlOtherActions.Visible := True;
          frmMain.lblStatus.Color := clYellow;
          frmActions.lblFlowMessage.Caption := '# --> SPI Status Changed: ' +
            ComWrapper.GetSpiStatusEnumName(spi.CurrentStatus);
          frmActions.btnAction1.Visible := True;
          frmActions.btnAction1.Caption := 'OK';
          frmActions.btnAction2.Visible := False;
          frmActions.btnAction3.Visible := False;
          frmActions.lblAmount.Visible := False;
          frmActions.lblPreauthId.Visible := False;
          frmActions.edtAmount.Visible := False;
          frmActions.edtPreauthId.Visible := False;
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
            frmActions.lblPreauthId.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtPreauthId.Visible := False;
            exit;
          end
          else if (not Spi.CurrentTxFlowState.Finished) then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'Cancel';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.lblPreauthId.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtPreauthId.Visible := False;
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
                frmActions.lblPreauthId.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtPreauthId.Visible := False;
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
                exit;
              end;
              else
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'OK';
                frmActions.btnAction2.Visible := False;
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.lblPreauthId.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtPreauthId.Visible := False;
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
          frmActions.lblPreauthId.Visible := False;
          frmActions.edtAmount.Visible := False;
          frmActions.edtPreauthId.Visible := False;
          exit;
        end;

      else
        frmActions.btnAction1.Visible := True;
        frmActions.btnAction1.Caption := 'OK';
        frmActions.btnAction2.Visible := False;
        frmActions.btnAction3.Visible := False;
        frmActions.lblAmount.Visible := False;
        frmActions.lblPreauthId.Visible := False;
        frmActions.edtAmount.Visible := False;
        frmActions.edtPreauthId.Visible := False;
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
          frmMain.pnlPreAuthActions.Visible := True;
          frmMain.pnlOtherActions.Visible := True;
          frmMain.lblStatus.Color := clGreen;

          if (frmActions.btnAction1.Caption = 'Retry') then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'OK';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.lblPreauthId.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtPreauthId.Visible := False;
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
            frmActions.lblPreauthId.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtPreauthId.Visible := False;
            exit;
          end
          else if (not Spi.CurrentTxFlowState.Finished) then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'Cancel';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.lblPreauthId.Visible := False;
            frmActions.edtAmount.Visible := False;
            frmActions.edtPreauthId.Visible := False;
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
                frmActions.lblPreauthId.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtPreauthId.Visible := False;
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
                exit;
              end;
              else
              begin
                frmActions.btnAction1.Visible := True;
                frmActions.btnAction1.Caption := 'OK';
                frmActions.btnAction2.Visible := False;
                frmActions.btnAction3.Visible := False;
                frmActions.lblAmount.Visible := False;
                frmActions.lblPreauthId.Visible := False;
                frmActions.edtAmount.Visible := False;
                frmActions.edtPreauthId.Visible := False;
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
          frmActions.lblPreauthId.Visible := False;
          frmActions.edtAmount.Visible := False;
          frmActions.edtPreauthId.Visible := False;
          exit;
        end;

      else
        frmActions.btnAction1.Visible := True;
        frmActions.btnAction1.Caption := 'OK';
        frmActions.btnAction2.Visible := False;
        frmActions.btnAction3.Visible := False;
        frmActions.lblAmount.Visible := False;
        frmActions.lblPreauthId.Visible := False;
        frmActions.edtAmount.Visible := False;
        frmActions.edtPreauthId.Visible := False;
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
    frmActions.lblPreauthId.Visible := False;
    frmActions.edtAmount.Visible := False;
    frmActions.edtPreauthId.Visible := False;
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
  frmMain.btnSecretsClick(frmMain.btnSecrets);
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
  SpiPreauth := Spi.EnablePreauth;

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
    frmMain.pnlPreAuthActions.Visible := False;
    frmMain.pnlOtherActions.Visible := False;
    edtSecrets.Text := '';
    lblStatus.Color := clRed;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject;
  var Action: TCloseAction);
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

procedure TfrmMain.btnVerifyClick(Sender: TObject);
var
  initRes: SPIClient_TLB.InitiateTxResult;
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
  frmActions.lblPreauthId.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.edtPreauthId.Visible := False;
  frmMain.Enabled := False;

  initRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  initRes := SpiPreauth.InitiateAccountVerifyTx('actvfy-' + FormatDateTime(
    'dd-mm-yyyy-hh-nn-ss', Now));

  if (initRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('#Account verify request initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add(
      '# Could not initiate account verify request: ' + initRes.Message +
      '. Please Retry.');
  end;
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
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to open for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Open';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.lblPreauthId.Visible := False;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.edtPreauthId.Visible := False;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnExtendClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to extend';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Extend';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.lblPreauthId.Visible := True;
  frmActions.edtAmount.Visible := False;
  frmActions.edtPreauthId.Visible := True;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnTopUpClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to top up for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Top Up';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.lblPreauthId.Visible := True;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.edtPreauthId.Visible := True;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnTopDownClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to top down for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Top Down';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.lblPreauthId.Visible := True;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.edtPreauthId.Visible := True;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the table id you would like to cancel';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'PreAuth Cancel';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := False;
  frmActions.lblPreauthId.Visible := True;
  frmActions.edtAmount.Visible := False;
  frmActions.edtPreauthId.Visible := True;
  frmMain.Enabled := False;
end;

procedure TfrmMain.btnCompleteClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to complete for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Complete';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.lblPreauthId.Visible := True;
  frmActions.edtAmount.Visible := True;
  frmActions.edtAmount.Text := '0';
  frmActions.edtPreauthId.Visible := True;
  frmMain.Enabled := False;
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
    frmActions.lblAmount.Visible := False;
    frmActions.lblPreauthId.Visible := False;
    frmActions.edtAmount.Visible := False;
    frmActions.edtPreauthId.Visible := False;
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
  frmActions.lblPreauthId.Visible := False;
  frmActions.edtAmount.Visible := False;
  frmActions.edtPreauthId.Visible := False;
  frmMain.Enabled := False;
end;

end.
