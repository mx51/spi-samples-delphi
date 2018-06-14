Attribute VB_Name = "VB6Pos"
Option Explicit

Public spi As SPIClient.spi
Public comWrapper As SPIClient.comWrapper
Public posId, eftposAddress, EncKey, HmacKey As String
Public spiSecrets As SPIClient.Secrets
Public secretsInited As Boolean

Sub Start()
    posId = ""
    eftposAddress = ""
    Set spiSecrets = New SPIClient.Secrets
    Set spi = New SPIClient.spi
    Set comWrapper = New SPIClient.comWrapper
    Set spiSecrets = Nothing
    
    LoadPersistedState
    
    Set spi = comWrapper.SpiInit(posId, eftposAddress, spiSecrets)
    comWrapper.Main spi, AddressOf TxFlowStateChanged, AddressOf PairingFlowStateChanged, AddressOf SecretsChanged, AddressOf SpiStatusChanged
    spi.Start
    
    PrintStatusAndActions
End Sub

Private Sub TxFlowStateChanged(ByVal e As SPIClient.TransactionFlowState)
    frmActions.Show
    
    PrintFlowInfo e
    
    PrintStatusAndActions
End Sub

Private Sub PairingFlowStateChanged(ByVal e As SPIClient.PairingFlowState)
    frmActions.Show
    
    frmActions.listFlow.Clear
    frmActions.lblFlowMessage.Caption = e.Message
    
    If e.ConfirmationCode <> "" Then
        frmActions.listFlow.AddItem "# Confirmation Code: " + e.ConfirmationCode
    End If
    
    PrintStatusAndActions
End Sub

Private Sub SecretsChanged(ByVal e As SPIClient.Secrets)
    Set spiSecrets = e
End Sub

Private Sub SpiStatusChanged(ByVal e As SPIClient.SpiStatusEventArgs)
    If secretsInited = False Then
        frmActions.Show
    
        If spi.CurrentFlow = SpiFlow_Idle Then
            frmActions.listFlow.Clear
        End If
    End If
    
    PrintStatusAndActions
End Sub

Private Sub LoadPersistedState()
    secretsInited = False
    posId = "VBPOS"
    eftposAddress = "192.168.0.5"
    
    frmMain.txtPosId.Text = posId
    frmMain.txtEftposAddress.Text = eftposAddress
    If EncKey <> "" And HmacKey <> "" Then
        Set spiSecrets = comWrapper.SecretsInit(EncKey, HmacKey)
        secretsInited = True
    End If
End Sub

