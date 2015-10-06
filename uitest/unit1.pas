unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus, ExtCtrls, ComCtrls, Process;

type

  { TMain }

  TMain = class(TForm)
    btnInput: TButton;
    Button2: TButton;
    layoutType: TComboBox;
    Edit1: TEdit;
    lblFileType: TLabel;
    OpenDialog1: TOpenDialog;
    rgOutputType: TRadioGroup;
    StatusBar1: TStatusBar;
    procedure btnInputClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Main: TMain;

  // name of the chose record-based file
  inputFile: string;

  // used to spawn a new process and call converter
  converter: TProcess;

implementation

{ TMain }

// select input file to convert
procedure TMain.btnInputClick(Sender: TObject);
begin
  if Main.OpenDialog1.Execute then
  begin
    inputFile := Main.OpenDialog1.Filename;
    Edit1.text :=  inputFile;

    // get file size to update status bar
    StatusBar1.Panels.Items[0].Text := inputFile;
  end;
end;

procedure TMain.Button2Click(Sender: TObject);
begin
   // Now we will create the TProcess object, and
   // assign it to the var converter
   converter := TProcess.Create(nil);

   // Tell the new AProcess what the command to execute is.
   // Let's use the FreePascal compiler
   converter.Executable := '/usr/local/bin/readrbf';
   converter.Parameters.Add('-l');
   converter.Parameters.Add(layoutType.Text);
   converter.Parameters.Add('-i');
   converter.Parameters.Add(inputFile);
   converter.Parameters.Add('-v');

   // We will define an option for when the program
   // is run. This option will make sure that our program
   // does not continue until the program we will launch
   // has stopped running.
   converter.Options := converter.Options + [poWaitOnExit];

   // Now that AProcess knows what the commandline is
   // we will run it.
   converter.Execute;

   // This is not reached until program stops running.
   converter.Free;
   ShowMessage('finished');
end;


begin


{$R *.lfm}

end.

