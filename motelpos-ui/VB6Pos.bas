Attribute VB_Name = "VB6Pos"
Option Explicit

Public spi As SPIClient.spi
Public comWrapper As SPIClient.comWrapper
Public posId, eftposAddress As String
Public spiSecrets As SPIClient.Secrets
Public spiPreauth As SPIClient.spiPreauth

Sub Start()
    LoadPersistedState

    posId = frmMain.txtPosId.Text
    eftposAddress = frmMain.txtEftposAddress.Text
    
    Set spi = comWrapper.SpiInit(posId, eftposAddress, spiSecrets)
    
    comWrapper.Main spi, AddressOf TxFlowStateChanged, AddressOf PairingFlowStateChanged, AddressOf SecretsChanged, AddressOf SpiStatusChanged
    Set spiPreauth = spi.EnablePreauth
    
    spi.Start
    
    PrintStatusAndActions
End Sub

Private Sub TxFlowStateChanged(ByVal e As SPIClient.TransactionFlowState)
    frmActions.Show
    frmActions.listFlow.Clear
    
    PrintFlowInfo
    
    PrintStatusAndActions
End Sub

Private Sub PairingFlowStateChanged(ByVal e As SPIClient.PairingFlowState)
    frmActions.Show
    frmActions.listFlow.Clear
    frmActions.lblFlowMessage.Caption = e.Message
    
    If e.ConfirmationCode <> "" Then
        frmActions.listFlow.AddItem "# Confirmation Code: " + e.ConfirmationCode
    End If

    PrintFlowInfo
    PrintStatusAndActions
End Sub

Private Sub SecretsChanged(ByVal e As SPIClient.Secrets)
    Set spiSecrets = e
End Sub

Private Sub SpiStatusChanged(ByVal e As SPIClient.SpiStatusEventArgs)
    If IsOpenForm("frmMain") Then
        frmActions.Show
        frmActions.lblFlowMessage.Caption = "It's trying to connect"
    
        If spi.CurrentFlow = SpiFlow_Idle Then
            frmActions.listFlow.Clear
        End If
    
        PrintFlowInfo
        PrintStatusAndActions
    End If
End Sub

Private Sub LoadPersistedState()
    If frmMain.txtSecrets.Text <> "" Then
        Dim outputList() As String
        outputList = Split(frmMain.txtSecrets.Text, ":", 2)
        Set spiSecrets = comWrapper.SecretsInit(outputList(0), outputList(1))
    End If
End Sub