Private Sub PrintFlowInfo(ByVal txFlow As SPIClient.TransactionFlowState)
    If frmMain.richtxtReceipt.Text <> "" Then
        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + " "
    End If
    
    frmActions.listFlow.Clear
    
    Select Case spi.CurrentFlow
    Case SpiFlow_Pairing
        frmActions.listFlow.AddItem "### PAIRING PROCESS UPDATE ###"
        frmActions.listFlow.AddItem "# " + spi.CurrentPairingFlowState.Message
        frmActions.listFlow.AddItem "# Finished? " + CStr(spi.CurrentPairingFlowState.Finished)
        frmActions.listFlow.AddItem "# Successful? " + CStr(spi.CurrentPairingFlowState.Successful)
        frmActions.listFlow.AddItem "# Confirmation Code: " + spi.CurrentPairingFlowState.ConfirmationCode
        frmActions.listFlow.AddItem "# Waiting Confirm from Eftpos?: " + CStr(spi.CurrentPairingFlowState.AwaitingCheckFromEftpos)
        frmActions.listFlow.AddItem "# Waiting Confirm from POS? " + CStr(spi.CurrentPairingFlowState.AwaitingCheckFromPos)
    Case SpiFlow_Transaction
        frmActions.listFlow.AddItem "# Id: " + txFlow.PosRefId
        frmActions.listFlow.AddItem "# Type: " + comWrapper.GetTransactionTypeEnumName(txFlow.Type)
        frmActions.listFlow.AddItem "# Amount: " + CStr(txFlow.amountCents / 100)
        frmActions.listFlow.AddItem "# WaitingForSignature: " + CStr(txFlow.AwaitingSignatureCheck)
        frmActions.listFlow.AddItem "# Attempting to Cancel : " + CStr(txFlow.AttemptingToCancel)
        frmActions.listFlow.AddItem "# Finished: " + CStr(txFlow.Finished)
        frmActions.listFlow.AddItem "# Success: " + comWrapper.GetSuccessStateEnumName(txFlow.success)
    
        If txFlow.AwaitingSignatureCheck Then
            'We need to print the receipt for the customer to sign.
            frmActions.listFlow.AddItem "# RECEIPT TO PRINT FOR SIGNATURE"
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + Trim(txFlow.SignatureRequiredMessage.GetMerchantReceipt)
        End If
    
        If txFlow.AwaitingPhoneForAuth Then
            'We need to print the receipt for the customer to sign.
            frmActions.listFlow.AddItem "# RECEIPT TO PRINT FOR SIGNATURE"
            frmActions.listFlow.AddItem "# CALL: " + txFlow.PhoneForAuthRequiredMessage.GetPhoneNumber
            frmActions.listFlow.AddItem "# QUOTE: Merchant Id: " + txFlow.PhoneForAuthRequiredMessage.GetMerchantId
        End If
    
        'If the transaction is finished, we take some extra steps.
        If txFlow.Finished Then
            Select Case txFlow.Type
            Case TransactionType_Purchase
                HandleFinishedPurchase txFlow
            Case TransactionType_Refund
                HandleFinishedRefund txFlow
            Case TransactionType_CashoutOnly
                HandleFinishedCashout txFlow
            Case TransactionType_MOTO
                HandleFinishedMoto txFlow
            Case TransactionType_Settle
                HandleFinishedSettle txFlow
            Case TransactionType_SettlementEnquiry
                HandleFinishedSettlementEnquiry txFlow
            Case TransactionType_GetLastTransaction
                HandleFinishedGetLastTransaction txFlow
            Case Else
                frmActions.listFlow.AddItem "# CAN''T HANDLE TX TYPE: " + comWrapper.GetTransactionTypeEnumName(txFlow.Type)
            End Select
        End If
    Case SpiFlow_Idle
    End Select
    
    frmActions.listFlow.AddItem "# --------------- STATUS ------------------"
    frmActions.listFlow.AddItem "# " + posId + " <-> Eftpos: " + eftposAddress + " #"
    frmActions.listFlow.AddItem "# SPI STATUS: " + comWrapper.GetSpiStatusEnumName(spi.CurrentStatus) _
        + "     FLOW:" + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow) + " #"
    frmActions.listFlow.AddItem "# -----------------------------------------"
    frmActions.listFlow.AddItem "# POS: v" + comWrapper.GetPosVersion + " Spi: v" + comWrapper.GetSpiVersion
End Sub

