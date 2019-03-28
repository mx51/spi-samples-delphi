unit ActionsUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, ComObj, SPIClient_TLB;

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
    { Private declarations }
  public

  end;

implementation

{$R *.dfm}

uses MainUnit, ComponentNames;

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

procedure DoOpen;
var
  initRes: SPIClient_TLB.InitiateTxResult;
  amount: Integer;
begin
  amount := StrToInt(frmActions.edtAction1.Text);
  initRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  initRes := frmMain.SpiPreauth.InitiateOpenTx_2
    ('propen-' + FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), amount,
    frmMain.options);

  if (initRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Preauth request Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate preauth request: ' +
      initRes.Message + '. Please Retry.');
  end;
end;

procedure DoTopUp;
var
  initRes: SPIClient_TLB.InitiateTxResult;
  amount: Integer;
begin
  amount := StrToInt(frmActions.edtAction2.Text);
  initRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  initRes := frmMain.SpiPreauth.InitiateTopupTx_2
    ('prtopup-' + frmActions.edtAction1.Text + '-' +
    FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), frmActions.edtAction1.Text,
    amount, frmMain.options);

  if (initRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Preauth request initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate preauth request: ' +
      initRes.Message + '. Please Retry.');
  end;
end;

procedure DoTopDown;
var
  initRes: SPIClient_TLB.InitiateTxResult;
  amount: Integer;
begin
  amount := StrToInt(frmActions.edtAction2.Text);
  initRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  initRes := frmMain.SpiPreauth.InitiatePartialCancellationTx_2
    ('prtopd-' + frmActions.edtAction1.Text + '-' +
    FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), frmActions.edtAction1.Text,
    amount, frmMain.options);

  if (initRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Preauth request initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate preauth request: ' +
      initRes.Message + '. Please Retry.');
  end;
end;

procedure DoExtend;
var
  initRes: SPIClient_TLB.InitiateTxResult;
begin
  initRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  initRes := frmMain.SpiPreauth.InitiateExtendTx_2
    ('prtopd-' + frmActions.edtAction1.Text + '-' +
    FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), frmActions.edtAction1.Text,
    frmMain.options);

  if (initRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Preauth request initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate preauth request: ' +
      initRes.Message + '. Please Retry.');
  end;
end;

procedure DoComplete;
var
  initRes: SPIClient_TLB.InitiateTxResult;
  amount, surchargeAmount: Integer;
begin
  amount := StrToInt(frmActions.edtAction2.Text);
  surchargeAmount := StrToInt(frmActions.edtAction3.Text);
  initRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  initRes := frmMain.SpiPreauth.InitiateCompletionTx_3
    ('prcomp-' + frmActions.edtAction1.Text + '-' +
    FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), frmActions.edtAction1.Text,
    amount, surchargeAmount, frmMain.options);

  if (initRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Preauth request initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate preauth request: ' +
      initRes.Message + '. Please Retry.');
  end;
end;

procedure DoCancel;
var
  initRes: SPIClient_TLB.InitiateTxResult;
begin
  initRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  initRes := frmMain.SpiPreauth.InitiateCancelTx_2
    ('prtopd-' + frmActions.edtAction1.Text + '-' +
    FormatDateTime('dd-mm-yyyy-hh-nn-ss', Now), frmActions.edtAction1.Text,
    frmMain.options);

  if (initRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Preauth request initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate preauth request: ' +
      initRes.Message + '. Please Retry.');
  end;
end;

procedure DoRecovery;
var
  rres: SPIClient_TLB.InitiateTxResult;
begin
  if (frmActions.edtAction1.Text = '') then
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

    rres := CreateComObject(CLASS_InitiateTxResult)
      AS SPIClient_TLB.InitiateTxResult;

    rres := frmMain.spi.InitiateRecovery(frmActions.edtAction1.Text,
      TransactionType_Purchase);

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

  frmActions.btnAction1.Enabled := True;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.OK;
  frmActions.btnAction2.Visible := False;
  frmActions.btnAction3.Visible := False;
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
    frmActions.btnAction1.Enabled := False;
    frmMain.spi.PairingCancel;
    frmMain.lblStatus.Color := clRed;
  end
  else if (btnAction1.Caption = ComponentNames.CANCEL) then
  begin
    frmActions.btnAction1.Enabled := False;
    frmMain.spi.CancelTransaction;
  end
  else if (btnAction1.Caption = ComponentNames.OK) then
  begin
    frmMain.spi.AckFlowEndedAndBackToIdle;
    TMyWorkerThread.Create(False);
    frmMain.Enabled := True;
    frmMain.btnPair.Enabled := True;
    frmMain.edtPosID.Enabled := True;
    frmMain.edtEftposAddress.Enabled := True;
    Hide;
  end
  else if (btnAction1.Caption = ComponentNames.OKUNPAIRED) then
  begin
    frmMain.spi.AckFlowEndedAndBackToIdle;
    frmMain.btnPair.Caption := ComponentNames.PAIR;
    frmMain.lblStatus.Color := clRed;
    frmMain.btnPair.Enabled := True;
    frmMain.edtPosID.Enabled := True;
    frmMain.edtEftposAddress.Enabled := True;
    frmMain.pnlPreAuthActions.Visible := False;
    frmMain.pnlEftposSettings.Visible := False;
    frmMain.pnlOtherActions.Visible := False;
    frmMain.lblStatus.Color := clRed;
    frmMain.Enabled := True;
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
    frmActions.lblFlowMessage.Caption := 'Retry by selecting from the options';
    TMyWorkerThread.Create(False);
  end
  else if (btnAction1.Caption = 'Open') then
  begin
    DoOpen;
  end
  else if (btnAction1.Caption = 'Top Up') then
  begin
    DoTopUp;
  end
  else if (btnAction1.Caption = 'Top Down') then
  begin
    DoTopDown;
  end
  else if (btnAction1.Caption = 'Extend') then
  begin
    DoExtend;
  end
  else if (btnAction1.Caption = 'Complete') then
  begin
    DoComplete;
  end
  else if (btnAction1.Caption = 'PreAuth Cancel') then
  begin
    DoCancel;
  end
  else if (btnAction1.Caption = ComponentNames.SETPRINT) then
  begin
    DoHeaderFooter;
  end
  else if (btnAction1.Caption = ComponentNames.PRINT) then
  begin
    frmMain.spi.PrintReport(frmActions.edtAction1.Text,
      SanitizePrintText(frmActions.edtAction2.Text));
  end
end;

procedure TfrmActions.btnAction2Click(Sender: TObject);
begin
  if (btnAction2.Caption = 'Cancel Pairing') then
  begin
    frmMain.spi.PairingCancel;
    frmMain.lblStatus.Color := clRed;
  end
  else if (btnAction2.Caption = 'Decline Signature') then
  begin
    frmMain.spi.ACCEPTSIGNATURE(False);
  end
  else if (btnAction2.Caption = 'Cancel') then
  begin
    frmMain.spi.AckFlowEndedAndBackToIdle;
    frmActions.richEdtFlow.Lines.clear;
    TMyWorkerThread.Create(False);
    frmMain.Enabled := True;
    Hide
  end;
end;

procedure TfrmActions.btnAction3Click(Sender: TObject);
begin
  if (btnAction3.Caption = 'Cancel') then
  begin
    frmMain.spi.CancelTransaction;
  end;
end;

end.
