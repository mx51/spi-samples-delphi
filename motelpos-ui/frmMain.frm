VERSION 5.00
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "RICHTX32.OCX"
Begin VB.Form frmMain 
   Caption         =   "Motel VB6 Pos"
   ClientHeight    =   9285
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
   ScaleHeight     =   9285
   ScaleWidth      =   8955
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
      Height          =   1575
      Left            =   120
      TabIndex        =   29
      Top             =   3480
      Visible         =   0   'False
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
         Left            =   240
         TabIndex        =   31
         Top             =   960
         Width           =   1575
      End
      Begin VB.CommandButton btnSecrets 
         Caption         =   "Secrets"
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
         TabIndex        =   30
         Top             =   960
         Visible         =   0   'False
         Width           =   1575
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
         TabIndex        =   32
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
      Height          =   3495
      Left            =   120
      TabIndex        =   13
      Top             =   0
      Width           =   3975
      Begin VB.TextBox txtPosId 
         Height          =   375
         Left            =   1920
         TabIndex        =   23
         Top             =   480
         Width           =   1935
      End
      Begin VB.TextBox txtEftposAddress 
         Height          =   375
         Left            =   1920
         TabIndex        =   22
         Top             =   960
         Width           =   1935
      End
      Begin VB.Frame frmReceipt 
         Height          =   495
         Left            =   2280
         TabIndex        =   19
         Top             =   1800
         Width           =   1575
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
            TabIndex        =   21
            Top             =   120
            Width           =   615
         End
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
            TabIndex        =   20
            Top             =   120
            Value           =   -1  'True
            Width           =   735
         End
      End
      Begin VB.Frame frmSign 
         Height          =   495
         Left            =   2280
         TabIndex        =   16
         Top             =   2280
         Width           =   1575
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
            TabIndex        =   18
            Top             =   120
            Width           =   615
         End
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
            TabIndex        =   17
            Top             =   120
            Value           =   -1  'True
            Width           =   735
         End
      End
      Begin VB.CommandButton btnSave 
         Caption         =   "Save"
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
         Left            =   2280
         TabIndex        =   15
         Top             =   2880
         Width           =   1575
      End
      Begin VB.TextBox txtSecrets 
         Height          =   375
         Left            =   1920
         TabIndex        =   14
         Top             =   1440
         Width           =   1935
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
         TabIndex        =   28
         Top             =   480
         Width           =   855
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
         Index           =   0
         Left            =   120
         TabIndex        =   27
         Top             =   960
         Width           =   1815
         WordWrap        =   -1  'True
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
         TabIndex        =   26
         Top             =   1920
         Width           =   2415
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
         TabIndex        =   25
         Top             =   2400
         Width           =   2175
      End
      Begin VB.Label lblSecrets 
         Caption         =   "Secrets:"
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
         TabIndex        =   24
         Top             =   1440
         Width           =   1815
         WordWrap        =   -1  'True
      End
   End
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
      TabIndex        =   9
      Top             =   7560
      Visible         =   0   'False
      Width           =   3975
      Begin VB.TextBox txtReference 
         Height          =   375
         Left            =   1800
         TabIndex        =   11
         Top             =   480
         Width           =   1935
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
         Left            =   1800
         TabIndex        =   10
         Top             =   1080
         Width           =   1935
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
         TabIndex        =   12
         Top             =   480
         Width           =   1095
      End
   End
   Begin VB.Frame framePreauthActions 
      Caption         =   "Pre-Auth Actions"
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
      TabIndex        =   1
      Top             =   5160
      Visible         =   0   'False
      Width           =   3975
      Begin VB.CommandButton btnCancel 
         Caption         =   "Cancel"
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
         Left            =   1440
         TabIndex        =   33
         Top             =   1680
         Width           =   1095
      End
      Begin VB.CommandButton btnComplete 
         Caption         =   "Complete"
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
         Left            =   1440
         TabIndex        =   8
         Top             =   1080
         Width           =   1095
      End
      Begin VB.CommandButton btnOpen 
         Caption         =   "Open"
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
         Left            =   1440
         TabIndex        =   7
         Top             =   480
         Width           =   1095
      End
      Begin VB.CommandButton btnExtend 
         Caption         =   "Extend"
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
         Left            =   120
         TabIndex        =   6
         Top             =   1080
         Width           =   1095
      End
      Begin VB.CommandButton btnTopUp 
         Caption         =   "Top Up"
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
         Left            =   2760
         TabIndex        =   5
         Top             =   480
         Width           =   1095
      End
      Begin VB.CommandButton btnVerify 
         Caption         =   "Verify"
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
         Left            =   120
         TabIndex        =   4
         Top             =   480
         Width           =   1095
      End
      Begin VB.CommandButton btnTopDown 
         Caption         =   "Top Down"
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
         Left            =   2760
         TabIndex        =   3
         Top             =   1080
         Width           =   1095
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
      Height          =   9255
      Left            =   4200
      TabIndex        =   0
      Top             =   0
      Width           =   4695
      Begin RichTextLib.RichTextBox richtxtReceipt 
         Height          =   8655
         Left            =   120
         TabIndex        =   2
         Top             =   480
         Width           =   4455
         _ExtentX        =   7858
         _ExtentY        =   15266
         _Version        =   393217
         Enabled         =   -1  'True
         ScrollBars      =   2
         TextRTF         =   $"frmMain.frx":0000
      End
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub btnCancel_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to cancel"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Preauth Cancel"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = False
    frmActions.lblPreauthId.Visible = True
    frmActions.txtAmount.Visible = False
    frmActions.txtPreauthId.Visible = True
    Enabled = False
End Sub

