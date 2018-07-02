object frmMain: TfrmMain
  Left = 366
  Top = 103
  AutoSize = True
  BorderIcons = [biSystemMenu]
  Caption = 'Motel Delphi Pos'
  ClientHeight = 530
  ClientWidth = 626
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Verdana'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlSettings: TPanel
    Left = 0
    Top = 0
    Width = 313
    Height = 147
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object lblSettings: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Settings'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 95
    end
    object lblPosID: TLabel
      Left = 1
      Top = 40
      Width = 53
      Height = 19
      Caption = 'Pos ID:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object lblEftposAddress: TLabel
      Left = 1
      Top = 72
      Width = 134
      Height = 19
      AutoSize = False
      Caption = 'EFTPOS Address:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object lblReceiptFrom: TLabel
      Left = 1
      Top = 100
      Width = 150
      Height = 19
      AutoSize = False
      Caption = 'Receipt From EFTPOS:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object lblSignFrom: TLabel
      Left = 1
      Top = 123
      Width = 150
      Height = 19
      AutoSize = False
      Caption = 'Sign From EFTPOS:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object edtPosID: TEdit
      Left = 143
      Top = 40
      Width = 158
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object radioSign: TRadioGroup
      Left = 141
      Top = 97
      Width = 160
      Height = 42
      Columns = 2
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Yes'
        'No')
      ParentFont = False
      TabOrder = 3
    end
    object radioReceipt: TRadioGroup
      Left = 141
      Top = 75
      Width = 160
      Height = 42
      Columns = 2
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Yes'
        'No')
      ParentFont = False
      TabOrder = 2
    end
    object edtEftposAddress: TEdit
      Left = 143
      Top = 70
      Width = 158
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 147
    Width = 313
    Height = 110
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    object lblStatusHead: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Status'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 74
    end
    object lblStatus: TLabel
      Left = 60
      Top = 40
      Width = 185
      Height = 19
      Alignment = taCenter
      AutoSize = False
      Caption = 'Idle'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      Layout = tlCenter
    end
    object btnPair: TButton
      Left = 74
      Top = 65
      Width = 158
      Height = 34
      Caption = 'Pair'
      TabOrder = 0
      OnClick = btnPairClick
    end
  end
  object pnlReceipt: TPanel
    Left = 313
    Top = 0
    Width = 313
    Height = 530
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    object lblReceipt: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Receipt'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 87
    end
    object richEdtReceipt: TRichEdit
      Left = 0
      Top = 35
      Width = 307
      Height = 486
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      Zoom = 100
    end
  end
  object pnlPreAuthActions: TPanel
    Left = 0
    Top = 257
    Width = 313
    Height = 160
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    Visible = False
    object lblPreAuthActions: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Pre-Auth Actions'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 197
    end
    object btnVerify: TButton
      Left = 20
      Top = 40
      Width = 80
      Height = 34
      Caption = 'Verify'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btnVerifyClick
    end
    object btnExtend: TButton
      Left = 117
      Top = 80
      Width = 80
      Height = 34
      Caption = 'Extend'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = btnExtendClick
    end
    object btnTopDown: TButton
      Left = 20
      Top = 80
      Width = 80
      Height = 34
      Caption = 'Top Down'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = btnTopDownClick
    end
    object btnComplete: TButton
      Left = 212
      Top = 80
      Width = 80
      Height = 34
      Caption = 'Complete'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = btnCompleteClick
    end
    object btnOpen: TButton
      Left = 117
      Top = 40
      Width = 80
      Height = 34
      Caption = 'Open'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = btnOpenClick
    end
    object btnTopUp: TButton
      Left = 212
      Top = 40
      Width = 80
      Height = 34
      Caption = 'Top Up'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = btnTopUpClick
    end
    object btnCancel: TButton
      Left = 117
      Top = 120
      Width = 80
      Height = 34
      Caption = 'Cancel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = btnCancelClick
    end
  end
  object pnlOtherActions: TPanel
    Left = 0
    Top = 417
    Width = 313
    Height = 112
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    Visible = False
    object lblOtherActions: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Other Actions'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitLeft = 2
      ExplicitTop = 9
    end
    object lblReference: TLabel
      Left = 1
      Top = 40
      Width = 75
      Height = 19
      Caption = 'Reference:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object btnRecover: TButton
      Left = 74
      Top = 70
      Width = 80
      Height = 34
      Caption = 'Recover'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btnRecoverClick
    end
    object btnLastTx: TButton
      Left = 173
      Top = 70
      Width = 80
      Height = 34
      Caption = 'Last Tx'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = btnLastTxClick
    end
    object edtReference: TEdit
      Left = 147
      Top = 40
      Width = 158
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
  end
end
