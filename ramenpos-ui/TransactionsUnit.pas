unit TransactionsUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  ComObj,
  ActionsUnit,
  ComponentNames,
  ActiveX,
  SPIClient_TLB, Vcl.Menus;

type
  TfrmTransactions = class(TForm)
    pnlSettings: TPanel;
    lblSettings: TLabel;
    pnlStatus: TPanel;
    lblStatusHead: TLabel;
    lblStatus: TLabel;
    pnlReceipt: TPanel;
    lblReceipt: TLabel;
    richEdtReceipt: TRichEdit;
    pnlTransActions: TPanel;
    btnPurchase: TButton;
    btnRefund: TButton;
    btnSettle: TButton;
    btnSettleEnq: TButton;
    btnMoto: TButton;
    btnCashOut: TButton;
    lblTransActions: TLabel;
    cboxReceiptFromEftpos: TCheckBox;
    cboxSignFromEftpos: TCheckBox;
    cboxPrintMerchantCopy: TCheckBox;
    btnSecrets: TButton;
    btnLastTx: TButton;
    btnRecovery: TButton;
    pnlOtherActions: TPanel;
    lblOtherActions: TLabel;
    btnTerminalSettings: TButton;
    btnFreeformReceipt: TButton;
    btnHeaderFooter: TButton;
    btnTerminalStatus: TButton;
    mainMenuTransactions: TMainMenu;
    menuItemPairingSettings: TMenuItem;
    menuItemSecrets: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRefundClick(Sender: TObject);
    procedure btnSettleClick(Sender: TObject);
    procedure btnPurchaseClick(Sender: TObject);
    procedure btnSettleEnqClick(Sender: TObject);
    procedure btnCashOutClick(Sender: TObject);
    procedure btnMotoClick(Sender: TObject);
    procedure btnLastTxClick(Sender: TObject);
    procedure menuItemPairingSettingsClick(Sender: TObject);
    procedure btnRecoveryClick(Sender: TObject);
    procedure cboxReceiptFromEftposClick(Sender: TObject);
    procedure cboxSignFromEftposClick(Sender: TObject);
    procedure cboxPrintMerchantCopyClick(Sender: TObject);
    procedure btnHeaderFooterClick(Sender: TObject);
    procedure btnFreeformReceiptClick(Sender: TObject);
    procedure btnTerminalStatusClick(Sender: TObject);
    procedure btnTerminalSettingsClick(Sender: TObject);
    procedure menuItemSecretsClick(Sender: TObject);
  private

  public

  end;

var
  UseSynchronize, UseQueue: Boolean;

implementation

{$R *.dfm}

uses MainUnit;

function FormExists(apForm: TForm): Boolean;
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

procedure TfrmTransactions.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (FormExists(frmActions)) then
  begin
    frmActions.Close;
    frmMain.Close;
  end;

  Action := caFree;
end;

procedure TfrmTransactions.FormCreate(Sender: TObject);
begin
  frmMain.pnlSecrets.Enabled := False;
  frmMain.pnlAutoAddressResolution.Enabled := False;
  frmMain.pnlSettings.Enabled := False;
end;

procedure TfrmTransactions.menuItemPairingSettingsClick(Sender: TObject);
begin
  frmMain.menuItemTransactions.Visible := True;
  frmMain.pnlSecrets.Enabled := False;
  frmMain.pnlAutoAddressResolution.Enabled := False;
  frmMain.pnlSettings.Enabled := False;
  Hide;
  frmMain.Show;
end;

procedure TfrmTransactions.menuItemSecretsClick(Sender: TObject);
begin
  frmMain.CheckFormActions;
  frmActions.richEdtFlow.Clear;

  if (frmMain.SpiSecrets <> nil) then
  begin
    frmActions.richEdtFlow.Lines.Add('Pos Id: ' + frmMain.posId);
    frmActions.richEdtFlow.Lines.Add('Eftpos Address: ' +
      frmMain.eftposAddress);
    frmActions.richEdtFlow.Lines.Add('Secrets: ' + frmMain.SpiSecrets.encKey +
      ':' + frmMain.SpiSecrets.hmacKey);
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('I have no secrets!');
  end;

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
  frmTransactions.Enabled := False;
end;

procedure TfrmTransactions.btnPurchaseClick(Sender: TObject);
begin
  frmMain.CheckFormActions;
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
  frmActions.lblAction2.Caption := ComponentNames.TIPAMOUNT;
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
  frmTransactions.Enabled := False;
end;

procedure TfrmTransactions.btnRecoveryClick(Sender: TObject);
begin
  frmMain.CheckFormActions;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the reference id you would like to recovery';
  frmActions.btnAction1.Enabled := True;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.RECOVERY;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := ComponentNames.REFERENCE;
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := False;
  frmActions.edtAction2.Visible := False;
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmTransactions.Enabled := False;
end;

procedure TfrmTransactions.btnRefundClick(Sender: TObject);
begin
  frmMain.CheckFormActions;
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
  frmTransactions.Enabled := False;
end;