Private Sub PrintFlowInfo()
    Dim preauthResponse As SPIClient.preauthResponse
    Dim acctVerifyResponse As SPIClient.AccountVerifyResponse
    Dim details As SPIClient.PurchaseResponse
    Dim txFlow As SPIClient.TransactionFlowState
    
    Set preauthResponse = New SPIClient.preauthResponse
    Set acctVerifyResponse = New SPIClient.AccountVerifyResponse
    
    If frmMain.richtxtReceipt.Text <> "" Then
        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + " "
    End If
    
    If (spi.CurrentFlow = SpiFlow_Pairing) Then
        frmActions.lblFlowMessage.Caption = spi.CurrentPairingFlowState.Message
        frmActions.listFlow.AddItem "### PAIRING PROCESS UPDATE ###"
        frmActions.listFlow.AddItem "# " + spi.CurrentPairingFlowState.Message
        frmActions.listFlow.AddItem "# Finished? " + CStr(spi.CurrentPairingFlowState.Finished)
        frmActions.listFlow.AddItem "# Successful? " + CStr(spi.CurrentPairingFlowState.Successful)
        frmActions.listFlow.AddItem "# Confirmation Code: " + spi.CurrentPairingFlowState.ConfirmationCode
        frmActions.listFlow.AddItem "# Waiting Confirm from Eftpos?: " + CStr(spi.CurrentPairingFlowState.AwaitingCheckFromEftpos)
        frmActions.listFlow.AddItem "# Waiting Confirm from POS? " + CStr(spi.CurrentPairingFlowState.AwaitingCheckFromPos)
    End If
    
    If (spi.CurrentFlow = SpiFlow_Transaction) Then
        Set txFlow = spi.CurrentTxFlowState
        frmActions.lblFlowMessage.Caption = txFlow.DisplayMessage
        frmActions.listFlow.AddItem "### TX PROCESS UPDATE ###"
        frmActions.listFlow.AddItem "# " + txFlow.DisplayMessage
        frmActions.listFlow.AddItem "# Id: " + txFlow.PosRefId
        frmActions.listFlow.AddItem "# Type: " + comWrapper.GetTransactionTypeEnumName(txFlow.Type)
        frmActions.listFlow.AddItem "# Amount: " + CStr(txFlow.amountCents / 100)
        frmActions.listFlow.AddItem "# Waiting For Signature: " + CStr(txFlow.AwaitingSignatureCheck)
        frmActions.listFlow.AddItem "# Attempting to Cancel : " + CStr(txFlow.AttemptingToCancel)
        frmActions.listFlow.AddItem "# Finished: " + CStr(txFlow.Finished)
        frmActions.listFlow.AddItem "# Success: " + comWrapper.GetSuccessStateEnumName(txFlow.Success)
    
        If txFlow.AwaitingSignatureCheck Then
            'We need to print the receipt for the customer to sign.
            frmActions.listFlow.AddItem "# RECEIPT TO PRINT FOR SIGNATURE"
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + Trim(txFlow.SignatureRequiredMessage.GetMerchantReceipt)
        End If
    
        'If the transaction is finished, we take some extra steps.
        If txFlow.Finished Then
            Select Case txFlow.Success
            Case SuccessState_Success
                Select Case txFlow.Type
                Case TransactionType_Preauth
                    frmActions.listFlow.AddItem "# PREAUTH RESULT - SUCCESS"
                    Set preauthResponse = comWrapper.PreauthResponseInit(txFlow.Response)
                    frmActions.listFlow.AddItem "# PREAUTH-ID: " + preauthResponse.PreauthId
                    frmActions.listFlow.AddItem "# NEW BALANCE AMOUNT: " + CStr(preauthResponse.GetBalanceAmount)
                    frmActions.listFlow.AddItem "# PREV BALANCE AMOUNT: " + CStr(preauthResponse.GetPreviousBalanceAmount)
                    frmActions.listFlow.AddItem "# COMPLETION AMOUNT: " + CStr(preauthResponse.GetCompletionAmount)
                
                    Set details = preauthResponse.details
                    frmActions.listFlow.AddItem "# Response: " + details.GetResponseText
                    frmActions.listFlow.AddItem "# RRN: " + details.GetRRN
                    frmActions.listFlow.AddItem "# Scheme: " + details.SchemeName
                    frmActions.listFlow.AddItem "# Customer Receipt:"
                    frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(details.GetCustomerReceipt)
                Case TransactionType_AccountVerify
                    frmActions.listFlow.AddItem "# ACCOUNT VERIFICATION SUCCESS"
                    Set acctVerifyResponse = comWrapper.AccountVerifyResponseInit(txFlow.Response)
                    Set details = acctVerifyResponse.details
                    
                    frmActions.listFlow.AddItem "# Response: " + details.GetResponseText
                    frmActions.listFlow.AddItem "# RRN: " + details.GetRRN
                    frmActions.listFlow.AddItem "# Scheme: " + details.SchemeName
                    frmActions.listFlow.AddItem "# Merchant Receipt:"
                    frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(details.GetCustomerReceipt)
                Case Else
                    frmActions.listFlow.AddItem "# MOTEL POS DOESN'T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT SUCCEEDS"
                End Select
            Case SuccessState_Failed
                Select Case txFlow.Type
                Case TransactionType_Preauth
                    frmActions.listFlow.AddItem "# PREAUTH TRANSACTION FAILED :("
                    frmActions.listFlow.AddItem "# Error: " + txFlow.Response.GetError
                    frmActions.listFlow.AddItem "# Error Detail: " + txFlow.Response.GetErrorDetail
                    
                    If (txFlow.Response <> "") Then
                        Set details = comWrapper.PurchaseResponseInit(txFlow.Response)
                        frmActions.listFlow.AddItem "# Response: " + details.GetResponseText
                        frmActions.listFlow.AddItem "# RRN: " + details.GetRRN
                        frmActions.listFlow.AddItem "# Scheme: " + details.SchemeName
                        frmActions.listFlow.AddItem "# Customer Receipt:"
                        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(details.GetCustomerReceipt)
                    End If
                Case TransactionType_AccountVerify
                    frmActions.listFlow.AddItem "# ACCOUNT TRANSACTION FAILED :("
                    frmActions.listFlow.AddItem "# Error: " + txFlow.Response.GetError
                    frmActions.listFlow.AddItem "# Error Detail: " + txFlow.Response.GetErrorDetail
                    
                    If (txFlow.Response <> "") Then
                        Set acctVerifyResponse = comWrapper.AccountVerifyResponseInit(txFlow.Response)
                        Set details = acctVerifyResponse.details
                        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(details.GetCustomerReceipt)
                    End If
                Case Else
                    frmActions.listFlow.AddItem "# MOTEL POS DOESN'T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT SUCCEEDS"
                End Select
            Case SuccessState_Unknown
                Select Case txFlow.Type
                Case TransactionType_Preauth
                    frmActions.listFlow.AddItem "# WE'RE NOT QUITE SURE WHETHER PREAUTH TRANSACTION WENT THROUGH OR NOT:/"
                    frmActions.listFlow.AddItem "# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM."
                    frmActions.listFlow.AddItem "# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER."
                    frmActions.listFlow.AddItem "# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH."
                Case TransactionType_AccountVerify
                    frmActions.listFlow.AddItem "# WE'RE NOT QUITE SURE WHETHER ACCOUNT VERIFICATION WENT THROUGH OR NOT:/"
                    frmActions.listFlow.AddItem "# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM."
                    frmActions.listFlow.AddItem "# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER."
                    frmActions.listFlow.AddItem "# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH."
                Case Else
                    frmActions.listFlow.AddItem "# MOTEL POS DOESN'T KNOW WHAT TO DO WITH THIS TX TYPE WHEN IT'S UNKNOWN"
                End Select
            End Select
        End If
        
    End If
    
    frmActions.listFlow.AddItem "# --------------- STATUS ------------------"
    frmActions.listFlow.AddItem "# " + posId + " <-> Eftpos: " + eftposAddress + " #"
    frmActions.listFlow.AddItem "# SPI STATUS: " + comWrapper.GetSpiStatusEnumName(spi.CurrentStatus) _
        + "     FLOW:" + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow) + " #"
    frmActions.listFlow.AddItem "# CASH ONLY! #"
    frmActions.listFlow.AddItem "# -----------------------------------------"
    frmActions.listFlow.AddItem "# POS: v" + comWrapper.GetPosVersion + " Spi: v" + comWrapper.GetSpiVersion
