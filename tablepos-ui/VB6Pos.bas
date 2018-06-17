Attribute VB_Name = "VB6Pos"
Option Explicit

Public spi As SPIClient.spi
Public comWrapper As SPIClient.comWrapper
Public posId, eftposAddress, EncKey, HmacKey As String
Public spiSecrets As SPIClient.Secrets
Public secretsInited As Boolean
Public spiPayAtTable As SPIClient.spiPayAtTable
Public billsStoreDict As Dictionary
Public tableToBillMappingDict As Dictionary
Public assemblyBillDataStoreDict As Dictionary
Public Const tableposDirectory As String = "C:\Users\metin.DESKTOP-7K2R3O3\Documents\GitHub\spi-samples-vb\tablepos\"

Sub Start()
    posId = ""
    eftposAddress = ""
    Set spiSecrets = New SPIClient.Secrets
    Set spiPayAtTable = New SPIClient.spiPayAtTable
    Set spi = New SPIClient.spi
    Set comWrapper = New SPIClient.comWrapper
    Set spiSecrets = Nothing
    
    LoadPersistedState
    
    Set spi = comWrapper.SpiInit(posId, eftposAddress, spiSecrets)
    Set spiPayAtTable = spi.EnablePayAtTable
    spiPayAtTable.Config.LabelTableId = "Table Number"
    
    comWrapper.Main_2 spi, spiPayAtTable, AddressOf TxFlowStateChanged, AddressOf PairingFlowStateChanged, AddressOf SecretsChanged, _
        AddressOf SpiStatusChanged, AddressOf PayAtTableGetBillDetails, AddressOf PayAtTableBillPaymentReceived

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

Private Sub PayAtTableGetBillDetails(ByVal billSatusInfo As SPIClient.BillStatusInfo, ByRef billStatus As SPIClient.BillStatusResponse)
    Set billStatus = New SPIClient.BillStatusResponse
    If (billSatusInfo.billId = "") Then
        If (Not tableToBillMappingDict.Exists(billSatusInfo.TableId)) Then
            billStatus.Result = BillRetrievalResult_INVALID_TABLE_ID
            Exit Sub
        End If
        
        billSatusInfo.billId = tableToBillMappingDict.Item(billSatusInfo.TableId)
    End If
    
    If (Not billsStoreDict.Exists(billSatusInfo.billId)) Then
        billStatus.Result = BillRetrievalResult_INVALID_BILL_ID
        Exit Sub
    End If
    
    Dim myBill As bill
    Set myBill = billsStoreDict(billSatusInfo.billId)
    
    billStatus.Result = BillRetrievalResult_SUCCESS
    billStatus.billId = billSatusInfo.billId
    billStatus.TableId = billSatusInfo.TableId
    billStatus.TotalAmount = myBill.TotalAmount
    billStatus.OutstandingAmount = myBill.OutstandingAmount
    billStatus.BillData = assemblyBillDataStoreDict.Item(billSatusInfo.billId)
End Sub

Private Sub PayAtTableBillPaymentReceived(ByVal billPaymentInfo As SPIClient.billPaymentInfo, ByRef billStatus As SPIClient.BillStatusResponse)
    Set billStatus = New SPIClient.BillStatusResponse
    
    If (Not billsStoreDict.Exists(billPaymentInfo.BillPayment.billId)) Then
        billStatus.Result = BillRetrievalResult_INVALID_BILL_ID
        Exit Sub
    End If
    
    frmActions.Show
    frmActions.listFlow.AddItem "# Got a " + comWrapper.GetPaymentTypeEnumName(billPaymentInfo.BillPayment.PaymentType) + _
        " Payment against bill " + billPaymentInfo.BillPayment.billId + " for table " + billPaymentInfo.BillPayment.TableId
        
    Dim bill As New bill
    Set bill = billsStoreDict.Item(billPaymentInfo.BillPayment.billId)
    bill.OutstandingAmount = bill.OutstandingAmount - billPaymentInfo.BillPayment.PurchaseAmount
    bill.TippedAmount = bill.TippedAmount + billPaymentInfo.BillPayment.TipAmount
    
    frmActions.listFlow.AddItem "Updated Bill: " + bill.billId + " - Table:$" + bill.TableId + " Total:$" + _
        CStr(bill.TotalAmount \ 100)
    frmActions.listFlow.AddItem " Outstanding:$" + CStr(bill.OutstandingAmount \ 100) + " Tips:$" + _
        CStr(bill.TippedAmount \ 100)
    
    assemblyBillDataStoreDict.Item(billPaymentInfo.BillPayment.billId) = billPaymentInfo.UpdatedBillData
    billStatus.Result = BillRetrievalResult_SUCCESS
    billStatus.OutstandingAmount = bill.OutstandingAmount
    billStatus.TotalAmount = bill.TotalAmount
    
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "OK"
    frmActions.btnAction2.Visible = False
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = False
    frmActions.txtAmount.Visible = False
    frmActions.lblTableId.Visible = False
    frmActions.txtTableId.Visible = False