procedure TfrmTransactions.btnCashOutClick(Sender: TObject);
begin
  frmMain.CheckFormActions;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to cashout for in cents';
  frmActions.btnAction1.Enabled := True;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.CASHOUT;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := ComponentNames.AMOUNT;
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '0';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := ComponentNames.SURCHARGEAMOUNT;
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '0';
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmTransactions.Enabled := False;
end;

procedure TfrmTransactions.btnMotoClick(Sender: TObject);
begin
  frmMain.CheckFormActions;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the amount you would like to moto for in cents';
  frmActions.btnAction1.Enabled := True;
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.MOTO;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := ComponentNames.AMOUNT;
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '0';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := ComponentNames.SURCHARGEAMOUNT;
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '0';
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := True;
  frmActions.cboxAction1.Caption := ComponentNames.SUPPRESSMERCHANTPASSWORD;
  frmTransactions.Enabled := False;
end;

procedure TfrmTransactions.btnSettleClick(Sender: TObject);
var
  settleres: SPIClient_TLB.InitiateTxResult;
begin
  frmMain.CheckFormActions;
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
  frmTransactions.Enabled := False;

  settleres := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  settleres := frmMain.Spi.InitiateSettleTx_2
    (frmMain.ComWrapper.Get_Id('settle'), frmMain.options);

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

procedure TfrmTransactions.btnSettleEnqClick(Sender: TObject);
var
  senqres: SPIClient_TLB.InitiateTxResult;
begin
  frmMain.CheckFormActions;
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
  frmTransactions.Enabled := False;

  senqres := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;

  senqres := frmMain.Spi.InitiateSettlementEnquiry_2
    (frmMain.ComWrapper.Get_Id('stlenq'), frmMain.options);

  if (senqres.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Settle Enquiry Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate settlement enquiry: '
      + senqres.Message + '. Please Retry.');
  end;
end;

procedure TfrmTransactions.btnTerminalSettingsClick(Sender: TObject);
begin
  frmMain.Spi.GetTerminalConfiguration;
end;

procedure TfrmTransactions.btnTerminalStatusClick(Sender: TObject);
begin
  frmMain.Spi.GetTerminalStatus;
end;

procedure TfrmTransactions.cboxPrintMerchantCopyClick(Sender: TObject);
begin
  frmMain.Spi.Config.PrintMerchantCopy :=
    frmTransactions.cboxPrintMerchantCopy.Checked;
end;

procedure TfrmTransactions.cboxReceiptFromEftposClick(Sender: TObject);
begin
  frmMain.Spi.Config.PromptForCustomerCopyOnEftpos :=
    frmTransactions.cboxReceiptFromEftpos.Checked;
end;

procedure TfrmTransactions.cboxSignFromEftposClick(Sender: TObject);
begin
  frmMain.Spi.Config.SignatureFlowOnEftpos :=
    frmTransactions.cboxSignFromEftpos.Checked;
end;

procedure TfrmTransactions.btnFreeformReceiptClick(Sender: TObject);
begin
  frmMain.CheckFormActions;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the print text and key you would like to print receipt';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.SETPRINT;
  frmActions.btnAction2.Visible := True;
  frmActions.btnAction2.Caption := ComponentNames.CANCEL;
  frmActions.btnAction3.Visible := False;
  frmActions.lblAction1.Visible := True;
  frmActions.lblAction1.Caption := ComponentNames.KEY;
  frmActions.edtAction1.Visible := True;
  frmActions.edtAction1.Text := '';
  frmActions.lblAction2.Visible := True;
  frmActions.lblAction2.Caption := ComponentNames.PRINTTEXT;
  frmActions.edtAction2.Visible := True;
  frmActions.edtAction2.Text := '';
  frmActions.lblAction3.Visible := False;
  frmActions.edtAction3.Visible := False;
  frmActions.lblAction4.Visible := False;
  frmActions.edtAction4.Visible := False;
  frmActions.cboxAction1.Visible := False;
  frmTransactions.Enabled := False;
end;

procedure TfrmTransactions.btnHeaderFooterClick(Sender: TObject);
begin
  frmMain.CheckFormActions;
  frmActions.lblFlowMessage.Caption :=
    'Please enter the receipt header and footer you would like to print';
  frmActions.btnAction1.Visible := True;
  frmActions.btnAction1.Caption := ComponentNames.PRINT;
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
  frmTransactions.Enabled := False;
end;

procedure TfrmTransactions.btnLastTxClick(Sender: TObject);
var
  lastTxRes: SPIClient_TLB.InitiateTxResult;
begin
  frmMain.CheckFormActions;
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
  frmTransactions.Enabled := False;

  lastTxRes := CreateComObject(CLASS_InitiateTxResult)
    AS SPIClient_TLB.InitiateTxResult;
  lastTxRes := frmMain.Spi.InitiateGetLastTx();

  if (lastTxRes.Initiated) then
  begin
    frmActions.richEdtFlow.Lines.Add
      ('# Last Transaction Initiated. Will be updated with Progress.');
  end
  else
  begin
    frmActions.richEdtFlow.Lines.Add('# Could not initiate last transaction: ' +
      lastTxRes.Message + '. Please Retry.');
  end;
end;

end.
