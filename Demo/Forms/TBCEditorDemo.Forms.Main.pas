﻿unit TBCEditorDemo.Forms.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls,
  BCCommon.Form.Base, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, BCEditor.Editor, BCEditor.Highlighter,
  BCEditor.Editor.Base, Vcl.Buttons, Vcl.AppEvnts, System.Actions, Vcl.ActnList, BCEditor.Print, BCCommon.Images,
  BCComponent.SkinManager, BCControl.Panel, BCControl.StatusBar, BCComponent.TitleBar, Vcl.Menus, ObjectInspectorEh,
  BCControl.Splitter, sPanel, BCComponent.MultiStringHolder, sSkinManager, sStatusBar, sSplitter, acTitleBar,
  sSkinProvider, sDialogs, Vcl.StdCtrls, System.Diagnostics, BCCommon.Dialog.Popup.Highlighter,
  BCCommon.Dialog.Popup.Highlighter.Color, sSpeedButton, BCControl.SpeedButton, sComboBox, BCControl.ComboBox, sLabel,
  EhLibVCL, GridsEh, BCEditor.MacroRecorder;

const
  BCEDITORDEMO_CAPTION = 'TBCEditor Control Demo v1.7.0 beta';
  TITLE_BAR_CAPTION = 1;
  TITLE_BAR_HIGHLIGHTER = 2;
  TITLE_BAR_COLORS = 4;

type
  TMainForm = class(TBCBaseForm)
    ActionFileOpen: TAction;
    ActionPreview: TAction;
    ActionSearch: TAction;
    Editor: TBCEditor;
    MenuItemExit: TMenuItem;
    MenuItemFileOpen: TMenuItem;
    MenuItemPrintPreview: TMenuItem;
    MenuItemSeparator1: TMenuItem;
    MenuItemSeparator2: TMenuItem;
    MultiStringHolderFileTypes: TBCMultiStringHolder;
    ObjectInspectorEh: TObjectInspectorEh;
    PanelLeft: TBCPanel;
    PanelProperty: TBCPanel;
    PopupMenuFile: TPopupMenu;
    PopupMenuDummy: TPopupMenu;
    Splitter: TBCSplitter;
    OpenDialog: TsOpenDialog;
    MenuItemSkins: TMenuItem;
    ActionSkins: TAction;
    PanelSearch: TBCPanel;
    ComboBoxSearchText: TBCComboBox;
    BCSplitter1: TBCSplitter;
    SpeedButtonFindPrevious: TBCSpeedButton;
    SpeedButtonFindNext: TBCSpeedButton;
    SpeedButtonDivider: TBCSpeedButton;
    SpeedButtonOptions: TBCSpeedButton;
    SpeedButtonClose: TBCSpeedButton;
    PanelRight: TBCPanel;
    ActionFindNext: TAction;
    ActionFindPrevious: TAction;
    ActionOptions: TAction;
    ActionClose: TAction;
    LabelSearchResultCount: TsLabel;
    procedure ActionFileOpenExecute(Sender: TObject);
    procedure ActionPreviewExecute(Sender: TObject);
    procedure ActionSearchExecute(Sender: TObject);
    procedure ApplicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure EditorCaretChanged(Sender: TObject; X, Y: Integer);
    procedure ActionSkinsExecute(Sender: TObject);
    procedure SelectedHighlighterClick(AHighlighterName: string);
    procedure SelectedHighlighterColorClick(AHighlighterColorName: string);
    procedure FormDestroy(Sender: TObject);
    procedure ActionFindNextExecute(Sender: TObject);
    procedure ActionFindPreviousExecute(Sender: TObject);
    procedure ActionOptionsExecute(Sender: TObject);
    procedure ActionCloseExecute(Sender: TObject);
    procedure ComboBoxSearchTextChange(Sender: TObject);
    procedure ComboBoxSearchTextKeyPress(Sender: TObject; var Key: Char);
    procedure TitleBarItems6Click(Sender: TObject);
    procedure TitleBarItems4Click(Sender: TObject);
  private
    FStopWatch: TStopWatch;
    FPopupHighlighterDialog: TPopupHighlighterDialog;
    FPopupHighlighterColorDialog: TPopupHighlighterColorDialog;
    FHighlighterStrings: TStringList;
    FHighlighterColorStrings: TStringList;
    function GetTitleBarItemLeftBottom(AIndex: Integer): TPoint;
    procedure ClearText;
    procedure DoSearchTextChange;
    procedure InitializeEditorPrint(AEditorPrint: TBCEditorPrint);
    procedure LockFormPaint;
    procedure PrintPreview;
    procedure SetMatchesFound;
    procedure UnlockFormPaint;
    procedure WMEnterSizeMove(var AMessage: TMessage); message WM_ENTERSIZEMOVE;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  BCCommon.Form.Print.Preview, BCEditor.Print.Types, BCCommon.Dialog.SkinSelect, BCCommon.FileUtils, BCEditor.Types,
  BCCommon.Dialog.Options.Search;

