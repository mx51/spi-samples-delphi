program MotelDelphiPosDesktop;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {frmMain},
  ActionsUnit in 'ActionsUnit.pas' {frmActions},
  ComponentNames in 'ComponentNames.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;

end.
