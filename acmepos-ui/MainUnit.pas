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
    pnlActions: TPanel;
    btnPurchase: TButton;
    btnRefund: TButton;
    btnSettle: TButton;
    btnGetLast: TButton;
    edtSecrets: TEdit;
    lblSecrets: TLabel;
    btnSave: TButton;
    btnSecrets: TButton;
    procedure btnPairClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRefundClick(Sender: TObject);
    procedure btnSettleClick(Sender: TObject);
    procedure btnPurchaseClick(Sender: TObject);
    procedure btnGetLastClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnSecretsClick(Sender: TObject);
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
  purchaseResponse: SPIClient_TLB.PurchaseResponse;
  refundResponse: SPIClient_TLB.RefundResponse;
  settleResponse: SPIClient_TLB.Settlement;
  gltResponse: SPIClient_TLB.GetLastTransactionResponse;
  success: SPIClient_TLB.SuccessState;
  TimeMinutes : TDateTime;
  txFlowState: SPIClient_TLB.TransactionFlowState;
const
  MinutesPerDay = 60 * 24;
begin
  purchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.PurchaseResponse;
  refundResponse := CreateComObject(CLASS_RefundResponse)
    AS SPIClient_TLB.RefundResponse;
  settleResponse := CreateComObject(CLASS_Settlement)
    AS SPIClient_TLB.Settlement;
  gltResponse := CreateComObject(CLASS_GetLastTransactionResponse)
    AS SPIClient_TLB.GetLastTransactionResponse;
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
      frmActions.richEdtFlow.Lines.Clear;
      frmActions.lblFlowMessage.Caption := txFlowState.DisplayMessage;
      frmActions.richEdtFlow.Lines.Add('# Id: ' + txFlowState.Id);
      frmActions.richEdtFlow.Lines.Add('# Type: ' +
        ComWrapper.GetTransactionTypeEnumName(txFlowState.type_));
      frmActions.richEdtFlow.Lines.Add('# RequestSent: ' +
        BoolToStr(txFlowState.RequestSent));
      frmActions.richEdtFlow.Lines.Add('# WaitingForSignature: ' +
        BoolToStr(txFlowState.AwaitingSignatureCheck));
      frmActions.richEdtFlow.Lines.Add('# Attempting to Cancel : ' +
        BoolToStr(txFlowState.AttemptingToCancel));
      frmActions.richEdtFlow.Lines.Add('# Finished: ' +
        BoolToStr(txFlowState.Finished));
      frmActions.richEdtFlow.Lines.Add('# Outcome: ' +
        ComWrapper.GetSuccessStateEnumName(txFlowState.Success));
      frmActions.richEdtFlow.Lines.Add('# Display Message: ' +
        txFlowState.DisplayMessage);

      if (txFlowState.AwaitingSignatureCheck) then
      begin
        //We need to print the receipt for the customer to sign.
        frmMain.richEdtReceipt.Lines.Add
          (TrimLeft(txFlowState.SignatureRequiredMessage.GetMerchantReceipt));
      end;

      //If the transaction is finished, we take some extra steps.
      If (txFlowState.Finished) then
      begin
        if (txFlowState.Success = SuccessState_Unknown) then
        begin
          //TH-4T, TH-4N, TH-2T - This is the dge case when we can't be sure what happened to the transaction.
          //Invite the merchant to look at the last transaction on the EFTPOS using the dicumented shortcuts.
          //Now offer your merchant user the options to:
          //A. Retry the transaction from scratch or pay using a different method - If Merchant is confident that tx didn't go through.
          //B. Override Order as Paid in you POS - If Merchant is confident that payment went through.
          //C. Cancel out of the order all together - If the customer has left / given up without paying
          frmActions.richEdtFlow.Lines.Add
            ('# ##########################################################################');
          frmActions.richEdtFlow.Lines.Add
            ('# NOT SURE IF WE GOT PAID OR NOT. CHECK LAST TRANSACTION MANUALLY ON EFTPOS!');
          frmActions.richEdtFlow.Lines.Add
            ('# ##########################################################################');
        end
        else
        begin
          //We have a result...
          case txFlowState.type_ of
            //Depending on what type of transaction it was, we might act diffeently or use different data.
            TransactionType_Purchase:
            begin
              if (txFlowState.Success = SuccessState_Success) then
              begin
                //TH-6A
                frmActions.richEdtFlow.Lines.Add
                  ('# ##########################################################################');
                frmActions.richEdtFlow.Lines.Add
                  ('# HOORAY WE GOT PAID (TH-7A). CLOSE THE ORDER!');
                frmActions.richEdtFlow.Lines.Add
                  ('# ##########################################################################');
              end
              else
              begin
                //TH-6E
                frmActions.richEdtFlow.Lines.Add
                  ('# ##########################################################################');
                frmActions.richEdtFlow.Lines.Add
                  ('# WE DIDN''T GET PAID. RETRY PAYMENT (TH-5R) OR GIVE UP (TH-5C)!');
                frmActions.richEdtFlow.Lines.Add
                  ('# ##########################################################################');
              end;

              if (txFlowState.Response <> nil) then
              begin
                purchaseResponse := ComWrapper.PurchaseResponseInit
                  (txFlowState.Response);
                frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
                  purchaseResponse.SchemeName);
                frmActions.richEdtFlow.Lines.Add('# Response: ' +
                  purchaseResponse.GetResponseText);
                frmActions.richEdtFlow.Lines.Add('# RRN: ' +
                  purchaseResponse.GetRRN);
                frmActions.richEdtFlow.Lines.Add('# Error: ' +
                  txFlowState.Response.GetError);
                frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                frmMain.richEdtReceipt.Lines.Add
                  (TrimLeft(purchaseResponse.GetCustomerReceipt));
              end
              else
              begin
                //We did not even get a response, like in the case of a time-out.
              end;
            end;

            TransactionType_Refund:
              if (txFlowState.Response <> nil) then
              begin
                refundResponse := ComWrapper.RefundResponseInit
                  (txFlowState.Response);
                frmActions.richEdtFlow.Lines.Add('# Scheme: ' +
                  refundResponse.SchemeName);
                frmActions.richEdtFlow.Lines.Add('# Response: ' +
                  refundResponse.GetResponseText);
                frmActions.richEdtFlow.Lines.Add('# RRN: ' +
                  refundResponse.GetRRN);
                frmActions.richEdtFlow.Lines.Add('# Error: ' +
                  txFlowState.Response.GetError);
                frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                frmMain.richEdtReceipt.Lines.Add
                  (TrimLeft(refundResponse.GetCustomerReceipt));
              end
              else
              begin
                //We did not even get a response, like in the case of a time-out.
              end;

            TransactionType_Settle:
              if (txFlowState.Response <> nil) then
              begin
                settleResponse := ComWrapper.SettlementInit
                  (txFlowState.Response);
                frmActions.richEdtFlow.Lines.Add('# Response: ' +
                  settleResponse.GetResponseText);
                frmActions.richEdtFlow.Lines.Add('# Error: ' +
                  txFlowState.Response.GetError);
                frmActions.richEdtFlow.Lines.Add('# Merchant Receipt:');
                frmMain.richEdtReceipt.Lines.Add
                  (TrimLeft(settleResponse.GetReceipt));
              end
              else
              begin
                //We did not even get a response, like in the case of a time-out.
              end;

            TransactionType_GetLastTransaction:
              if (txFlowState.Response <> nil) then
              begin
                gltResponse := ComWrapper.GetLastTransactionResponseInit(txFlowState.Response);
                frmActions.richEdtFlow.Lines.Add('# Checking to see if it matches the $100.00 purchase we did 1 minute ago :)');

                TimeMinutes := 1 / MinutesPerDay;
                success := Spi.GltMatch_2(gltResponse, TransactionType_Purchase, 10000, Now - TimeMinutes, 'MYORDER123');

                if (success = SuccessState_Unknown) then
                begin
                  frmActions.richEdtFlow.Lines.Add('# Did not retrieve Expected Transaction.');
                end
                else
                begin
                  frmActions.richEdtFlow.Lines.Add('# Tx Matched Expected Purchase Request.');
                  frmActions.richEdtFlow.Lines.Add('# Result: ' + ComWrapper.GetSuccessStateEnumName(success));

                  purchaseResponse := ComWrapper.PurchaseResponseInit(txFlowState.Response);
                  frmActions.richEdtFlow.Lines.Add('# Scheme: ' + purchaseResponse.SchemeName);
                  frmActions.richEdtFlow.Lines.Add('# Response: ' + purchaseResponse.GetResponseText());
                  frmActions.richEdtFlow.Lines.Add('# RRN: ' + purchaseResponse.GetRRN());
                  frmActions.richEdtFlow.Lines.Add('# Error: ' + txFlowState.Response.GetError());
                  frmActions.richEdtFlow.Lines.Add('# Customer Receipt:');
                  frmMain.richEdtReceipt.Lines.Add(TrimLeft(purchaseResponse.GetMerchantReceipt));
                end;
              end
              else
              begin
                // We did not even get a response, like in the case of a time-out.
              end;
          end;
        end;
      end;
    end;
  end;
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
          frmMain.pnlActions.Visible := True;
          frmMain.lblStatus.Color := clYellow;
          frmActions.lblFlowMessage.Caption := '# --> SPI Status Changed: ' +
            ComWrapper.GetSpiStatusEnumName(spi.CurrentStatus);
          frmActions.btnAction1.Visible := True;
          frmActions.btnAction1.Caption := 'OK';
          frmActions.btnAction2.Visible := False;
          frmActions.btnAction3.Visible := False;
          frmActions.lblAmount.Visible := False;
          frmActions.edtAmount.Visible := False;
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
                frmActions.edtAmount.Visible := False;
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
          exit;
        end;

      else
        frmActions.btnAction1.Visible := True;
        frmActions.btnAction1.Caption := 'OK';
        frmActions.btnAction2.Visible := False;
        frmActions.btnAction3.Visible := False;
        frmActions.lblAmount.Visible := False;
        frmActions.edtAmount.Visible := False;
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
          frmMain.pnlActions.Visible := True;
          frmMain.lblStatus.Color := clGreen;
          frmActions.lblFlowMessage.Caption := '# --> SPI Status Changed: ' +
            ComWrapper.GetSpiStatusEnumName(spi.CurrentStatus);

          if (frmActions.btnAction1.Caption = 'Retry') then
          begin
            frmActions.btnAction1.Visible := True;
            frmActions.btnAction1.Caption := 'OK';
            frmActions.btnAction2.Visible := False;
            frmActions.btnAction3.Visible := False;
            frmActions.lblAmount.Visible := False;
            frmActions.edtAmount.Visible := False;
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
                frmActions.edtAmount.Visible := False;
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
          exit;
        end;

      else
        frmActions.btnAction1.Visible := True;
        frmActions.btnAction1.Caption := 'OK';
        frmActions.btnAction2.Visible := False;
        frmActions.btnAction3.Visible := False;
        frmActions.lblAmount.Visible := False;
        frmActions.edtAmount.Visible := False;
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

  Spi.Start;

  TMyWorkerThread.Create(false);