Private Sub HandleFinishedPurchase(ByVal txFlowState As SPIClient.TransactionFlowState)
    Dim purchaseResponse As SPIClient.purchaseResponse
    Set purchaseResponse = New SPIClient.purchaseResponse
    
    Select Case txFlowState.success
    Case SuccessState_Success
        frmActions.listFlow.AddItem "# WOOHOO - WE GOT PAID!"
        Set purchaseResponse = comWrapper.PurchaseResponseInit(txFlowState.Response)
        frmActions.listFlow.AddItem "# Response: " + purchaseResponse.GetResponseText
        frmActions.listFlow.AddItem "# RRN: " + purchaseResponse.GetRRN
        frmActions.listFlow.AddItem "# Scheme: " + purchaseResponse.SchemeName
        frmActions.listFlow.AddItem "# Customer Receipt:"

        If (Not purchaseResponse.WasCustomerReceiptPrinted) Then
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(purchaseResponse.GetCustomerReceipt)
        Else
            frmActions.listFlow.AddItem "# PRINTED FROM EFTPOS"
        End If
        
        frmActions.listFlow.AddItem "# PURCHASE: " + CStr(purchaseResponse.GetPurchaseAmount)
        frmActions.listFlow.AddItem "# TIP: " + CStr(purchaseResponse.GetTipAmount)
        frmActions.listFlow.AddItem "# CASHOUT: " + CStr(purchaseResponse.GetCashoutAmount)
        frmActions.listFlow.AddItem "# BANKED NON-CASH AMOUNT: " + CStr(purchaseResponse.GetBankNonCashAmount)
        frmActions.listFlow.AddItem "# BANKED CASH AMOUNT: " + CStr(purchaseResponse.GetBankCashAmount)
    Case SuccessState_Failed
        frmActions.listFlow.AddItem "# WE DID NOT GET PAID :("
        frmActions.listFlow.AddItem "# Error: " + txFlowState.Response.GetError
        frmActions.listFlow.AddItem "# Error Detail: " + txFlowState.Response.GetErrorDetail

        If (txFlowState.Response <> "") Then
            Set purchaseResponse = comWrapper.PurchaseResponseInit(txFlowState.Response)
            frmActions.listFlow.AddItem "# Response: " + purchaseResponse.GetResponseText
            frmActions.listFlow.AddItem "# RRN: " + purchaseResponse.GetRRN
            frmActions.listFlow.AddItem "# Scheme: " + purchaseResponse.SchemeName
            frmActions.listFlow.AddItem "# Customer Receipt:"
            
            If (Not purchaseResponse.WasCustomerReceiptPrinted) Then
                frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(purchaseResponse.GetCustomerReceipt)
            Else
                frmActions.listFlow.AddItem "# PRINTED FROM EFTPOS"
            End If
        End If
    Case SuccessState_Unknown
        frmActions.listFlow.AddItem "# WE'RE NOT QUITE SURE WHETHER WE GOT PAID OR NOT :/"
        frmActions.listFlow.AddItem "# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM."
        frmActions.listFlow.AddItem "# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER."
        frmActions.listFlow.AddItem "# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH."
    Case Else
        Err.Raise -456, "Exception", "Argument Out Of Range Exception"
        Exit Sub
ErrorHandler:
        MsgBox Err.Description
        Resume Next
    End Select
End Sub

Private Sub HandleFinishedRefund(ByVal txFlowState As SPIClient.TransactionFlowState)
    Dim refundResponse As SPIClient.refundResponse
    Set refundResponse = New SPIClient.refundResponse
    
    Select Case txFlowState.success
    Case SuccessState_Success
        frmActions.listFlow.AddItem "# REFUND GIVEN- OH WELL!"
        Set refundResponse = comWrapper.RefundResponseInit(txFlowState.Response)
        frmActions.listFlow.AddItem "# Response: " + refundResponse.GetResponseText
        frmActions.listFlow.AddItem "# RRN: " + refundResponse.GetRRN
        frmActions.listFlow.AddItem "# Scheme: " + refundResponse.SchemeName
        frmActions.listFlow.AddItem "# Customer Receipt:"

        If (Not refundResponse.WasCustomerReceiptPrinted) Then
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(refundResponse.GetCustomerReceipt)
        Else
            frmActions.listFlow.AddItem "# PRINTED FROM EFTPOS"
        End If
        
        frmActions.listFlow.AddItem "# REFUNDED AMOUNT: " + CStr(refundResponse.GetRefundAmount)
    Case SuccessState_Failed
        frmActions.listFlow.AddItem "# REFUND FAILED!"
        frmActions.listFlow.AddItem "# Error: " + txFlowState.Response.GetError
        frmActions.listFlow.AddItem "# Error Detail: " + txFlowState.Response.GetErrorDetail

        If (txFlowState.Response <> "") Then
            Set refundResponse = comWrapper.RefundResponseInit(txFlowState.Response)
            frmActions.listFlow.AddItem "# Response: " + refundResponse.GetResponseText
            frmActions.listFlow.AddItem "# RRN: " + refundResponse.GetRRN
            frmActions.listFlow.AddItem "# Scheme: " + refundResponse.SchemeName
            frmActions.listFlow.AddItem "# Customer Receipt:"
            
            If (Not refundResponse.WasCustomerReceiptPrinted) Then
                frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(refundResponse.GetCustomerReceipt)
            Else
                frmActions.listFlow.AddItem "# PRINTED FROM EFTPOS"
            End If
        End If
    Case SuccessState_Unknown
        frmActions.listFlow.AddItem "# WE'RE NOT QUITE SURE WHETHER THE REFUND WENT THROUGH OR NOT :/"
        frmActions.listFlow.AddItem "# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM."
        frmActions.listFlow.AddItem "# YOU CAN THE TAKE THE APPROPRIATE ACTION."
    Case Else
        Err.Raise -456, "Exception", "Argument Out Of Range Exception"
        Exit Sub