End Sub

Private Sub LoadPersistedState()
    secretsInited = False
    posId = "VBPOS"
    
    Set billsStoreDict = New Dictionary
    Set tableToBillMappingDict = New Dictionary
    Set assemblyBillDataStoreDict = New Dictionary
   
    frmMain.txtPosId.Text = posId
    frmMain.txtEftposAddress.Text = eftposAddress
    
    If EncKey <> "" And HmacKey <> "" Then
        Set spiSecrets = comWrapper.SecretsInit(EncKey, HmacKey)
        secretsInited = True
        
        If (Dir(tableposDirectory + "billsStore.bin") <> "") Then
            Dim sFileText As String
            Dim iFileNo As Integer
            iFileNo = FreeFile
            Open tableposDirectory + "billsStore.bin" For Input As #iFileNo
            Do While Not EOF(iFileNo)
                Input #iFileNo, sFileText
                Dim billsStore() As String
                billsStore = Split(sFileText, " ", 2)
                Dim bill() As String
                bill = Split(billsStore(1), " ", 5)
                With billsStoreDict
                    .Add billsStore(0), bill
                End With
            Loop
            Close #iFileNo

            sFileText = ""
            iFileNo = 0
            iFileNo = FreeFile
            Open tableposDirectory + "tableToBillMapping.bin" For Input As #iFileNo
            Do While Not EOF(iFileNo)
                Input #iFileNo, sFileText
                Dim tableToBillMapping() As String
                tableToBillMapping = Split(sFileText, "", 2)
                With tableToBillMappingDict
                    .Add tableToBillMapping(0), tableToBillMapping(1)
                End With
            Loop
            Close #iFileNo

            sFileText = ""
            iFileNo = 0
            iFileNo = FreeFile
            Open tableposDirectory + "assemblyBillDataStore.bin" For Input As #iFileNo
            Do While Not EOF(iFileNo)
                Input #iFileNo, sFileText
                Dim assemblyBillDataStore() As String
                assemblyBillDataStore = Split(sFileText, "", 2)
                With assemblyBillDataStoreDict
                    .Add assemblyBillDataStore(0), assemblyBillDataStore(1)
                End With
            Loop
            Close #iFileNo
        End If
    End If
End Sub

