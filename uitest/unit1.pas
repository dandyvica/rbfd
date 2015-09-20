unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus, Process;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    layoutType: TComboBox;
    Edit1: TEdit;
    Label1: TLabel;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

  // name of the chose record-based file
  inputFile: string;

  // used to spawn a new process and call converter
  converter: TProcess;

implementation

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  if Form1.OpenDialog1.Execute then
  begin
    inputFile := Form1.OpenDialog1.Filename;
    ShowMessage(inputFile);

    Edit1.text :=  inputFile;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
   // Now we will create the TProcess object, and
   // assign it to the var converter
   converter := TProcess.Create(nil);

   // Tell the new AProcess what the command to execute is.
   // Let's use the FreePascal compiler
   converter.Executable := '/home/alain/projects/rbfd/readrbf/bin/readrbf';
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

