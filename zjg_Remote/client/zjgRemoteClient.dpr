program zjgRemoteClient;

uses
  Vcl.Forms,
  Umain in 'Umain.pas' {Fmain},
  sndkey32 in '..\Units\sndkey32.pas',
  StreamManager in '..\Units\StreamManager.pas',
  ZLibEx in '..\Units\DelphiZlib\ZLibEx.pas',
  ZLibExApi in '..\Units\DelphiZlib\ZLibExApi.pas',
  ZLibExGZ in '..\Units\DelphiZlib\ZLibExGZ.pas',
  UPassWord in 'UPassWord.pas' {FPassWord},
  URemoteScreen in 'URemoteScreen.pas' {FRemoteScreen},
  UShareFiles in 'UShareFiles.pas' {FShareFiles},
  UChat in 'UChat.pas' {FChat};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFmain, Fmain);
  Application.CreateForm(TFPassWord, FPassWord);
  Application.CreateForm(TFRemoteScreen, FRemoteScreen);
  Application.CreateForm(TFShareFiles, FShareFiles);
  Application.CreateForm(TFChat, FChat);
  Application.Run;
end.