ErrorHandler:
        MsgBox Err.Description
        Resume Next
    End Select
End Sub

Private Sub HandleFinishedCashout(ByVal txFlowState As SPIClient.TransactionFlowState)
    Dim cashoutResponse As SPIClient.CashoutOnlyResponse
    Set cashoutResponse = New SPIClient.CashoutOnlyResponse
    
    Select Case txFlowState.success
    Case SuccessState_Success
        frmActions.listFlow.AddItem "# CASH-OUT SUCCESSFUL - HAND THEM THE CASH!"
        Set cashoutResponse = comWrapper.CashoutOnlyResponseInit(txFlowState.Response)
        frmActions.listFlow.AddItem "# Response: " + cashoutResponse.GetResponseText
        frmActions.listFlow.AddItem "# RRN: " + cashoutResponse.GetRRN
        frmActions.listFlow.AddItem "# Scheme: " + cashoutResponse.SchemeName
        frmActions.listFlow.AddItem "# Customer Receipt:"

        If (Not cashoutResponse.WasCustomerReceiptPrinted) Then
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(cashoutResponse.GetCustomerReceipt)
        Else
            frmActions.listFlow.AddItem "# PRINTED FROM EFTPOS"
        End If
        
        frmActions.listFlow.AddItem "# CASHOUT: " + CStr(cashoutResponse.GetCashoutAmount)
        frmActions.listFlow.AddItem "# BANKED NON-CASH AMOUNT: " + CStr(cashoutResponse.GetBankNonCashAmount)
        frmActions.listFlow.AddItem "# BANKED CASH AMOUNT: " + CStr(cashoutResponse.GetBankCashAmount)
    Case SuccessState_Failed
        frmActions.listFlow.AddItem "# CASHOUT FAILED!"
        frmActions.listFlow.AddItem "# Error: " + txFlowState.Response.GetError
        frmActions.listFlow.AddItem "# Error Detail: " + txFlowState.Response.GetErrorDetail

        If (txFlowState.Response <> "") Then
            Set cashoutResponse = comWrapper.CashoutOnlyResponseInit(txFlowState.Response)
            frmActions.listFlow.AddItem "# Response: " + cashoutResponse.GetResponseText
            frmActions.listFlow.AddItem "# RRN: " + cashoutResponse.GetRRN
            frmActions.listFlow.AddItem "# Scheme: " + cashoutResponse.SchemeName
            frmActions.listFlow.AddItem "# Customer Receipt:"
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(cashoutResponse.GetCustomerReceipt)
        End If
    Case SuccessState_Unknown
        frmActions.listFlow.AddItem "# WE'RE NOT QUITE SURE WHETHER THE CASHOUT WENT THROUGH OR NOT :/"
        frmActions.listFlow.AddItem "# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM."
        frmActions.listFlow.AddItem "# YOU CAN THE TAKE THE APPROPRIATE ACTION."
    Case Else
        Err.Raise -456, "Exception", "Argument Out Of Range Exception"
        Exit Sub
ErrorHandler:
        MsgBox Err.Description
        Resume Next
    End Select
End Sub

