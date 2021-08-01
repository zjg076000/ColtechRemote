unit UShareFiles;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.ImageList, Vcl.ImgList,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ExtCtrls;

type
  TFShareFiles = class(TForm)
    ShareFiles_ListView: TListView;
    Menu_Panel: TPanel;
    UploadProgress_Label: TLabel;
    DownloadProgress_Label: TLabel;
    Directory_Label: TLabel;
    Bevel1: TBevel;
    SizeDownload_Label: TLabel;
    SizeUpload_Label: TLabel;
    Download_BitBtn: TBitBtn;
    Upload_BitBtn: TBitBtn;
    Upload_ProgressBar: TProgressBar;
    Download_ProgressBar: TProgressBar;
    Directory_Edit: TEdit;
    ImageList1: TImageList;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Download_BitBtnClick(Sender: TObject);
    procedure Upload_BitBtnClick(Sender: TObject);
    procedure Directory_EditKeyPress(Sender: TObject; var Key: Char);
    procedure ShareFiles_ListViewDblClick(Sender: TObject);
  private
     procedure WMGetMinMaxInfo(var Message: TWMGetMinMaxInfo); message WM_GETMINMAXINFO;
    procedure GoToDirectory(Directory: string);
    procedure EnterInDirectory;
  public
    DirectoryToSaveFile: string;
    FileStream: TFileStream;
  end;

var
  FShareFiles: TFShareFiles;

implementation
    uses umain;
{$R *.dfm}

procedure TFShareFiles.Directory_EditKeyPress(Sender: TObject; var Key: Char);
begin
    if (Key = #13) then
  begin
    GoToDirectory(Directory_Edit.Text);
    Key := #0;
  end;
end;

procedure TFShareFiles.Download_BitBtnClick(Sender: TObject);
begin
   if ShareFiles_ListView.ItemIndex = -1 then
    exit;

  if not(ShareFiles_ListView.Selected.ImageIndex = 0) and not(ShareFiles_ListView.Selected.ImageIndex = 1) then
  begin
    SaveDialog1.FileName := '';
    SaveDialog1.Filter := 'File (*' + ExtractFileExt(ShareFiles_ListView.Selected.Caption) + ')|*' + ExtractFileExt(ShareFiles_ListView.Selected.Caption);

    if SaveDialog1.Execute() then
    begin
      DirectoryToSaveFile := SaveDialog1.FileName + ExtractFileExt(ShareFiles_ListView.Selected.Caption);
      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|DOWNLOADFILE|>' + Directory_Edit.Text + ShareFiles_ListView.Selected.Caption + '<|END|>');
      Download_BitBtn.Enabled := false;
    end;
  end;
end;

procedure TFShareFiles.EnterInDirectory;
var
  Directory: string;
begin
  if (ShareFiles_ListView.ItemIndex = -1) or not(Directory_Edit.Enabled) then
    exit;

  if (ShareFiles_ListView.Selected.ImageIndex = 0) or (ShareFiles_ListView.Selected.ImageIndex = 1) then
  begin
    if ShareFiles_ListView.Selected.Caption = 'Return' then
    begin
      Directory := Directory_Edit.Text;
      Delete(Directory, Length(Directory), Length(Directory));
      Directory_Edit.Text := ExtractFilePath(Directory + '..');
    end
    else
      Directory_Edit.Text := Directory_Edit.Text + ShareFiles_ListView.Selected.Caption + '\';

    GoToDirectory(Directory_Edit.Text);
  end;
end;

procedure TFShareFiles.FormCreate(Sender: TObject);
begin
      SetWindowLong(Handle, GWL_EXSTYLE, WS_EX_APPWINDOW);
end;

procedure TFShareFiles.FormShow(Sender: TObject);
begin
   GoToDirectory(Directory_Edit.Text);
end;

procedure TFShareFiles.GoToDirectory(Directory: string);
 begin
  Directory_Edit.Enabled := false;

  if not (Directory[Length(Directory)] = '\') then
  begin
    Directory := Directory + '\';
    Directory_Edit.Text := Directory;
  end;

  FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|GETFOLDERS|>' + Directory + '<|END|>');
end;

procedure TFShareFiles.ShareFiles_ListViewDblClick(Sender: TObject);
begin
    EnterInDirectory;
end;

procedure TFShareFiles.Upload_BitBtnClick(Sender: TObject);

  var
  FileName: string;
  arquivo: TMemoryStream;
begin
  OpenDialog1.FileName := '';

  if OpenDialog1.Execute() then
  begin
    FileStream := TFileStream.Create(OpenDialog1.FileName, fmOpenRead);
    FileName := ExtractFileName(OpenDialog1.FileName);
    Upload_ProgressBar.Max := FileStream.Size;
   FMain.Files_Socket.Socket.SendText('<|DIRECTORYTOSAVE|>' + Directory_Edit.Text + FileName + '<|><|SIZE|>' + intToStr(FileStream.Size) + '<|END|>');
    FileStream.Position := 0;
    FMain.Files_Socket.Socket.SendStream(FileStream);
    Upload_BitBtn.Enabled := false;
  end;
end;

procedure TFShareFiles.WMGetMinMaxInfo(var Message: TWMGetMinMaxInfo);
{ sets Size-limits for the Form }
var
  MinMaxInfo: PMinMaxInfo;
begin
  inherited;
  MinMaxInfo := Message.MinMaxInfo;
  MinMaxInfo^.ptMinTrackSize.X := 515; // Minimum Width
  MinMaxInfo^.ptMinTrackSize.Y := 460; // Minimum Height
end;


end.