end;

procedure TfrmMain.btnGetLastClick(Sender: TObject);
var
  sres: SPIClient_TLB.InitiateTxResult;
begin
  sres := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  sres := Spi.InitiateGetLastTx;

  if (sres.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# GLT Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate GLT: ' +
      sres.Message + '. Please Retry.');
  end;
  frmActions.Show;
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
    frmMain.pnlActions.Visible := False;
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

procedure TfrmMain.btnPurchaseClick(Sender: TObject);
begin
  if (not Assigned(frmActions)) then
  begin
    frmActions := frmActions.Create(frmMain, Spi);
    frmActions.PopupParent := frmMain;
    frmMain.Enabled := False;
  end;

  frmActions.Show;
  frmActions.lblFlowMessage.Caption :=  'Please enter the amount you would like to purchase for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Purchase';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.edtAmount.Visible := True;
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
  frmActions.lblFlowMessage.Caption :=  'Please enter the amount you would like to refund for in cents';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := 'Refund';
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := 'Cancel';
  frmActions.btnAction3.Visible := False;
  frmActions.lblAmount.Visible := True;
  frmActions.edtAmount.Visible := True;
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
  frmActions.edtAmount.Visible := False;
  frmMain.Enabled := False;
end;

Procedure TfrmMain.btnSettleClick(Sender: TObject);
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
  frmActions.edtAmount.Visible := False;
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

end.