Private Sub HandleFinishedMoto(ByVal txFlowState As SPIClient.TransactionFlowState)
    Dim motoResponse As SPIClient.MotoPurchaseResponse
    Dim purchaseResponse As SPIClient.purchaseResponse
    Set motoResponse = New SPIClient.MotoPurchaseResponse
    Set purchaseResponse = New SPIClient.purchaseResponse
    
    Select Case txFlowState.success
    Case SuccessState_Success
        frmActions.listFlow.AddItem "# WOOHOO - WE GOT MOTO-PAID!"
        Set motoResponse = comWrapper.MotoPurchaseResponseInit(txFlowState.Response)
        Set purchaseResponse = motoResponse.purchaseResponse
        frmActions.listFlow.AddItem "# Response: " + purchaseResponse.GetResponseText
        frmActions.listFlow.AddItem "# RRN: " + purchaseResponse.GetRRN
        frmActions.listFlow.AddItem "# Scheme: " + purchaseResponse.SchemeName
        frmActions.listFlow.AddItem "# Card Entry: " + purchaseResponse.GetCardEntry
        frmActions.listFlow.AddItem "# Customer Receipt:"

        If (Not purchaseResponse.WasCustomerReceiptPrinted) Then
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(purchaseResponse.GetCustomerReceipt)
        Else
            frmActions.listFlow.AddItem "# PRINTED FROM EFTPOS"
        End If
        
        frmActions.listFlow.AddItem "# PURCHASE: " + CStr(purchaseResponse.GetPurchaseAmount)
        frmActions.listFlow.AddItem "# BANKED NON-CASH AMOUNT: " + CStr(purchaseResponse.GetBankNonCashAmount)
        frmActions.listFlow.AddItem "# BANKED CASH AMOUNT: " + CStr(purchaseResponse.GetBankCashAmount)
    Case SuccessState_Failed
        frmActions.listFlow.AddItem "# WE DID NOT GET MOTO-PAID :("
        frmActions.listFlow.AddItem "# Error: " + txFlowState.Response.GetError
        frmActions.listFlow.AddItem "# Error Detail: " + txFlowState.Response.GetErrorDetail

        If (txFlowState.Response <> "") Then
            Set motoResponse = comWrapper.MotoPurchaseResponseInit(txFlowState.Response)
            Set purchaseResponse = motoResponse.purchaseResponse
            frmActions.listFlow.AddItem "# Response: " + purchaseResponse.GetResponseText
            frmActions.listFlow.AddItem "# RRN: " + purchaseResponse.GetRRN
            frmActions.listFlow.AddItem "# Scheme: " + purchaseResponse.SchemeName
            frmActions.listFlow.AddItem "# Customer Receipt:"
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(purchaseResponse.GetCustomerReceipt)
        End If
    Case SuccessState_Unknown
        frmActions.listFlow.AddItem "# WE'RE NOT QUITE SURE WHETHER THE MOTO WENT THROUGH OR NOT :/"
        frmActions.listFlow.AddItem "# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM."
        frmActions.listFlow.AddItem "# YOU CAN THE TAKE THE APPROPRIATE ACTION."
    Case Else
        Err.Raise -456, "Exception", "Argument Out Of Range Exception"
        Exit Sub
ErrorHandler:
        MsgBox Err.Description
        Resume Next
    End Select
End Sub

Private Sub HandleFinishedSettle(ByVal txFlowState As SPIClient.TransactionFlowState)
    Dim settleResponse As SPIClient.Settlement
    Set settleResponse = New SPIClient.Settlement
    
    Select Case txFlowState.success
    Case SuccessState_Success
        frmActions.listFlow.AddItem "# SETTLEMENT SUCCESSFUL!"
        Set settleResponse = comWrapper.SettlementInit(txFlowState.Response)
        frmActions.listFlow.AddItem "# Response: " + settleResponse.GetResponseText
        frmActions.listFlow.AddItem "# Merchant Receipt:"
        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(settleResponse.GetReceipt)
        frmActions.listFlow.AddItem "# Period Start: " + CStr(settleResponse.GetPeriodStartTime)
        frmActions.listFlow.AddItem "# Period End: " + CStr(settleResponse.GetPeriodEndTime)
        frmActions.listFlow.AddItem "# Settlement Time: " + CStr(settleResponse.GetTriggeredTime)
        frmActions.listFlow.AddItem "# Transaction Range: " + settleResponse.GetTransactionRange
        frmActions.listFlow.AddItem "# Terminal Id:" + settleResponse.GetTerminalId
        frmActions.listFlow.AddItem "# Total TX Count: " + CStr(settleResponse.GetTotalCount)
        frmActions.listFlow.AddItem "# Total TX Value: " + CStr(settleResponse.GetTotalValue / 100)
        frmActions.listFlow.AddItem "# By Aquirer TX Count: " + CStr(settleResponse.GetSettleByAcquirerCount)
        frmActions.listFlow.AddItem "# By Aquirer TX Value: " + CStr(settleResponse.GetSettleByAcquirerValue / 100)
        frmActions.listFlow.AddItem "# SCHEME SETTLEMENTS:"
        
        Dim schemeList() As New SchemeSettlementEntry
        schemeList = comWrapper.GetSchemeSettlementEntries(txFlowState)
        
        Dim lngPosition As Long
        For lngPosition = LBound(schemeList) To UBound(schemeList)
            frmActions.listFlow.AddItem "# " + schemeList(lngPosition).ToString
        Next lngPosition
    Case SuccessState_Failed
        frmActions.listFlow.AddItem "# SETTLEMENT FAILED!"

        If (txFlowState.Response <> "") Then
            Set settleResponse = comWrapper.SettlementInit(txFlowState.Response)
            frmActions.listFlow.AddItem "# Response: " + settleResponse.GetResponseText
            frmActions.listFlow.AddItem "# Error: " + txFlowState.Response.GetError
            frmActions.listFlow.AddItem "# Merchant Receipt:"
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(settleResponse.GetReceipt)
        End If
    Case SuccessState_Unknown
        frmActions.listFlow.AddItem "'# SETTLEMENT ENQUIRY RESULT UNKNOWN!"
    Case Else
        Err.Raise -456, "Exception", "Argument Out Of Range Exception"
        Exit Sub
