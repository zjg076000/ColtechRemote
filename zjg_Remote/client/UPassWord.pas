unit UPassWord;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls;

type
  TFPassWord = class(TForm)
    BackgroundTop_Image: TImage;
    PasswordIcon_Image: TImage;
    Label1: TLabel;
    Ok_BitBtn: TBitBtn;
    Password_Edit: TEdit;
    procedure Ok_BitBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FPassWord: TFPassWord;
   Canceled: Boolean;
implementation

{$R *.dfm}

uses Umain;

procedure TFPassWord.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   if Canceled then
  begin
    FMain.Status_Image.Picture.Assign(FMain.Image3.Picture);
    FMain.Status_Label.Caption := 'Access canceled.';
    FMain.TargetID_MaskEdit.Enabled := true;
    FMain.Connect_BitBtn.Enabled := true;
  end;
end;

procedure TFPassWord.FormShow(Sender: TObject);
begin
         Canceled := true;
  Password_Edit.Clear;
  Password_Edit.SetFocus;
end;

procedure TFPassWord.Ok_BitBtnClick(Sender: TObject);
begin
  FMain.Main_Socket.Socket.SendText('<|CHECKIDPASSWORD|>' + FMain.TargetID_MaskEdit.Text + '<|>' + Password_Edit.Text + '<|END|>');
  Canceled := false;
  Close;
end;

end.