End Sub

Public Sub PrintStatusAndActions()
    frmMain.lblStatus.Caption = comWrapper.GetSpiStatusEnumName(spi.CurrentStatus) + ":" + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
    frmActions.lblFlowStatus.Caption = comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
    
    Select Case spi.CurrentStatus
    Case SpiStatus_Unpaired
        Select Case spi.CurrentFlow
        Case SpiFlow_Idle
            frmActions.lblFlowMessage.Caption = "Unpaired"
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK-Unpaired"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblPreauthId.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtPreauthId.Visible = False
            frmMain.btnPair.Caption = "Pair"
            frmMain.framePreauthActions.Visible = False
            frmMain.frameOtherActions.Visible = False
            frmMain.lblStatus.BackColor = RGB(255, 0, 0)
        Case SpiFlow_Pairing
            If spi.CurrentPairingFlowState.AwaitingCheckFromPos Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Confirm Code"
                frmActions.btnAction2.Visible = True
                frmActions.btnAction2.Caption = "Cancel Pairing"
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblPreauthId.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtPreauthId.Visible = False
            ElseIf Not spi.CurrentPairingFlowState.Finished Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Cancel Pairing"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblPreauthId.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtPreauthId.Visible = False
            Else
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "OK"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblPreauthId.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtPreauthId.Visible = False
            End If
        Case SpiFlow_Transaction
        Case Else
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblPreauthId.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtPreauthId.Visible = False
            frmActions.listFlow.Clear
            frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
        End Select
    Case SpiStatus_PairedConnecting
        Select Case spi.CurrentFlow
        Case SpiFlow_Idle
            frmMain.btnPair.Caption = "UnPair"
            frmMain.framePreauthActions.Visible = True
            frmMain.frameOtherActions.Visible = True
            frmMain.lblStatus.BackColor = RGB(0, 255, 0)
            frmActions.lblFlowMessage.Caption = "# --> SPI Status Changed: " + comWrapper.GetSpiStatusEnumName(spi.CurrentStatus)
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblPreauthId.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtPreauthId.Visible = False
        Case SpiFlow_Transaction
            If spi.CurrentTxFlowState.AwaitingSignatureCheck Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Accept Signature"
                frmActions.btnAction2.Visible = True
                frmActions.btnAction2.Caption = "Decline Signature"
                frmActions.btnAction3.Visible = True
                frmActions.btnAction3.Caption = "Cancel"
                frmActions.lblAmount.Visible = False
                frmActions.lblPreauthId.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtPreauthId.Visible = False
            ElseIf Not spi.CurrentTxFlowState.Finished Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Cancel"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblPreauthId.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtPreauthId.Visible = False
            Else
                Select Case spi.CurrentTxFlowState.Success
                Case SuccessState_Success
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "OK"
                    frmActions.btnAction2.Visible = False
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblPreauthId.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtPreauthId.Visible = False
                Case SuccessState_Failed
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "Retry"
                    frmActions.btnAction2.Visible = True
                    frmActions.btnAction2.Caption = "Cancel"
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblPreauthId.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtPreauthId.Visible = False
                Case Else
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "OK"
                    frmActions.btnAction2.Visible = False
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblPreauthId.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtPreauthId.Visible = False
                End Select
            End If
        Case SpiFlow_Pairing
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblPreauthId.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtPreauthId.Visible = False
        Case Else
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblPreauthId.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtPreauthId.Visible = False
            frmActions.listFlow.Clear
            frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
        End Select
    Case SpiStatus_PairedConnected
        Select Case spi.CurrentFlow
        Case SpiFlow_Idle
            frmMain.btnPair.Caption = "UnPair"
            frmMain.framePreauthActions.Visible = True
            frmMain.frameOtherActions.Visible = True
            frmMain.lblStatus.BackColor = RGB(0, 255, 0)
            frmActions.lblFlowMessage.Caption = "# --> SPI Status Changed: " + comWrapper.GetSpiStatusEnumName(spi.CurrentStatus)
            
            If (frmActions.btnAction1.Caption = "Retry") Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "OK"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblPreauthId.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtPreauthId.Visible = False
            End If
        Case SpiFlow_Transaction
            If spi.CurrentTxFlowState.AwaitingSignatureCheck Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Accept Signature"
                frmActions.btnAction2.Visible = True
                frmActions.btnAction2.Caption = "Decline Signature"
                frmActions.btnAction3.Visible = True
                frmActions.btnAction3.Caption = "Cancel"
                frmActions.lblAmount.Visible = False
                frmActions.lblPreauthId.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtPreauthId.Visible = False
            ElseIf Not spi.CurrentTxFlowState.Finished Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Cancel"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblPreauthId.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtPreauthId.Visible = False
            Else
                Select Case spi.CurrentTxFlowState.Success
                Case SuccessState_Success
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "OK"
                    frmActions.btnAction2.Visible = False
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblPreauthId.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtPreauthId.Visible = False
                Case SuccessState_Failed
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "Retry"
                    frmActions.btnAction2.Visible = True
                    frmActions.btnAction2.Caption = "Cancel"
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblPreauthId.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtPreauthId.Visible = False
                Case Else
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "OK"
                    frmActions.btnAction2.Visible = False
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblPreauthId.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtPreauthId.Visible = False
                End Select
            End If
        Case SpiFlow_Pairing
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblPreauthId.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtPreauthId.Visible = False
        Case Else
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblPreauthId.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtPreauthId.Visible = False
            frmActions.listFlow.Clear
            frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
        End Select
    Case Else
        frmActions.btnAction1.Visible = True
        frmActions.btnAction1.Caption = "OK"
        frmActions.btnAction2.Visible = False
        frmActions.btnAction3.Visible = False
        frmActions.lblAmount.Visible = False
        frmActions.lblPreauthId.Visible = False
        frmActions.txtAmount.Visible = False
        frmActions.txtPreauthId.Visible = False
        frmActions.listFlow.Clear
        frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
    End Select
End Sub

Public Function IsOpenForm(ByVal formName As String) As Boolean
    Dim tmpForm As Form
    Dim isOpen As Boolean
    isOpen = False
    
    For Each tmpForm In Forms
        If tmpForm.Name = formName Then
            isOpen = True
        End If
    Next
    
    IsOpenForm = isOpen
End Function