ErrorHandler:
        MsgBox Err.Description
        Resume Next
    End Select
End Sub

Private Sub HandleFinishedSettlementEnquiry(ByVal txFlowState As SPIClient.TransactionFlowState)
    Dim settleResponse As SPIClient.Settlement
    Set settleResponse = New SPIClient.Settlement
    
    Select Case txFlowState.success
    Case SuccessState_Success
        frmActions.listFlow.AddItem "# SETTLEMENT ENQUIRY SUCCESSFUL!"
        Set settleResponse = comWrapper.SettlementInit(txFlowState.Response)
        frmActions.listFlow.AddItem "# Response: " + settleResponse.GetResponseText
        frmActions.listFlow.AddItem "# Merchant Receipt:"
        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(settleResponse.GetReceipt)
        frmActions.listFlow.AddItem "# Period Start: " + CStr(settleResponse.GetPeriodStartTime)
        frmActions.listFlow.AddItem "# Period End: " + CStr(settleResponse.GetPeriodEndTime)
        frmActions.listFlow.AddItem "# Settlement Time: " + CStr(settleResponse.GetTriggeredTime)
        frmActions.listFlow.AddItem "# Transaction Range: " + settleResponse.GetTransactionRange
        frmActions.listFlow.AddItem "# Terminal Id:" + settleResponse.GetTerminalId
        frmActions.listFlow.AddItem "# Total TX Count: " + CStr(settleResponse.GetTotalCount)
        frmActions.listFlow.AddItem "# Total TX Value: " + CStr(settleResponse.GetTotalValue / 100)
        frmActions.listFlow.AddItem "# By Aquirer TX Count: " + CStr(settleResponse.GetSettleByAcquirerCount)
        frmActions.listFlow.AddItem "# By Aquirer TX Value: " + CStr(settleResponse.GetSettleByAcquirerValue / 100)
        frmActions.listFlow.AddItem "# SCHEME SETTLEMENTS:"
        
        Dim schemeList() As New SchemeSettlementEntry
        schemeList = comWrapper.GetSchemeSettlementEntries(txFlowState)
        
        Dim lngPosition As Long
        For lngPosition = LBound(schemeList) To UBound(schemeList)
            frmActions.listFlow.AddItem "# " + schemeList(lngPosition).ToString
        Next lngPosition
    Case SuccessState_Failed
        frmActions.listFlow.AddItem "# SETTLEMENT ENQUIRY FAILED!"

        If (txFlowState.Response <> "") Then
            Set settleResponse = comWrapper.SettlementInit(txFlowState.Response)
            frmActions.listFlow.AddItem "# Response: " + settleResponse.GetResponseText
            frmActions.listFlow.AddItem "# Error: " + txFlowState.Response.GetError
            frmActions.listFlow.AddItem "# Merchant Receipt:"
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(settleResponse.GetReceipt)
        End If
    Case SuccessState_Unknown
        frmActions.listFlow.AddItem "'# SETTLEMENT ENQUIRY RESULT UNKNOWN!"
    Case Else
        Err.Raise -456, "Exception", "Argument Out Of Range Exception"
        Exit Sub