procedure TMainForm.ActionSkinsExecute(Sender: TObject);
begin
  inherited;
  TSkinSelectDialog.ClassShowModal(SkinManager);
end;

procedure TMainForm.ApplicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
var
  InfoText: string;
  KeyState: TKeyboardState;
begin
  if PanelSearch.Visible then
    Editor.Margins.Bottom := 0
  else
    Editor.Margins.Bottom := 5;
  if Editor.Modified then
    InfoText := 'Modified'
  else
    InfoText := '';
  if StatusBar.Panels[2].Text <> InfoText then
    StatusBar.Panels[2].Text := InfoText;
  GetKeyboardState(KeyState);
  if KeyState[VK_INSERT] = 0 then
    if StatusBar.Panels[1].Text <> 'Insert' then
      StatusBar.Panels[1].Text := 'Insert';
  if KeyState[VK_INSERT] = 1 then
    if StatusBar.Panels[1].Text <> 'Overwrite' then
      StatusBar.Panels[1].Text := 'Overwrite';
end;

procedure TMainForm.DoSearchTextChange;
begin
   if Assigned(Editor) then
    Editor.Search.SearchText := ComboBoxSearchText.Text;
  SetMatchesFound;
end;

procedure TMainForm.ComboBoxSearchTextChange(Sender: TObject);
begin
  inherited;
  if soSearchOnTyping in Editor.Search.Options then
    DoSearchTextChange;
end;

