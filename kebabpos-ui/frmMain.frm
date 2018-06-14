VERSION 5.00
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "RICHTX32.OCX"
Begin VB.Form frmMain 
   Caption         =   "VB6 Pos"
   ClientHeight    =   8295
   ClientLeft      =   4560
   ClientTop       =   405
   ClientWidth     =   8955
   BeginProperty Font 
      Name            =   "Calibri"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   8295
   ScaleWidth      =   8955
   Begin VB.Frame frameOtherActions 
      Caption         =   "Other Actions"
      BeginProperty Font 
         Name            =   "Calibri"
         Size            =   15.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   1695
      Left            =   120
      TabIndex        =   17
      Top             =   6600
      Visible         =   0   'False
      Width           =   3975
      Begin VB.TextBox txtReference 
         Height          =   375
         Left            =   1800
         TabIndex        =   20
         Top             =   480
         Width           =   1935
      End
      Begin VB.CommandButton btnLastTx 
         Caption         =   "Last Tx"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   2160
         TabIndex        =   19
         Top             =   1080
         Width           =   1335
      End
      Begin VB.CommandButton btnRecover 
         Caption         =   "Recover"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   480
         TabIndex        =   18
         Top             =   1080
         Width           =   1335
      End
      Begin VB.Label lblReference 
         Caption         =   "Reference:"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   255
         Left            =   120
         TabIndex        =   21
         Top             =   480
         Width           =   1095
      End
   End
   Begin VB.Frame frameTransActions 
      Caption         =   "Transactional Actions"
      BeginProperty Font 
         Name            =   "Calibri"
         Size            =   15.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2295
      Left            =   120
      TabIndex        =   6
      Top             =   4200
      Visible         =   0   'False
      Width           =   3975
      Begin VB.CommandButton btnSettleEnq 
         Caption         =   "Settle Enq"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   2160
         TabIndex        =   16
         Top             =   1680
         Width           =   1335
      End
      Begin VB.CommandButton btnMoto 
         Caption         =   "MOTO"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   2160
         TabIndex        =   15
         Top             =   480
         Width           =   1335
      End
      Begin VB.CommandButton btnSettle 
         Caption         =   "Settle"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   480
         TabIndex        =   14
         Top             =   1680
         Width           =   1335
      End
      Begin VB.CommandButton btnRefund 
         Caption         =   "Refund"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   480
         TabIndex        =   13
         Top             =   1080
         Width           =   1335
      End
      Begin VB.CommandButton btnPurchase 
         Caption         =   "Purchase"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   480
         TabIndex        =   12
         Top             =   480
         Width           =   1335
      End
      Begin VB.CommandButton btnCashout 
         Caption         =   "Cash Out"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   2160
         TabIndex        =   11
         Top             =   1080
         Width           =   1335
      End
   End
   Begin VB.Frame frameReceipt 
      Caption         =   "Receipt"
      BeginProperty Font 
         Name            =   "Calibri"
         Size            =   18
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   8295
      Left            =   4200
      TabIndex        =   5
      Top             =   0
      Width           =   4695
      Begin RichTextLib.RichTextBox richtxtReceipt 
         Height          =   7695
         Left            =   120
         TabIndex        =   8
         Top             =   480
         Width           =   4455
         _ExtentX        =   7858
         _ExtentY        =   13573
         _Version        =   393217
         Enabled         =   -1  'True
         ScrollBars      =   2
         TextRTF         =   $"frmMain.frx":0000
      End
   End
   Begin VB.Frame frameStatus 
      Caption         =   "Status"
      BeginProperty Font 
         Name            =   "Calibri"
         Size            =   18
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   1695
      Left            =   120
      TabIndex        =   4
      Top             =   2520
      Width           =   3975
      Begin VB.CommandButton btnPair 
         Caption         =   "Pair"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   1080
         TabIndex        =   10
         Top             =   960
         Width           =   1815
      End
      Begin VB.Label lblStatus 
         Alignment       =   2  'Center
         Caption         =   "Idle"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   375
         Left            =   120
         TabIndex        =   9
         Top             =   480
         Width           =   3735
      End
   End
   Begin VB.Frame frameSettings 
      Caption         =   "Settings"
      BeginProperty Font 
         Name            =   "Calibri"
         Size            =   18
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2415
      Left            =   120
      TabIndex        =   0
      Top             =   0
      Width           =   3975
      Begin VB.Frame frmSign 
         Height          =   495
         Left            =   2280
         TabIndex        =   27
         Top             =   1800
         Width           =   1575
         Begin VB.OptionButton optionSignYes 
            Caption         =   "Yes"
            BeginProperty Font 
               Name            =   "Calibri"
               Size            =   12
               Charset         =   0
               Weight          =   400
               Underline       =   0   'False
               Italic          =   0   'False
               Strikethrough   =   0   'False
            EndProperty
            Height          =   285
            Left            =   120
            TabIndex        =   29
            Top             =   120
            Value           =   -1  'True
            Width           =   735
         End
         Begin VB.OptionButton optionSignNo 
            Caption         =   "No"
            BeginProperty Font 
               Name            =   "Calibri"
               Size            =   12
               Charset         =   0
               Weight          =   400
               Underline       =   0   'False
               Italic          =   0   'False
               Strikethrough   =   0   'False
            EndProperty
            Height          =   255
            Left            =   840
            TabIndex        =   28
            Top             =   120
            Width           =   615
         End
      End
      Begin VB.Frame frmReceipt 
         Height          =   495
         Left            =   2280
         TabIndex        =   24
         Top             =   1320
         Width           =   1575
         Begin VB.OptionButton optionReceiptYes 
            Caption         =   "Yes"
            BeginProperty Font 
               Name            =   "Calibri"
               Size            =   12
               Charset         =   0
               Weight          =   400
               Underline       =   0   'False
               Italic          =   0   'False
               Strikethrough   =   0   'False
            EndProperty
            Height          =   285
            Left            =   120
            TabIndex        =   26
            Top             =   120
            Value           =   -1  'True
            Width           =   735
         End
         Begin VB.OptionButton optionReceiptNo 
            Caption         =   "No"
            BeginProperty Font 
               Name            =   "Calibri"
               Size            =   12
               Charset         =   0
               Weight          =   400
               Underline       =   0   'False
               Italic          =   0   'False
               Strikethrough   =   0   'False
            EndProperty
            Height          =   255
            Left            =   840
            TabIndex        =   25
            Top             =   120
            Width           =   615
         End
      End
      Begin VB.TextBox txtEftposAddress 
         Height          =   375
         Left            =   1920
         TabIndex        =   7
         Top             =   960
         Width           =   1935
      End
      Begin VB.TextBox txtPosId 
         Height          =   375
         Left            =   1920
         TabIndex        =   2
         Top             =   480
         Width           =   1935
      End
      Begin VB.Label lbSign 
         Caption         =   "Sign From EFTPOS:"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   375
         Left            =   120
         TabIndex        =   23
         Top             =   1920
         Width           =   2175
      End
      Begin VB.Label lblReceipt 
         Caption         =   "Receipt From EFTPOS:"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   375
         Left            =   120
         TabIndex        =   22
         Top             =   1440
         Width           =   2415
      End
      Begin VB.Label lblEftposAddress 
         Caption         =   "EFTPOS Address:"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   375
         Left            =   120
         TabIndex        =   3
         Top             =   960
         Width           =   1815
         WordWrap        =   -1  'True
      End
      Begin VB.Label lblPosId 
         Caption         =   "Pos ID:"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   12
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   255
         Left            =   120
         TabIndex        =   1
         Top             =   480
         Width           =   855
      End
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub btnCashout_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to cash out for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Cash Out"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblTipAmount.Visible = False
    frmActions.lblCashoutAmount.Visible = False
    frmActions.lblPrompt.Visible = False
    frmActions.txtAmount.Visible = True
    frmActions.txtAmount.Text = "0"
    frmActions.txtTipAmount.Visible = False
    frmActions.txtCashoutAmount.Visible = False
    frmActions.optionPromptYes.Visible = False
    frmActions.optionPromptNo.Visible = False
    Enabled = False