Private Sub PrintFlowInfo(ByVal txFlow As SPIClient.TransactionFlowState)
    Dim purchaseResponse As SPIClient.purchaseResponse
    Dim refundResponse As SPIClient.refundResponse
    Dim settleResponse As SPIClient.Settlement
    
    Set purchaseResponse = New SPIClient.purchaseResponse
    Set refundResponse = New SPIClient.refundResponse
    Set settleResponse = New SPIClient.Settlement
    
    If frmMain.richtxtReceipt.Text <> "" Then
        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + " "
    End If
    
    frmActions.lblFlowMessage.Caption = txFlow.DisplayMessage
    frmActions.listFlow.Clear
    
    If (spi.CurrentFlow = SpiFlow_Pairing) Then
        frmActions.listFlow.AddItem "### PAIRING PROCESS UPDATE ###"
        frmActions.listFlow.AddItem "# " + spi.CurrentPairingFlowState.Message
        frmActions.listFlow.AddItem "# Finished? " + CStr(spi.CurrentPairingFlowState.Finished)
        frmActions.listFlow.AddItem "# Successful? " + CStr(spi.CurrentPairingFlowState.Successful)
        frmActions.listFlow.AddItem "# Confirmation Code: " + spi.CurrentPairingFlowState.ConfirmationCode
        frmActions.listFlow.AddItem "# Waiting Confirm from Eftpos?: " + CStr(spi.CurrentPairingFlowState.AwaitingCheckFromEftpos)
        frmActions.listFlow.AddItem "# Waiting Confirm from POS? " + CStr(spi.CurrentPairingFlowState.AwaitingCheckFromPos)
    End If
    
    If (spi.CurrentFlow = SpiFlow_Transaction) Then
        frmActions.listFlow.AddItem "### TX PROCESS UPDATE ###"
        frmActions.listFlow.AddItem "# " + txFlow.DisplayMessage
        frmActions.listFlow.AddItem "# Id: " + txFlow.PosRefId
        frmActions.listFlow.AddItem "# Type: " + comWrapper.GetTransactionTypeEnumName(txFlow.Type)
        frmActions.listFlow.AddItem "# Amount: " + CStr(txFlow.amountCents / 100)
        frmActions.listFlow.AddItem "# Waiting For Signature: " + CStr(txFlow.AwaitingSignatureCheck)
        frmActions.listFlow.AddItem "# Attempting to Cancel : " + CStr(txFlow.AttemptingToCancel)
        frmActions.listFlow.AddItem "# Finished: " + CStr(txFlow.Finished)
        frmActions.listFlow.AddItem "# Success: " + comWrapper.GetSuccessStateEnumName(txFlow.Success)
    
        If txFlow.Finished Then
            Select Case txFlow.Success
            Case SuccessState_Success
                Select Case txFlow.Type
                Case TransactionType_Purchase
                    frmActions.listFlow.AddItem "# WOOHOO - WE GOT PAID!"
                    Set purchaseResponse = comWrapper.PurchaseResponseInit(txFlow.Response)
                    frmActions.listFlow.AddItem "# Response: " + purchaseResponse.GetResponseText
                    frmActions.listFlow.AddItem "# RRN: " + purchaseResponse.GetRRN
                    frmActions.listFlow.AddItem "# Scheme: " + purchaseResponse.SchemeName
                    frmActions.listFlow.AddItem "# Customer Receipt:"
                    frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(purchaseResponse.GetCustomerReceipt)
                    
                    frmActions.listFlow.AddItem "# PURCHASE: " + CStr(purchaseResponse.GetPurchaseAmount)
                    frmActions.listFlow.AddItem "# TIP: " + CStr(purchaseResponse.GetTipAmount)
                    frmActions.listFlow.AddItem "# CASHOUT: " + CStr(purchaseResponse.GetCashoutAmount)
                    frmActions.listFlow.AddItem "# BANKED NON-CASH AMOUNT: " + CStr(purchaseResponse.GetBankNonCashAmount)
                    frmActions.listFlow.AddItem "# BANKED CASH AMOUNT: " + CStr(purchaseResponse.GetBankCashAmount)
                Case TransactionType_Refund
                    frmActions.listFlow.AddItem "# REFUND GIVEN- OH WELL!"
                    Set refundResponse = comWrapper.RefundResponseInit(txFlow.Response)
                    frmActions.listFlow.AddItem "# Response: " + refundResponse.GetResponseText
                    frmActions.listFlow.AddItem "# RRN: " + refundResponse.GetRRN
                    frmActions.listFlow.AddItem "# Scheme: " + refundResponse.SchemeName
                    frmActions.listFlow.AddItem "# Customer Receipt:"
                    frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(refundResponse.GetCustomerReceipt)
                Case TransactionType_Settle
                    frmActions.listFlow.AddItem "# SETTLEMENT SUCCESSFUL!"
                    If (txFlow.Response <> "") Then
                        Set settleResponse = comWrapper.SettlementInit(txFlow.Response)
                        frmActions.listFlow.AddItem "# Response: " + settleResponse.GetResponseText
                        frmActions.listFlow.AddItem "# Merchant Receipt:"
                        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(settleResponse.GetReceipt)
                    End If
                End Select
            Case SuccessState_Failed
                Select Case txFlow.Type
                Case TransactionType_Purchase
                    frmActions.listFlow.AddItem "# WE DID NOT GET PAID :("
                    If (txFlow.Response <> "") Then
                        Set purchaseResponse = comWrapper.PurchaseResponseInit(txFlow.Response)
                        frmActions.listFlow.AddItem "# Error: " + txFlow.Response.GetError
                        frmActions.listFlow.AddItem "# Response: " + purchaseResponse.GetResponseText
                        frmActions.listFlow.AddItem "# RRN: " + purchaseResponse.GetRRN
                        frmActions.listFlow.AddItem "# Scheme: " + purchaseResponse.SchemeName
                        frmActions.listFlow.AddItem "# Customer Receipt:"
                        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(purchaseResponse.GetCustomerReceipt)
                    End If
                Case TransactionType_Refund
                    frmActions.listFlow.AddItem "# REFUND FAILED!"
                    If (txFlow.Response <> "") Then
                        frmActions.listFlow.AddItem "# Error: " + txFlow.Response.GetError
                        Set refundResponse = comWrapper.RefundResponseInit(txFlow.Response)
                        frmActions.listFlow.AddItem "# Response: " + refundResponse.GetResponseText
                        frmActions.listFlow.AddItem "# RRN: " + refundResponse.GetRRN
                        frmActions.listFlow.AddItem "# Scheme: " + refundResponse.SchemeName
                        frmActions.listFlow.AddItem "# Customer Receipt:"
                        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(refundResponse.GetCustomerReceipt)
                    End If
                Case TransactionType_Settle
                    frmActions.listFlow.AddItem "# SETTLEMENT FAILED!"
                    If (txFlow.Response <> "") Then
                        Set settleResponse = comWrapper.SettlementInit(txFlow.Response)
                        frmActions.listFlow.AddItem "# Response: " + settleResponse.GetResponseText
                        frmActions.listFlow.AddItem "# Error: " + txFlow.Response.GetError
                        frmActions.listFlow.AddItem "# Merchant Receipt:"
                        frmMain.richtxtReceipt.Text = frmMain.richtxtReceipt.Text + vbCrLf + Trim(settleResponse.GetReceipt)
                    End If
                End Select
            Case SuccessState_Unknown
                Select Case txFlow.Type
                Case TransactionType_Purchase
                    frmActions.listFlow.AddItem "# WE'RE NOT QUITE SURE WHETHER WE GOT PAID OR NOT :/"
                    frmActions.listFlow.AddItem "# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM."
                    frmActions.listFlow.AddItem "# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER."
                    frmActions.listFlow.AddItem "# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH."
                Case TransactionType_Refund
                    frmActions.listFlow.AddItem "# WE'RE NOT QUITE SURE WHETHER THE REFUND WENT THROUGH OR NOT:/"
                    frmActions.listFlow.AddItem "# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM."
                    frmActions.listFlow.AddItem "# YOU CAN THE TAKE THE APPROPRIATE ACTION."
                End Select
            End Select
        End If
    End If
    
    frmActions.listFlow.AddItem "# --------------- STATUS ------------------"
    frmActions.listFlow.AddItem "# " + posId + " <-> Eftpos: " + eftposAddress + " #"
    frmActions.listFlow.AddItem "# SPI STATUS: " + comWrapper.GetSpiStatusEnumName(spi.CurrentStatus) _
        + "     FLOW:" + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow) + " #"
    frmActions.listFlow.AddItem "# ----------------TABLES-------------------"
    frmActions.listFlow.AddItem "#    Open Tables: " + CStr(tableToBillMappingDict.Count)
    frmActions.listFlow.AddItem "# Bills in Store: " + CStr(billsStoreDict.Count)
    frmActions.listFlow.AddItem "# Assembly Bills: " + CStr(assemblyBillDataStoreDict.Count)
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
        Case SpiFlow_Pairing
            If spi.CurrentPairingFlowState.AwaitingCheckFromPos Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Confirm Code"
                frmActions.btnAction2.Visible = True
                frmActions.btnAction2.Caption = "Cancel Pairing"
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.lblTableId.Visible = False
                frmActions.txtTableId.Visible = False
            ElseIf Not spi.CurrentPairingFlowState.Finished Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Cancel Pairing"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.lblTableId.Visible = False
                frmActions.txtTableId.Visible = False
            Else
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "OK"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.lblTableId.Visible = False
                frmActions.txtTableId.Visible = False
            End If
        Case SpiFlow_Transaction
        Case Else
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.lblTableId.Visible = False
            frmActions.txtTableId.Visible = False
            frmActions.listFlow.Clear
            frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
        End Select
    Case SpiStatus_PairedConnecting
    Case SpiStatus_PairedConnected
        Select Case spi.CurrentFlow
        Case SpiFlow_Idle
            frmMain.btnPair.Caption = "UnPair"
            frmMain.frameTableActions.Visible = True
            frmMain.frameOtherActions.Visible = True
            frmMain.lblStatus.BackColor = RGB(0, 256, 0)
            
            If (frmActions.btnAction1.Caption = "Retry") Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "OK"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.lblTableId.Visible = False
                frmActions.txtTableId.Visible = False
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
                frmActions.txtAmount.Visible = False
                frmActions.lblTableId.Visible = False
                frmActions.txtTableId.Visible = False
            ElseIf Not spi.CurrentTxFlowState.Finished Then
                frmActions.btnAction1.Visible = True
                frmActions.btnAction1.Caption = "Cancel"
                frmActions.btnAction2.Visible = False
                frmActions.btnAction3.Visible = False
                frmActions.lblAmount.Visible = False
                frmActions.txtAmount.Visible = False
                frmActions.lblTableId.Visible = False
                frmActions.txtTableId.Visible = False
            Else
                Select Case spi.CurrentTxFlowState.Success
                Case SuccessState_Success
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "OK"
                    frmActions.btnAction2.Visible = False
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.lblTableId.Visible = False
                    frmActions.txtTableId.Visible = False
                Case SuccessState_Failed
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "Retry"
                    frmActions.btnAction2.Visible = True
                    frmActions.btnAction2.Caption = "Cancel"
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.lblTableId.Visible = False
                    frmActions.txtTableId.Visible = False
                Case Else
                    frmActions.btnAction1.Visible = True
                    frmActions.btnAction1.Caption = "OK"
                    frmActions.btnAction2.Visible = False
                    frmActions.btnAction3.Visible = False
                    frmActions.lblAmount.Visible = False
                    frmActions.txtAmount.Visible = False
                    frmActions.lblTableId.Visible = False
                    frmActions.txtTableId.Visible = False
                End Select
            End If
            
        Case SpiFlow_Pairing
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.lblTableId.Visible = False
            frmActions.txtTableId.Visible = False
        Case Else
            frmActions.btnAction1.Visible = True
            frmActions.btnAction1.Caption = "OK"
            frmActions.btnAction2.Visible = False
            frmActions.btnAction3.Visible = False
            frmActions.lblAmount.Visible = False
            frmActions.txtAmount.Visible = False
            frmActions.lblTableId.Visible = False
            frmActions.txtTableId.Visible = False
            frmActions.listFlow.Clear
            frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
        End Select
    Case Else
        frmActions.btnAction1.Visible = True
        frmActions.btnAction1.Caption = "OK"
        frmActions.btnAction2.Visible = False
        frmActions.btnAction3.Visible = False
        frmActions.lblAmount.Visible = False
        frmActions.txtAmount.Visible = False
        frmActions.lblTableId.Visible = False
        frmActions.txtTableId.Visible = False
        frmActions.listFlow.Clear
        frmActions.listFlow.AddItem "# .. Unexpected Flow .. " + comWrapper.GetSpiFlowEnumName(spi.CurrentFlow)
    End Select
End Sub
