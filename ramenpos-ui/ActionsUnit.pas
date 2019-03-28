unit ActionsUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, ComObj, SPIClient_TLB,
  ComponentNames;

type
  TfrmActions = class(TForm)
    pnlActions: TPanel;
    btnAction1: TButton;
    btnAction2: TButton;
    lblAction1: TLabel;
    edtAction1: TEdit;
    pnlFlow: TPanel;
    lblFlow: TLabel;
    lblFlowStatus: TLabel;
    lblFlowMessage: TLabel;
    richEdtFlow: TRichEdit;
    btnAction3: TButton;
    edtAction2: TEdit;
    lblAction2: TLabel;
    edtAction3: TEdit;
    lblAction3: TLabel;
    cboxAction1: TCheckBox;
    lblAction4: TLabel;
    edtAction4: TEdit;
    procedure btnAction1Click(Sender: TObject);
    procedure btnAction2Click(Sender: TObject);
    procedure btnAction3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private

  public

  end;

implementation

{$R *.dfm}

uses MainUnit;

function SanitizePrintText(printText: WideString): WideString;
begin
  printText := StringReplace(printText, '\\emphasis', '\emphasis',
    [rfReplaceAll, rfIgnoreCase]);
  printText := StringReplace(printText, '\\clear', '\clear',
    [rfReplaceAll, rfIgnoreCase]);
  printText := StringReplace(printText, '\r\n', sLineBreak,
    [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(printText, 'n', sLineBreak,
    [rfReplaceAll, rfIgnoreCase]);
end;

procedure DoPurchase;
var
  purchase: SPIClient_TLB.InitiateTxResult;
  amount, tipAmount, cashoutAmount, surchargeAmount: Integer;
  posRefId: WideString;
  promptForCashout: Boolean;
begin
  amount := StrToInt(frmActions.edtAction1.Text);
  tipAmount := StrToInt(frmActions.edtAction2.Text);
  cashoutAmount := StrToInt(frmActions.edtAction3.Text);
  surchargeAmount := StrToInt(frmActions.edtAction4.Text);
  promptForCashout := frmActions.cboxAction1.Checked;
  frmActions.richEdtFlow.Lines.clear;

  purchase := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  posRefId := 'prchs-' + FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now);
  purchase := frmMain.spi.InitiatePurchaseTxV2_3(posRefId, amount, tipAmount,
    cashoutAmount, promptForCashout, frmMain.options, surchargeAmount);

  if (purchase.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Purchase Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate purchase: ' +
      purchase.Message + '. Please Retry.');
  end;
end;

procedure DoRefund;
var
  refund: SPIClient_TLB.InitiateTxResult;
  amount: Integer;
begin
  amount := StrToInt(frmActions.edtAction1.Text);
  refund := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  refund := frmMain.spi.InitiateRefundTx_3
    ('rfnd-' + FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), amount,
    frmActions.cboxAction1.Checked, frmMain.options);

  if (refund.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Refund Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate refund: ' +
      refund.Message + '. Please Retry.');
  end;
end;

procedure DoCashOut;
var
  coRes: SPIClient_TLB.InitiateTxResult;
  amount, surchargeAmount: Integer;
begin
  amount := StrToInt(frmActions.edtAction1.Text);
  surchargeAmount := StrToInt(frmActions.edtAction2.Text);
  coRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  coRes := frmMain.spi.InitiateCashoutOnlyTx_3
    ('cshout-' + FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), amount,
    surchargeAmount, frmMain.options);

  if (coRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Cashout Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate cashout: ' +
      coRes.Message + '. Please Retry.');
  end;
end;

procedure DoMoto;
var
  motoRes: SPIClient_TLB.InitiateTxResult;
  amount, surchargeAmount: Integer;
begin
  amount := StrToInt(frmActions.edtAction1.Text);
  surchargeAmount := StrToInt(frmActions.edtAction2.Text);
  motoRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  motoRes := frmMain.spi.InitiateMotoPurchaseTx_4
    ('moto-' + FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), amount,
    surchargeAmount, frmActions.cboxAction1.Checked, frmMain.options);

  if (motoRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Moto Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate moto: ' +
      motoRes.Message + '. Please Retry.');
  end;
end;

procedure DoRecovery;
var
  recoveryRes: SPIClient_TLB.InitiateTxResult;
begin
  if (frmActions.edtAction1.Text = '') then
  begin
    ShowMessage('Reference Id is missing!');
    exit
  end;

  recoveryRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  recoveryRes := frmMain.spi.InitiateRecovery(frmActions.edtAction1.Text,
    TransactionType_Purchase);

  if (recoveryRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Recovery Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate recovery: ' +
      recoveryRes.Message + '. Please Retry.');
  end;
end;