End Sub

Private Sub btnLastTx_Click()
    frmActions.Show
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
    Enabled = False
    
    Dim gltres As SPIClient.InitiateTxResult
    Set gltres = New SPIClient.InitiateTxResult
    Set gltres = spi.InitiateGetLastTx()
    
    If gltres.Initiated Then
        frmActions.listFlow.AddItem "# GLT Initiated. Will be updated with Progress."
    Else
        frmActions.listFlow.AddItem "# Could not initiate GLT: " + gltres.Message + ". Please Retry."
    End If
End Sub

Private Sub btnMoto_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to moto for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "MOTO"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblTipAmount.Visible = False
    frmActions.lblCashoutAmount.Visible = False
    frmActions.lblPrompt.Visible = False
    frmActions.txtAmount.Visible = True
    frmActions.txtAmount.Text = "0"
    frmActions.txtTipAmount.Visible = False
    frmActions.txtCashoutAmount.Visible = False
    frmActions.optionPromptYes.Visible = False
    frmActions.optionPromptNo.Visible = False
    Enabled = False
End Sub

Private Sub btnPair_Click()
    If btnPair.Caption = "Pair" Then
        posId = txtPosId.Text
        eftposAddress = txtEftposAddress.Text
        spi.SetPosId (posId)
        spi.SetEftposAddress (eftposAddress)
        spi.Config.PromptForCustomerCopyOnEftpos = optionReceiptYes.Value
        spi.Config.SignatureFlowOnEftpos = optionSignYes.Value
        txtPosId.Enabled = False
        txtEftposAddress.Enabled = False
        lblStatus.BackColor = RGB(255, 255, 0)
        spi.Pair
    ElseIf btnPair.Caption = "UnPair" Then
        btnPair.Caption = "Pair"
        frameTransActions.Visible = False
        frameOtherActions.Visible = False
        txtPosId.Enabled = True
        txtEftposAddress.Enabled = True
        lblStatus.BackColor = RGB(255, 0, 0)
        spi.Unpair
    End If
        
    btnPair.Enabled = False
    Enabled = False