ErrorHandler:
        MsgBox Err.Description
        Resume Next
    End Select
End Sub

Private Sub HandleFinishedGetLastTransaction(ByVal txFlowState As SPIClient.TransactionFlowState)
    Dim gltResponse As SPIClient.GetLastTransactionResponse
    Dim purchaseResponse As SPIClient.purchaseResponse
    Dim success As SPIClient.SuccessState
    Set gltResponse = New SPIClient.GetLastTransactionResponse
    Set purchaseResponse = New SPIClient.purchaseResponse

    If (txFlowState.Response <> "") Then
        If (frmMain.txtReference.Text <> "") Then
            Set gltResponse = comWrapper.GetLastTransactionResponseInit(txFlowState.Response)
            success = spi.GltMatch(gltResponse, frmMain.txtReference.Text)
            If (success = SuccessState_Unknown) Then
                frmActions.listFlow.AddItem "# Did not retrieve Expected Transaction. Here is what we got:"
            Else
                frmActions.listFlow.AddItem "# Tx Matched Expected Purchase Request."
            End If
        
            Set purchaseResponse = comWrapper.PurchaseResponseInit(txFlowState.Response)
            frmActions.listFlow.AddItem "# Scheme: " + purchaseResponse.SchemeName
            frmActions.listFlow.AddItem "# Response: " + purchaseResponse.GetResponseText
            frmActions.listFlow.AddItem "# RRN: " + purchaseResponse.GetRRN
            frmActions.listFlow.AddItem "# Error: " + txFlowState.Response.GetError
            frmActions.listFlow.AddItem "# Customer Receipt:"
            frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(purchaseResponse.GetCustomerReceipt)
        End If
    Else
        frmActions.listFlow.AddItem "# Could Not Retrieve Last Transaction."
    End If
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
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblTipAmount.Visible = False
            frmActions.lblCashoutAmount.Visible = False
            frmActions.lblPrompt.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtTipAmount.Visible = False
            frmActions.txtCashoutAmount.Visible = False
            frmActions.optionPromptYes.Visible = False
            frmActions.optionPromptNo.Visible = False
            frmMain.btnPair.Caption = "Pair"
            frmMain.frameTransActions.Visible = False
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
                frmActions.lblTipAmount.Visible = False
                frmActions.lblCashoutAmount.Visible = False
                frmActions.lblPrompt.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtTipAmount.Visible = False
                frmActions.txtCashoutAmount.Visible = False
                frmActions.optionPromptYes.Visible = False
                frmActions.optionPromptNo.Visible = False
            ElseIf Not spi.CurrentPairingFlowState.Finished Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Cancel Pairing"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblTipAmount.Visible = False
                frmActions.lblCashoutAmount.Visible = False
                frmActions.lblPrompt.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtTipAmount.Visible = False
                frmActions.txtCashoutAmount.Visible = False
                frmActions.optionPromptYes.Visible = False
                frmActions.optionPromptNo.Visible = False
            Else
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "OK"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblTipAmount.Visible = False
                frmActions.lblCashoutAmount.Visible = False
                frmActions.lblPrompt.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtTipAmount.Visible = False
                frmActions.txtCashoutAmount.Visible = False
                frmActions.optionPromptYes.Visible = False
                frmActions.optionPromptNo.Visible = False
            End If
        Case SpiFlow_Transaction
        Case Else
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblTipAmount.Visible = False
            frmActions.lblCashoutAmount.Visible = False
            frmActions.lblPrompt.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtTipAmount.Visible = False
            frmActions.txtCashoutAmount.Visible = False
            frmActions.optionPromptYes.Visible = False
            frmActions.optionPromptNo.Visible = False
            frmActions.listFlow.Clear
            frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
        End Select
    Case SpiStatus_PairedConnecting
    Case SpiStatus_PairedConnected
        Select Case spi.CurrentFlow
        Case SpiFlow_Idle
            frmMain.btnPair.Caption = "UnPair"
            frmMain.frameTransActions.Visible = True
            frmMain.frameOtherActions.Visible = True
            frmMain.lblStatus.BackColor = RGB(0, 255, 0)
        Case SpiFlow_Transaction
            If spi.CurrentTxFlowState.AwaitingSignatureCheck Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Accept Signature"
                frmActions.btnAction2.Visible = True
                frmActions.btnAction2.Caption = "Decline Signature"
                frmActions.btnAction3.Visible = True
                frmActions.btnAction3.Caption = "Cancel"
                frmActions.lblAmount.Visible = False
                frmActions.lblTipAmount.Visible = False
                frmActions.lblCashoutAmount.Visible = False
                frmActions.lblPrompt.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtTipAmount.Visible = False
                frmActions.txtCashoutAmount.Visible = False
                frmActions.optionPromptYes.Visible = False
                frmActions.optionPromptNo.Visible = False
            ElseIf Not spi.CurrentTxFlowState.Finished Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Cancel"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.lblTipAmount.Visible = False
                frmActions.lblCashoutAmount.Visible = False
                frmActions.lblPrompt.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.txtTipAmount.Visible = False
                frmActions.txtCashoutAmount.Visible = False
                frmActions.optionPromptYes.Visible = False
                frmActions.optionPromptNo.Visible = False
            Else
                Select Case spi.CurrentTxFlowState.success
                Case SuccessState_Success
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "OK"
                    frmActions.btnAction2.Visible = False
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblTipAmount.Visible = False
                    frmActions.lblCashoutAmount.Visible = False
                    frmActions.lblPrompt.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtTipAmount.Visible = False
                    frmActions.txtCashoutAmount.Visible = False
                    frmActions.optionPromptYes.Visible = False
                    frmActions.optionPromptNo.Visible = False
                Case SuccessState_Failed
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "Retry"
                    frmActions.btnAction2.Visible = True
                    frmActions.btnAction2.Caption = "Cancel"
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblTipAmount.Visible = False
                    frmActions.lblCashoutAmount.Visible = False
                    frmActions.lblPrompt.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtTipAmount.Visible = False
                    frmActions.txtCashoutAmount.Visible = False
                    frmActions.optionPromptYes.Visible = False
                    frmActions.optionPromptNo.Visible = False
                Case Else
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "OK"
                    frmActions.btnAction2.Visible = False
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.lblTipAmount.Visible = False
                    frmActions.lblCashoutAmount.Visible = False
                    frmActions.lblPrompt.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.txtTipAmount.Visible = False
                    frmActions.txtCashoutAmount.Visible = False
                    frmActions.optionPromptYes.Visible = False
                    frmActions.optionPromptNo.Visible = False
                End Select
            End If
            
        Case SpiFlow_Pairing
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblTipAmount.Visible = False
            frmActions.lblCashoutAmount.Visible = False
            frmActions.lblPrompt.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtTipAmount.Visible = False
            frmActions.txtCashoutAmount.Visible = False
            frmActions.optionPromptYes.Visible = False
            frmActions.optionPromptNo.Visible = False
        Case Else
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.lblTipAmount.Visible = False
            frmActions.lblCashoutAmount.Visible = False
            frmActions.lblPrompt.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.txtTipAmount.Visible = False
            frmActions.txtCashoutAmount.Visible = False
            frmActions.optionPromptYes.Visible = False
            frmActions.optionPromptNo.Visible = False
            frmActions.listFlow.Clear
            frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
        End Select
    Case Else
        frmActions.btnAction1.Visible = True
        frmActions.btnAction1.Caption = "OK"
        frmActions.btnAction2.Visible = False
        frmActions.btnAction3.Visible = False
        frmActions.lblAmount.Visible = False
        frmActions.lblTipAmount.Visible = False
        frmActions.lblCashoutAmount.Visible = False
        frmActions.lblPrompt.Visible = False
        frmActions.txtAmount.Visible = False
        frmActions.txtTipAmount.Visible = False
        frmActions.txtCashoutAmount.Visible = False
        frmActions.optionPromptYes.Visible = False
        frmActions.optionPromptNo.Visible = False
        frmActions.listFlow.Clear
        frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
    End Select
End Sub