procedure DoHeaderFooter;
begin
  frmMain.options.SetCustomerReceiptHeader
    (SanitizePrintText(frmActions.edtAction1.Text));
  frmMain.options.SetMerchantReceiptHeader
    (SanitizePrintText(frmActions.edtAction1.Text));
  frmMain.options.SetCustomerReceiptFooter
    (SanitizePrintText(frmActions.edtAction2.Text));
  frmMain.options.SetMerchantReceiptFooter
    (SanitizePrintText(frmActions.edtAction2.Text));

  frmActions.lblFlowMessage.Caption :=
    '# --> Receipt Header and Footer is entered';

  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.OK;
  frmActions.btnAction2.Visible := false;
  frmActions.btnAction3.Visible := false;
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

procedure TfrmActions.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmActions.btnAction1Click(Sender: TObject);
begin
  if (btnAction1.Caption = ComponentNames.CONFIRMCODE) then
  begin
    frmMain.spi.PairingConfirmCode;
  end
  else if (btnAction1.Caption = ComponentNames.CANCELPAIRING) then
  begin
    frmActions.btnAction1.Enabled := false;
    frmMain.spi.PairingCancel;
    frmTransactions.lblStatus.Color := clRed;
  end
  else if (btnAction1.Caption = ComponentNames.CANCEL) then
  begin
    frmActions.btnAction1.Enabled := false;
    frmMain.spi.CancelTransaction;
  end
  else if (btnAction1.Caption = ComponentNames.OK) then
  begin
    frmMain.spi.AckFlowEndedAndBackToIdle;
    TMyWorkerThread.Create(false);
    frmMain.Enabled := True;
    frmMain.btnMain.Enabled := True;
    frmTransactions.Enabled := True;
    Hide;
  end
  else if (btnAction1.Caption = ComponentNames.OKUNPAIRED) then
  begin
    frmMain.spi.AckFlowEndedAndBackToIdle;
    frmMain.btnMain.Caption := ComponentNames.PAIR;
    frmTransactions.lblStatus.Color := clRed;
    frmMain.pnlSecrets.Enabled := True;
    frmMain.pnlAutoAddressResolution.Enabled := True;
    frmMain.pnlSettings.Enabled := True;
    frmMain.chkSecrets.Checked := false;
    frmMain.Enabled := True;
    frmMain.Show;
    frmTransactions.Hide;
    Hide;
  end
  else if (btnAction1.Caption = ComponentNames.ACCEPTSIGNATURE) then
  begin
    frmMain.spi.ACCEPTSIGNATURE(True);
  end
  else if (btnAction1.Caption = ComponentNames.RETRY) then
  begin
    frmMain.spi.AckFlowEndedAndBackToIdle;
    frmActions.richEdtFlow.Lines.clear;
    if (frmMain.spi.CurrentTxFlowState.type_ = TransactionType_Purchase) then
    begin
      DoPurchase;
    end
    else if (frmMain.spi.CurrentTxFlowState.type_ = TransactionType_Refund) then
    begin
      DoRefund;
    end
    else if (frmMain.spi.CurrentTxFlowState.type_ = TransactionType_CashoutOnly)
    then
    begin
      DoCashOut;
    end
    else if (frmMain.spi.CurrentTxFlowState.type_ = TransactionType_MOTO) then
    begin
      DoMoto;
    end
    else
    begin
      frmActions.lblFlowMessage.Caption :=
        'Retry by selecting from the options';
      TMyWorkerThread.Create(false);
    end;
  end
  else if (btnAction1.Caption = ComponentNames.purchase) then
  begin
    DoPurchase;
  end
  else if (btnAction1.Caption = ComponentNames.refund) then
  begin
    DoRefund;
  end
  else if (btnAction1.Caption = ComponentNames.CASHOUT) then
  begin
    DoCashOut;
  end
  else if (btnAction1.Caption = ComponentNames.MOTO) then
  begin
    DoMoto;
  end
  else if (btnAction1.Caption = ComponentNames.RECOVERY) then
  begin
    DoRecovery;
  end
  else if (btnAction1.Caption = ComponentNames.SETPRINT) then
  begin
    DoHeaderFooter;
  end
  else if (btnAction1.Caption = ComponentNames.PRINT) then
  begin
    frmMain.spi.PrintReport(frmActions.edtAction1.Text,
      SanitizePrintText(frmActions.edtAction2.Text));
  end;
end;

procedure TfrmActions.btnAction2Click(Sender: TObject);
begin
  if (btnAction2.Caption = ComponentNames.CANCELPAIRING) then
  begin
    frmMain.spi.PairingCancel;
    frmTransactions.lblStatus.Color := clRed;
  end
  else if (btnAction2.Caption = ComponentNames.DECLINESIGNATURE) then
  begin
    frmMain.spi.ACCEPTSIGNATURE(false);
  end
  else if (btnAction2.Caption = ComponentNames.CANCEL) then
  begin
    frmMain.spi.AckFlowEndedAndBackToIdle;
    frmActions.richEdtFlow.Lines.clear;
    TMyWorkerThread.Create(false);
    frmTransactions.Enabled := True;
    Hide
  end;
end;

procedure TfrmActions.btnAction3Click(Sender: TObject);
begin
  if (btnAction3.Caption = ComponentNames.CANCEL) then
  begin
    frmMain.spi.CancelTransaction;
  end;
end;

end.