End Sub

Private Sub btnPurchase_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to purchase for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Purchase"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblTipAmount.Visible = True
    frmActions.lblCashoutAmount.Visible = True
    frmActions.lblPrompt.Visible = True
    frmActions.txtAmount.Visible = True
    frmActions.txtAmount.Text = "0"
    frmActions.txtTipAmount.Visible = True
    frmActions.txtTipAmount.Text = "0"
    frmActions.txtCashoutAmount.Visible = True
    frmActions.txtCashoutAmount.Text = "0"
    frmActions.optionPromptYes.Visible = True
    frmActions.optionPromptNo.Visible = True
    Enabled = False
End Sub

Private Sub btnRecover_Click()
    If (frmMain.txtReference.Text = "") Then
        MsgBox "Please enter refence!"
    Else
        frmActions.Show
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
        Enabled = False
    
        Dim rres As SPIClient.InitiateTxResult
        Set rres = New SPIClient.InitiateTxResult
        Set rres = spi.InitiateRecovery(txtReference.Text, TransactionType_Purchase)
    
        If rres.Initiated Then
            frmActions.listFlow.AddItem "# Recovery Initiated. Will be updated with Progress."
        Else
            frmActions.listFlow.AddItem "# Could not initiate recovery: " + rres.Message + ". Please Retry."
        End If
    End If
End Sub

Private Sub btnRefund_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to refund for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Refund"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblTipAmount.Visible = False
    frmActions.lblCashoutAmount.Visible = False
    frmActions.lblPrompt.Visible = False
    frmActions.txtAmount.Visible = True
    frmActions.txtAmount.Text = "0"
    frmActions.txtTipAmount.Visible = False
    frmActions.txtCashoutAmount.Visible = False
    frmActions.optionPromptYes.Visible = False
    frmActions.optionPromptNo.Visible = False
    Enabled = False
End Sub

Private Sub btnSettle_Click()
    frmActions.Show
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
    Enabled = False
    
    Dim settle As SPIClient.InitiateTxResult
    
    Set settle = New SPIClient.InitiateTxResult
    Set settle = spi.InitiateSettleTx(comWrapper.Get_Id("settle"))
    
    If settle.Initiated Then
        frmActions.listFlow.AddItem "# Settle Initiated. Will be updated with Progress."
    Else
        frmActions.listFlow.AddItem "# Could not initiate settlement: " + settle.Message + ". Please Retry."
    End If
End Sub

Private Sub btnSettleEnq_Click()
    frmActions.Show
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
    Enabled = False
    
    Dim senqres As SPIClient.InitiateTxResult
    
    Set senqres = New SPIClient.InitiateTxResult
    Set senqres = spi.InitiateSettlementEnquiry(comWrapper.Get_Id("stlenq"))
    
    If senqres.Initiated Then
        frmActions.listFlow.AddItem "# Settle Enquiry Initiated. Will be updated with Progress."
    Else
        frmActions.listFlow.AddItem "# Could not initiate settlement enquiry: " + senqres.Message + ". Please Retry."
    End If
End Sub

Private Sub Form_Load()
    lblStatus.BackColor = RGB(255, 0, 0)
    VB6Pos.Start
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Dim tmpForm As Form
    For Each tmpForm In Forms
        If tmpForm.Name <> "frmMain" Then
            Unload tmpForm
            Set tmpForm = Nothing
        End If
    Next
    Unload Me
End Sub