Private Sub btnComplete_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to complete for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Complete"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblAmount.Caption = "Amount (cents):"
    frmActions.lblPreauthId.Visible = True
    frmActions.txtAmount.Visible = True
    frmActions.txtAmount.Text = "0"
    frmActions.txtPreauthId.Visible = True
    Enabled = False
End Sub

Private Sub btnExtend_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to extend for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Extend"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = False
    frmActions.lblPreauthId.Visible = True
    frmActions.txtAmount.Visible = False
    frmActions.txtPreauthId.Visible = True
    Enabled = False
End Sub

Private Sub btnOpen_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to open for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Open"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblAmount.Caption = "Amount (cents):"
    frmActions.lblPreauthId.Visible = False
    frmActions.txtAmount.Visible = True
    frmActions.txtAmount.Text = "0"
    frmActions.txtPreauthId.Visible = False
    Enabled = False
End Sub

Private Sub btnPair_Click()
    If btnPair.Caption = "Pair" Then
        spi.Pair
        btnSecrets.Visible = True
        txtPosId.Enabled = False
        txtEftposAddress.Enabled = False
        lblStatus.BackColor = RGB(255, 255, 0)
    ElseIf btnPair.Caption = "UnPair" Then
        spi.Unpair
        btnPair.Caption = "Pair"
        framePreauthActions.Visible = False
        frameOtherActions.Visible = False
        txtPosId.Enabled = True
        txtEftposAddress.Enabled = True
        txtSecrets.Text = ""
        lblStatus.BackColor = RGB(255, 0, 0)
    End If
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
        frmActions.lblPreauthId.Visible = False
        frmActions.txtAmount.Visible = False
        frmActions.txtPreauthId.Visible = False
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

Private Sub btnSave_Click()
    VB6Pos.Start
    
    btnSave.Enabled = False
    If txtPosId.Text = "" Or txtEftposAddress.Text = "" Then
        MsgBox "Please fill the parameters", vbOKOnly, "Warning"
        Exit Sub
    End If
        
    spi.SetPosId (posId)
    spi.SetEftposAddress (eftposAddress)
    spi.Config.PromptForCustomerCopyOnEftpos = optionReceiptYes.Value
    spi.Config.SignatureFlowOnEftpos = optionSignYes.Value
    frameStatus.Visible = True
End Sub

Private Sub btnSecrets_Click()
    frmActions.listFlow.Clear

    If (Not spiSecrets Is Nothing) Then
        frmActions.listFlow.AddItem "Pos Id: " + posId
        frmActions.listFlow.AddItem "Eftpos Address: " + eftposAddress
        frmActions.listFlow.AddItem "Secrets: " + spiSecrets.encKey + ":" + spiSecrets.hmacKey
        frmActions.txtAmount.Text = spiSecrets.encKey + ":" + spiSecrets.hmacKey
    Else
        frmActions.listFlow.AddItem "I have no secrets!"
        frmActions.txtAmount.Text = ""
    End If

    frmActions.Show
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "OK"
    frmActions.btnAction2.Visible = False
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblAmount.Caption = "Secrets:"
    frmActions.txtAmount.Visible = True
    frmActions.lblPreauthId.Visible = False
    frmActions.txtPreauthId.Visible = False
End Sub

Private Sub btnTopDown_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to top down for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Top Down"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblAmount.Caption = "Amount (cents):"
    frmActions.lblPreauthId.Visible = True
    frmActions.txtAmount.Visible = True
    frmActions.txtAmount.Text = "0"
    frmActions.txtPreauthId.Visible = True
    Enabled = False
End Sub

Private Sub btnTopUp_Click()
    frmActions.Show
    frmActions.lblFlowMessage.Caption = "Please enter the amount you would like to top up for in cents"
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Top Up"
    frmActions.btnAction2.Visible = True
    frmActions.btnAction2.Caption = "Cancel"
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = True
    frmActions.lblAmount.Caption = "Amount (cents):"
    frmActions.lblPreauthId.Visible = True
    frmActions.txtAmount.Visible = True
    frmActions.txtAmount.Text = "0"
    frmActions.txtPreauthId.Visible = True
    Enabled = False
End Sub

Private Sub btnVerify_Click()
    frmActions.Show
    frmActions.btnAction1.Visible = True
    frmActions.btnAction1.Caption = "Cancel"
    frmActions.btnAction2.Visible = False
    frmActions.btnAction3.Visible = False
    frmActions.lblAmount.Visible = False
    frmActions.lblPreauthId.Visible = False
    frmActions.txtAmount.Visible = False
    frmActions.txtPreauthId.Visible = False
    Enabled = False
    
    Dim initRes As SPIClient.InitiateTxResult
    
    Set initRes = New SPIClient.InitiateTxResult
    Set initRes = spiPreauth.InitiateAccountVerifyTx("actvfy-" + Format(Now, "dd-mm-yyyy-hh-nn-ss"))
    
    If initRes.Initiated Then
        frmActions.listFlow.AddItem "# Account verify request initiated. Will be updated with Progress."
    Else
        frmActions.listFlow.AddItem "# Could not initiate account verify request: " + initRes.Message + ". Please Retry."
    End If
End Sub

Private Sub Form_Load()
    posId = ""
    eftposAddress = ""
    Set spiSecrets = New SPIClient.Secrets
    Set spi = New SPIClient.spi
    Set spiPreauth = New SPIClient.spiPreauth
    Set comWrapper = New SPIClient.comWrapper
    Set spiSecrets = Nothing
    
    txtPosId.Text = "VBPOS"
    lblStatus.BackColor = RGB(255, 0, 0)
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Dim tmpForm As Form
    For Each tmpForm In Forms
        If tmpForm.Name <> "frmMain" Then
            Unload tmpForm
            Set tmpForm = Nothing
        End If
    Next
    
    End
End Sub