procedure TMainForm.ComboBoxSearchTextKeyPress(Sender: TObject; var Key: Char);
begin
  inherited;
  if (Key = #13) or (Key = #10) then
  begin
    if Assigned(Editor) then
      if Editor.CanFocus then
        Editor.SetFocus;
    if ComboBoxSearchText.Items.IndexOf(ComboBoxSearchText.Text) = -1 then
      ComboBoxSearchText.Items.Add(ComboBoxSearchText.Text);
    Key := #0;

    DoSearchTextChange;
  end;
end;

procedure TMainForm.SetMatchesFound;
var
  s: string;
begin
  s := '';

  if Assigned(Editor) and (Editor.SearchResultCount > 1) then
    s := 'es';
  if Assigned(Editor) and (Editor.SearchResultCount > 0) then
    s := Format('%d match%s found', [Editor.SearchResultCount, s]);

  LabelSearchResultCount.Caption := s;
end;

procedure TMainForm.TitleBarItems4Click(Sender: TObject);
var
  LPoint: TPoint;
begin
  inherited;
  if Assigned(FPopupHighlighterDialog) then
    Exit;

  FPopupHighlighterDialog := TPopupHighlighterDialog.Create(Self);
  try
    FPopupHighlighterDialog.PopupParent := Self;
    FPopupHighlighterDialog.OnSelectHighlighter := SelectedHighlighterClick;

    LPoint := GetTitleBarItemLeftBottom(TITLE_BAR_HIGHLIGHTER);

    FPopupHighlighterDialog.Left := LPoint.X;
    FPopupHighlighterDialog.Top := LPoint.Y;

    LockFormPaint;

    FPopupHighlighterDialog.Execute(FHighlighterStrings, TitleBar.Items[TITLE_BAR_HIGHLIGHTER].Caption);

    UnlockFormPaint;

    while Assigned(FPopupHighlighterDialog) and FPopupHighlighterDialog.Visible do
      Application.HandleMessage;
  finally
    FPopupHighlighterDialog.Free;
    FPopupHighlighterDialog := nil;
  end;
end;

procedure TMainForm.TitleBarItems6Click(Sender: TObject);
var
  LPoint: TPoint;
begin
  inherited;
  if Assigned(FPopupHighlighterColorDialog) then
    Exit;

  FPopupHighlighterColorDialog := TPopupHighlighterColorDialog.Create(Self);
  try
    FPopupHighlighterColorDialog.PopupParent := Self;
    FPopupHighlighterColorDialog.OnSelectHighlighterColor := SelectedHighlighterColorClick;

    LPoint := GetTitleBarItemLeftBottom(TITLE_BAR_COLORS);

    FPopupHighlighterColorDialog.Left := LPoint.X;
    FPopupHighlighterColorDialog.Top := LPoint.Y;

    LockFormPaint;

    FPopupHighlighterColorDialog.Execute(FHighlighterColorStrings, TitleBar.Items[TITLE_BAR_COLORS].Caption);

    UnlockFormPaint;

    while Assigned(FPopupHighlighterColorDialog) and FPopupHighlighterColorDialog.Visible do
      Application.HandleMessage;
  finally
    FPopupHighlighterColorDialog.Free;
    FPopupHighlighterColorDialog := nil;
  end;
end;

procedure TMainForm.ClearText;
begin
  ComboBoxSearchText.Text := '';
  if Assigned(Editor) then
    Editor.Search.SearchText := '';
  SetMatchesFound;
end;

procedure TMainForm.EditorCaretChanged(Sender: TObject; X, Y: Integer);
var
  InfoText: string;
begin
  inherited;
  InfoText := Format('%d: %d', [Y, X]);
  if StatusBar.Panels[0].Text <> InfoText then
    StatusBar.Panels[0].Text := InfoText;
end;

procedure TMainForm.InitializeEditorPrint(AEditorPrint: TBCEditorPrint);
var
  Alignment: TAlignment;

  procedure SetHeaderFooter(Option: Integer; Value: string);
  begin
    case Option of
      0, 1:
        with AEditorPrint.Footer do
        begin
          case Option of
            0:
              Alignment := taLeftJustify;
            1:
              Alignment := taRightJustify;
          end;
          Add(Value, nil, Alignment, 1);
        end;
      2, 3:
        with AEditorPrint.Header do
        begin
          case Option of
            2:
              Alignment := taLeftJustify;
            3:
              Alignment := taRightJustify;
          end;
          Add(Value, nil, Alignment, 1);
        end;
    end;
  end;

begin
  AEditorPrint.Header.Clear;
  AEditorPrint.Footer.Clear;

  SetHeaderFooter(0, Format('Printed by', [Application.Title]));
  SetHeaderFooter(1, 'Page: $PAGENUM$ of $PAGECOUNT$');
  SetHeaderFooter(2, Editor.DocumentName);
  SetHeaderFooter(3, '$DATE$ $TIME$');

  AEditorPrint.Header.FrameTypes := [ftLine];
  AEditorPrint.Footer.FrameTypes := [ftLine];
  AEditorPrint.LineNumbersInMargin := True;
  AEditorPrint.LineNumbers := True;
  AEditorPrint.Wrap := False;
  AEditorPrint.Colors := True;

  AEditorPrint.Editor := Editor;
  AEditorPrint.Title := Editor.DocumentName;
end;

procedure TMainForm.ActionFindNextExecute(Sender: TObject);
begin
  inherited;
  if Assigned(Editor) then
  begin
    DoSearchTextChange;
    Editor.FindNext;
  end;
end;

procedure TMainForm.ActionFindPreviousExecute(Sender: TObject);
begin
  inherited;
  if Assigned(Editor) then
  begin
    DoSearchTextChange;
    Editor.FindPrevious;
  end;
end;

procedure TMainForm.ActionOptionsExecute(Sender: TObject);
begin
  inherited;
  if Assigned(Editor) then
    TSearchOptionsDialog.ClassShowModal(Editor);
end;

procedure TMainForm.ActionPreviewExecute(Sender: TObject);
begin
  PrintPreview
end;

procedure TMainForm.PrintPreview;
begin
  with PrintPreviewDialog do
  begin
    InitializeEditorPrint(PrintPreview.EditorPrint);
    ShowModal;
  end;
end;

procedure TMainForm.ActionCloseExecute(Sender: TObject);
begin
  inherited;
  PanelSearch.Visible := False;
end;

procedure TMainForm.ActionFileOpenExecute(Sender: TObject);
var
  LFileName: string;
begin
  OpenDialog.Title := 'Open';
  if OpenDialog.Execute(Handle) then
  begin
    FStopWatch.Reset;
    FStopWatch.Start;
    LFileName := OpenDialog.Files[0];
    TitleBar.Items[TITLE_BAR_CAPTION].Caption := Format('%s - %s', [BCEDITORDEMO_CAPTION, LFileName]);
    Editor.LoadFromFile(LFileName);
    FStopWatch.Stop;
    StatusBar.Panels[3].Text := 'Load: ' + FormatDateTime('s.zzz "s"', FStopWatch.ElapsedMilliseconds / MSecsPerDay);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  inherited;
  TitleBar.Items[TITLE_BAR_CAPTION].Caption := BCEDITORDEMO_CAPTION;
  SkinManager.ExtendedBorders := True;
  { IDE can lose these properties }
  PopupMenuFile.Images := ImagesDataModule.ImageList;
  TitleBar.Images := ImagesDataModule.ImageListSmall;

  FHighlighterStrings := GetHighlighters;
  FHighlighterColorStrings := GetHighlighterColors;

  SelectedHighlighterClick('Object Pascal');
  SelectedHighlighterColorClick('Default');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FHighlighterStrings.Free;
  FHighlighterColorStrings.Free;

  inherited;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  ObjectInspectorEh.Component := Editor;
  ObjectInspectorEh.LabelColWidth := 145;
end;

function TMainForm.GetTitleBarItemLeftBottom(AIndex: Integer): TPoint;
var
  LRect: TRect;
begin
  Result.X := TitleBar.Items[AIndex].Rect.Left;
  Result.Y := TitleBar.Items[AIndex].Rect.Bottom;

  if Assigned(TitleBar.Items[AIndex].ExtForm) then
  begin
    Inc(Result.X, TitleBar.Items[AIndex].ExtForm.Left);
    Inc(Result.Y, TitleBar.Items[AIndex].ExtForm.Top);
  end
  else
  begin
    GetWindowRect(Handle, LRect);
    Inc(Result.Y, LRect.Top);
    Inc(Result.X, LRect.Left);
  end;
end;

procedure TMainForm.ActionSearchExecute(Sender: TObject);
begin
  Editor.Search.Enabled := True;
  PanelSearch.Visible := True;
  ComboBoxSearchText.Text := Editor.Search.SearchText;
  ComboBoxSearchText.SetFocus;
end;

procedure TMainForm.SelectedHighlighterClick(AHighlighterName: string);
begin
  with Editor do
  begin
    Highlighter.LoadFromFile(Format('%s.json', [AHighlighterName]));
    CodeFolding.Visible := Highlighter.CodeFoldingRangeCount > 0;
  end;
  TitleBar.Items[TITLE_BAR_HIGHLIGHTER].Caption := Editor.Highlighter.Name;
  Editor.Lines.Text := Editor.Highlighter.Info.General.Sample;
  Editor.CaretZero;
  StatusBar.Panels[3].Text := '';
  Caption := BCEDITORDEMO_CAPTION;
  ClearText;
end;

procedure TMainForm.SelectedHighlighterColorClick(AHighlighterColorName: string);
begin
  with Editor do
  begin
    Highlighter.Colors.LoadFromFile(Format('%s.json', [AHighlighterColorName]));
    Invalidate;
  end;
  TitleBar.Items[TITLE_BAR_COLORS].Caption := Editor.Highlighter.Colors.Name;
end;

procedure TMainForm.LockFormPaint;
begin
  SkinProvider.SkinData.BeginUpdate;
  SkinProvider.Form.Perform(WM_SETREDRAW, 0, 0);
end;

procedure TMainForm.UnlockFormPaint;
begin
  SkinProvider.SkinData.EndUpdate;
  SkinProvider.Form.Perform(WM_SETREDRAW, 1, 0);
end;

procedure TMainForm.WMEnterSizeMove(var AMessage: TMessage);
begin
  if Assigned(FPopupHighlighterDialog) then
  begin
    FPopupHighlighterDialog.Free;
    FPopupHighlighterDialog := nil;
  end;
  if Assigned(FPopupHighlighterColorDialog) then
  begin
    FPopupHighlighterColorDialog.Free;
    FPopupHighlighterColorDialog := nil;
  end;
  inherited;
end;

end.
