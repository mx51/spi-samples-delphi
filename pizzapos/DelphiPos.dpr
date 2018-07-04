program DelphiPos;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  SysUtils,
  Variants,
  TypInfo,
  Classes,
  Windows,
  ActiveX,
  ComObj,
  SPIClient_TLB;

var
  ComWrapper: SPIClient_TLB.ComWrapper;
  Spi: SPIClient_TLB.Spi;
  _posId, _eftposAddress: WideString;
  _spiSecrets: SPIClient_TLB.Secrets;

procedure ClearConsoleScreen;
const
  BUFSIZE = 80 * 25;
var
  stdout: THandle;
  csbi: TConsoleScreenBufferInfo;
  ConsoleSize: DWORD;
  NumWritten: DWORD;
  Origin: TCoord;
begin
  stdout := GetStdHandle(STD_OUTPUT_HANDLE);
  Win32Check(stdout <> INVALID_HANDLE_VALUE);
  Win32Check(GetConsoleScreenBufferInfo(stdout, csbi));
  ConsoleSize := csbi.dwSize.X * csbi.dwSize.Y;
  Origin.X := 0;
  Origin.Y := 0;
  Win32Check(FillConsoleOutputCharacter(stdout, ' ', ConsoleSize, Origin,
    NumWritten));
  Win32Check(FillConsoleOutputAttribute(stdout, csbi.wAttributes, ConsoleSize,
    Origin, NumWritten));
  Win32Check(SetConsoleCursorPosition(stdout, Origin));
end;

procedure Split(Delimiter: Char; Str: WideString; ListOfStrings: TStrings);
begin
  ListOfStrings.Clear;
  ListOfStrings.Delimiter := Delimiter;
  ListOfStrings.StrictDelimiter := true; // Requires D2006 or newer.
  ListOfStrings.DelimitedText := Str;
end;

procedure LoadPersistedState;
var
  argSplit: TStringList;
begin
  if (ParamCount <= 1) then
    exit;

  if (ParamStr(1) = null) then
    exit;

  argSplit := TStringList.Create;
  Split(':', ParamStr(1), argSplit);
  _posId := argSplit[0];
  _eftposAddress := argSplit[1];
  _spiSecrets := ComWrapper.SecretsInit(argSplit[2], argSplit[3]);
end;

procedure PrintFlowInfo();
var
  PurchaseResponse: SPIClient_TLB.PurchaseResponse;
  RefundResponse: SPIClient_TLB.RefundResponse;
  SettleResponse: SPIClient_TLB.Settlement;
begin
  PurchaseResponse := CreateComObject(CLASS_PurchaseResponse)
    AS SPIClient_TLB.PurchaseResponse;
  RefundResponse := CreateComObject(CLASS_RefundResponse)
    AS SPIClient_TLB.RefundResponse;
  SettleResponse := CreateComObject(CLASS_Settlement)
    AS SPIClient_TLB.Settlement;

  if (Spi.CurrentFlow = SpiFlow_Pairing) then
  begin
    WriteLn('### PAIRING PROCESS UPDATE ###');
    WriteLn('# ', Spi.CurrentPairingFlowState.Message);
    WriteLn('# Finished? ', Spi.CurrentPairingFlowState.Finished);
    WriteLn('# Successful? ', Spi.CurrentPairingFlowState.Successful);
    WriteLn('# Confirmation Code: ',
      Spi.CurrentPairingFlowState.ConfirmationCode);
    WriteLn('# Waiting Confirm from Eftpos? ',
      Spi.CurrentPairingFlowState.AwaitingCheckFromEftpos);
    WriteLn('# Waiting Confirm from POS? ',
      Spi.CurrentPairingFlowState.AwaitingCheckFromPos);
  end;

  if (Spi.CurrentFlow = SpiFlow_Transaction) then
  begin
    WriteLn('### TX PROCESS UPDATE ###');
    WriteLn('# ', Spi.CurrentTxFlowState.DisplayMessage);
    WriteLn('# Id: ', Spi.CurrentTxFlowState.Id);
    WriteLn('# Type: ', ComWrapper.GetTransactionTypeEnumName
      (Spi.CurrentTxFlowState.type_));
    WriteLn('# Amount: ', IntToStr(Spi.CurrentTxFlowState.AmountCents div 100));
    WriteLn('# Waiting For Signature: ',
      Spi.CurrentTxFlowState.AwaitingSignatureCheck);
    WriteLn('# Attempting to Cancel : ',
      Spi.CurrentTxFlowState.AttemptingToCancel);
    WriteLn('# Finished: ', Spi.CurrentTxFlowState.Finished);
    WriteLn('# Success: ', ComWrapper.GetSuccessStateEnumName
      (Spi.CurrentTxFlowState.Success));

    if (Spi.CurrentTxFlowState.Finished) then
    begin
      WriteLn('');
      Case Spi.CurrentTxFlowState.Success of
        SuccessState_Success:
          if (Spi.CurrentTxFlowState.type_ = TransactionType_Purchase) then
          begin
            WriteLn('# WOOHOO - WE GOT PAID!');
            PurchaseResponse := ComWrapper.PurchaseResponseInit
              (Spi.CurrentTxFlowState.Response);
            WriteLn('# Response: ', PurchaseResponse.GetResponseText);
            WriteLn('# RRN: ', PurchaseResponse.GetRRN);
            WriteLn('# Scheme: ', PurchaseResponse.SchemeName);
            WriteLn('# Customer Receipt:');
            WriteLn(TrimRight(PurchaseResponse.GetCustomerReceipt));
          end
          else
          begin
            if (Spi.CurrentTxFlowState.type_ = TransactionType_Refund) then
            begin
              WriteLn('# REFUND GIVEN - OH WELL!');
              RefundResponse := ComWrapper.RefundResponseInit
                (Spi.CurrentTxFlowState.Response);
              WriteLn('# Response: ', RefundResponse.GetResponseText);
              WriteLn('# RRN: ', RefundResponse.GetRRN());
              WriteLn('# Scheme: ', RefundResponse.SchemeName);
              WriteLn('# Customer Receipt:');
              WriteLn(TrimRight(RefundResponse.GetCustomerReceipt));
            end
            else
            begin
              if (Spi.CurrentTxFlowState.type_ = TransactionType_Settle) then
              begin
                WriteLn('# SETTLEMENT SUCCESSFUL!');
                if (Spi.CurrentTxFlowState.Response <> nil) then
                begin
                  SettleResponse := ComWrapper.SettlementInit
                    (Spi.CurrentTxFlowState.Response);
                  WriteLn('# Response: ', SettleResponse.GetResponseText);
                  WriteLn('# Merchant Receipt:');
                  WriteLn(TrimRight(SettleResponse.GetReceipt));
                end;
              end;
            end;
          end;

        SuccessState_Failed:
          if (Spi.CurrentTxFlowState.type_ = TransactionType_Purchase) then
          begin
            WriteLn('# WE DID NOT GET PAID :(');
            if (Spi.CurrentTxFlowState.Response <> nil) then
            begin
              PurchaseResponse := ComWrapper.PurchaseResponseInit
                (Spi.CurrentTxFlowState.Response);
              WriteLn('# Error: ', Spi.CurrentTxFlowState.Response.GetError);
              WriteLn('# Response: ', PurchaseResponse.GetResponseText);
              WriteLn('# RRN: ', PurchaseResponse.GetRRN);
              WriteLn('# Scheme: ', PurchaseResponse.SchemeName);
              WriteLn('# Customer Receipt:');
              WriteLn(TrimRight(PurchaseResponse.GetCustomerReceipt));
            end;
          end
          else
          begin
            if (Spi.CurrentTxFlowState.type_ = TransactionType_Refund) then
            begin
              WriteLn('# REFUND FAILED!');

              if (Spi.CurrentTxFlowState.Response <> nil) then
              begin
                RefundResponse := ComWrapper.RefundResponseInit
                  (Spi.CurrentTxFlowState.Response);
                WriteLn('# Response: ', RefundResponse.GetResponseText);
                WriteLn('# RRN: ', RefundResponse.GetRRN);
                WriteLn('# Scheme: ', RefundResponse.SchemeName);
                WriteLn('# Customer Receipt:');
                WriteLn(TrimRight(RefundResponse.GetCustomerReceipt));
              end;
            end
            else
            begin
              if (Spi.CurrentTxFlowState.type_ = TransactionType_Settle) then
              begin
                WriteLn('# SETTLEMENT FAILED!');

                if (Spi.CurrentTxFlowState.Response <> nil) then
                begin
                  SettleResponse := ComWrapper.SettlementInit
                    (Spi.CurrentTxFlowState.Response);
                  WriteLn('# Response: ', SettleResponse.GetResponseText);
                  WriteLn('# Error: ',
                    Spi.CurrentTxFlowState.Response.GetError);
                  WriteLn('# Merchant Receipt:');
                  WriteLn(TrimRight(SettleResponse.GetReceipt));
                end;
              end;
            end;
          end;

        SuccessState_Unknown:
          if (Spi.CurrentTxFlowState.type_ = TransactionType_Purchase) then
          begin
            WriteLn('# WE''RE NOT QUITE SURE WHETHER WE GOT PAID OR NOT :/');
            WriteLn('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
            WriteLn('# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.');
            WriteLn('# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.');
          end
          else
          begin
            if (Spi.CurrentTxFlowState.type_ = TransactionType_Refund) then
            begin
              WriteLn('# WE''RE NOT QUITE SURE WHETHER THE REFUND WENT THROUGH OR NOT :/');
              WriteLn('# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.');
              WriteLn('# YOU CAN THE TAKE THE APPROPRIATE ACTION.');
            end;
          end;
      end;
    end;
  end;
  WriteLn('');
end;

procedure PrintActions();
begin
  WriteLn('# ----------- AVAILABLE ACTIONS ------------');

  if (Spi.CurrentFlow = SpiFlow_Idle) then
  begin
    WriteLn('# [pizza:funghi] - charge for a pizza!');
    WriteLn('# [yuck] - hand out a refund!');
    WriteLn('# [settle] - Initiate Settlement');
  end;

  if (Spi.CurrentStatus = SpiStatus_Unpaired) and
    (Spi.CurrentFlow = SpiFlow_Idle) then
  begin
    WriteLn('# [pos_id:CITYPIZZA1] - Set the POS ID');
    WriteLn('# [eftpos_address:10.161.104.104] - Set the EFTPOS ADDRESS');
  end;

  if (Spi.CurrentStatus = SpiStatus_Unpaired) and
    (Spi.CurrentFlow = SpiFlow_Idle) then
    WriteLn('# [pair] - Pair with Eftpos');

  if (Spi.CurrentStatus <> SpiStatus_Unpaired) and
    (Spi.CurrentFlow = SpiFlow_Idle) then
    WriteLn('# [unpair] - Unpair and Disconnect');

  if (Spi.CurrentFlow = SpiFlow_Pairing) then
  begin
    WriteLn('# [pair_cancel] - Cancel Pairing');

    if (Spi.CurrentPairingFlowState.AwaitingCheckFromPos) then
      WriteLn('# [pair_confirm] - Confirm Pairing Code');

    if (Spi.CurrentPairingFlowState.Finished) then
      WriteLn('# [ok] - acknowledge final');
  end;

  if (Spi.CurrentFlow = SpiFlow_Transaction) then
  begin
    if (Spi.CurrentTxFlowState.AwaitingSignatureCheck) then
    begin
      WriteLn('# [tx_sign_accept] - Accept Signature');
      WriteLn('# [tx_sign_decline] - Decline Signature');
    end;

    if (not Spi.CurrentTxFlowState.Finished) and
      (not Spi.CurrentTxFlowState.AttemptingToCancel) then
      WriteLn('# [tx_cancel] - Attempt to Cancel Tx');

    if (Spi.CurrentTxFlowState.Finished) then
      WriteLn('# [ok] - acknowledge final');
  end;

  WriteLn('# [status] - reprint buttons/status');
  WriteLn('# [bye] - exit');
  WriteLn('');
end;

procedure PrintPairingStatus();
begin
  WriteLn('# --------------- STATUS ------------------');
  WriteLn('# ', _posId, ' <-> Eftpos: ', _eftposAddress, ' #');
  WriteLn('# SPI STATUS: ', ComWrapper.GetSpiStatusEnumName(Spi.CurrentStatus),
    '     FLOW: ', ComWrapper.GetSpiFlowEnumName(Spi.CurrentFlow), ' #');
  WriteLn('# CASH ONLY! #');
  WriteLn('# -----------------------------------------');
end;

procedure PrintStatusAndActions();
begin
  PrintFlowInfo();
  PrintActions();
  PrintPairingStatus();
end;

procedure AcceptUserInput();
var
  bye: boolean;
  input: WideString;
  spInput: TStringList;
  pres: SPIClient_TLB.InitiateTxResult;
  yuckres: SPIClient_TLB.InitiateTxResult;
  settleres: SPIClient_TLB.InitiateTxResult;
begin

  bye := false;
  while not bye do
  begin
    Readln(input);
    spInput := TStringList.Create;
    Split(':', input, spInput);

    if (spInput.Count = 0) then
    begin
      Write('> ');
    end

    else if (spInput[0] = 'pizza') then
    begin
      pres := CreateComObject(CLASS_InitiateTxResult)
        AS SPIClient_TLB.InitiateTxResult;
      pres := Spi.InitiatePurchaseTx(ComWrapper.Get_Id('pizza'), 1000);
      if (not pres.Initiated) then
      begin
        WriteLn('# Could not initiate purchase: ', pres.Message,
          '. Please Retry.');
      end;
    end
    else if (spInput[0] = 'yuck') then
    begin
      yuckres := CreateComObject(CLASS_InitiateTxResult)
        AS SPIClient_TLB.InitiateTxResult;
      yuckres := Spi.InitiateRefundTx(ComWrapper.Get_Id('yuck'), 1000);
      if (not yuckres.Initiated) then
      begin
        WriteLn('# Could not initiate refund: ', yuckres.Message,
          '. Please Retry.');
      end;
    end

    else if (spInput[0] = 'pos_id') then
    begin
      ClearConsoleScreen;
      if (spInput.Count <> 2) then
      begin
        WriteLn('## -> Plese set POS ID');
      end

      else if (Spi.SetPosId(spInput[1])) then
      begin
        _posId := spInput[1];
        WriteLn('## -> POS ID now set to ', _posId);
      end

      else
      begin
        WriteLn('## -> Could not set POS ID');
      end;

      PrintStatusAndActions;
      Write('> ');
    end

    else if (spInput[0] = 'eftpos_address') then
    begin
      ClearConsoleScreen;
      if (spInput.Count <> 2) then
      begin
        WriteLn('## -> Plese set Eftpos Address');
      end

      else if (Spi.SetEftposAddress(spInput[1])) then
      begin
        _eftposAddress := spInput[1];
        WriteLn('## -> Eftpos Address now set to ', _eftposAddress);
      end

      else
      begin
        WriteLn('## -> Could not set Eftpos Address');
      end;

      PrintStatusAndActions();
      Write('> ');
    end

    else if (spInput[0] = 'pair') then
    begin
      Spi.Pair;
    end

    else if (spInput[0] = 'pair_cancel') then
    begin
      Spi.PairingCancel;
    end

    else if (spInput[0] = 'pair_confirm') then
    begin
      Spi.PairingConfirmCode;
    end

    else if (spInput[0] = 'unpair') then
    begin
      Spi.Unpair;
    end

    else if (spInput[0] = 'tx_sign_accept') then
    begin
      Spi.AcceptSignature(true);
    end

    else if (spInput[0] = 'tx_sign_decline') then
    begin
      Spi.AcceptSignature(false);
    end

    else if (spInput[0] = 'tx_cancel') then
    begin
      Spi.CancelTransaction;
    end

    else if (spInput[0] = 'settle') then
    begin
      settleres := CreateComObject(CLASS_InitiateTxResult)
        AS SPIClient_TLB.InitiateTxResult;

      settleres := Spi.InitiateSettleTx(ComWrapper.Get_Id('settle'));
      if (not settleres.Initiated) then
        WriteLn('# Could not initiate settlement: ', settleres.Message,
          '. Please Retry.');
    end

    else if (spInput[0] = 'ok') then
    begin
      ClearConsoleScreen;
      Spi.AckFlowEndedAndBackToIdle;
      PrintStatusAndActions;
      Write('> ');
    end

    else if (spInput[0] = 'status') then
    begin
      ClearConsoleScreen;
      PrintStatusAndActions;
    end

    else if (spInput[0] = 'bye') then
    begin
      bye := true;
    end

    else
      WriteLn('# I don''t understand. Sorry.');
  end;

  WriteLn('# BaBye!');
  if (_spiSecrets <> nil) then
    WriteLn('', _posId, ':', _eftposAddress, ':', _spiSecrets.EncKEY, ':',
      _spiSecrets.HmacKey);

end;

procedure TxFlowStateChanged(e: SPIClient_TLB.TransactionFlowState); stdcall;
begin
  ClearConsoleScreen;
  PrintStatusAndActions;
  Write('> ');
end;

procedure PairingFlowStateChanged(e: SPIClient_TLB.PairingFlowState); stdcall;
begin
  ClearConsoleScreen;
  PrintStatusAndActions;
  Write('> ');
end;

procedure SecretsChanged(e: SPIClient_TLB.Secrets); stdcall;
begin
  _spiSecrets := e;
  if (_spiSecrets <> nil) then
  begin
    WriteLn('# I Have Secrets: ', _spiSecrets.EncKEY, _spiSecrets.HmacKey,
      '. Persist them Securely');
  end
  else
  begin
    WriteLn('# I Have Lost the Secrets, i.e. Unpaired. Destroy the persisted secrets.');
  end;
end;

procedure SpiStatusChanged(e: SPIClient_TLB.SpiStatusEventArgs); stdcall;
begin
  ClearConsoleScreen;
  WriteLn('# --> SPI Status Changed: ',
    ComWrapper.GetSpiStatusEnumName(e.SpiStatus));
  PrintStatusAndActions;
  Write('> ');
end;

procedure MainPrint();
begin
  ClearConsoleScreen;
  WriteLn('# Welcome to DelphiPos !');
  PrintStatusAndActions;
  Write('> ');
  AcceptUserInput;
end;

begin
  try
    ComWrapper := CreateComObject(CLASS_ComWrapper) AS SPIClient_TLB.ComWrapper;
    Spi := CreateComObject(CLASS_Spi) AS SPIClient_TLB.Spi;
    _spiSecrets := CreateComObject(CLASS_Secrets) AS SPIClient_TLB.Secrets;

    LoadPersistedState;
    _posId := '';
    _eftposAddress := '';
    _spiSecrets := nil;
    Spi := ComWrapper.SpiInit(_posId, _eftposAddress, _spiSecrets);
    ComWrapper.Main(Spi, LongInt(@TxFlowStateChanged),
      LongInt(@PairingFlowStateChanged), LongInt(@SecretsChanged),
      LongInt(@SpiStatusChanged));
    Spi.Start;
    MainPrint;
  except
    on e: Exception do

    begin
      WriteLn(e.ClassName, ': ', e.Message);
      Readln;
    end;
  end;
  Readln;

end.
