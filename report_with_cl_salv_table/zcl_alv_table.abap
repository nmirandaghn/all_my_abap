report  zcl_alv_table.

types: begin of ty_material,
         matnr type matnr,
         maktx type maktx,
       end of ty_material.

data: g_matnr     like mara-matnr,
      gt_material type standard table of ty_material.

*----------------------------------------------------------------------*
*       CLASS cl_handler DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class cl_handler definition.
  public section.
    methods on_double_click for event double_click of cl_salv_events_table
      importing row column.
endclass.                    "cl_handler DEFINITION

*----------------------------------------------------------------------*
*       CLASS cl_handler IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class cl_handler implementation.
  method on_double_click.
    if column eq 'MATNR'.
      read table gt_material into data(wa_st_data) index row.

* Check that material exists
      select count( * ) from mara up to 1 rows where matnr eq wa_st_data-matnr.

      if sy-subrc = 0. " Exists?
* Load parameters
        set parameter id 'MXX' field 'K'. " Default view
        set parameter id 'MAT' field wa_st_data-matnr. " Material number

        call transaction 'MM03' and skip first screen.
      else. " No ?

        call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
          exporting
            input  = wa_st_data-matnr
          importing
            output = wa_st_data-matnr.

        data(lv_err) = `Material ` && wa_st_data-matnr && ` does not exist.`.
        message lv_err type 'I' display like 'E'.
      endif.
    else.
      message text-002 type 'I'. " Invalid cell
    endif.
  endmethod.                    "on_double_click
endclass.                    "cl_handler IMPLEMENTATION

selection-screen: begin of block b1 with frame title text-001.
select-options: so_matnr for g_matnr.
selection-screen: end of block b1.

start-of-selection.
  perform retrieve_data.
  perform display.

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
form retrieve_data.
  select matnr maktx from makt up to 100 rows " Retrieve only 100 records
    into table gt_material
    where matnr in so_matnr and spras eq sy-langu.
endform.                    "get_data

*&---------------------------------------------------------------------*
*&      Form  display
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
form display.
  data: lo_gr_alv       type ref to cl_salv_table, " Variables for ALV properties
        lo_gr_functions type ref to cl_salv_functions_list.

  data: lo_event_handler type ref to cl_handler, " Variables for events
        lo_events        type ref to cl_salv_events_table.

  data: lo_grid        type ref to cl_salv_form_layout_grid, " Variables for header
        lo_layout_logo type ref to cl_salv_form_layout_logo,
        lo_content     type ref to cl_salv_form_element,
        lv_title       type string,
        lv_rows        type string.

  data: lo_layout type ref to cl_salv_layout, " Variables for enabling Save button
        lv_key    type salv_s_layout_key.

  data: lo_display type ref to cl_salv_display_settings. " Variable for layout settings

  data: lo_selections type ref to cl_salv_selections, " Variables for selection mode and column properties
        lo_columns    type ref to cl_salv_columns,
        lo_column     type ref to cl_salv_column_table.

* Create the ALV object
  try.
      call method cl_salv_table=>factory
        importing
          r_salv_table = lo_gr_alv
        changing
          t_table      = gt_material.
    catch cx_salv_msg.
  endtry.

* Let's show all default buttons of ALV
  lo_gr_functions = lo_gr_alv->get_functions( ).
  lo_gr_functions->set_all( abap_true ).

* Fit the columns
  lo_columns = lo_gr_alv->get_columns( ).
  lo_columns->set_optimize( 'X' ).

* Create header
  describe table gt_material lines lv_rows.
  concatenate 'Number of lv_rows: ' lv_rows into lv_title separated by space.

  create object lo_grid.
  create object lo_layout_logo.
  lo_grid->create_label( row = 1 column = 1 text = lv_title tooltip = lv_title ).
  lo_layout_logo->set_left_content( lo_grid ).
  lo_content = lo_layout_logo.
  lo_gr_alv->set_top_of_list( lo_content ).

* Apply zebra style to lv_rows
  lo_display = lo_gr_alv->get_display_settings( ).
  lo_display->set_striped_pattern( cl_salv_display_settings=>true ).

* Enable the save layout buttons
  lv_key-report = sy-repid.
  lo_layout = lo_gr_alv->get_layout( ).
  lo_layout->set_key( lv_key ).
  lo_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  lo_layout->set_default( abap_true ).

* Register events
  lo_events = lo_gr_alv->get_event( ).
  create object lo_event_handler.
  set handler lo_event_handler->on_double_click for lo_events.

* Enable cell selection mode
  lo_selections = lo_gr_alv->get_selections( ).
  lo_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

  try.
      lo_column ?= lo_columns->get_column( 'MAKTX' ). " Find the 'MAKTX' column ans change attributes
      lo_column->set_visible( if_salv_c_bool_sap=>true ).
      lo_column->set_long_text( 'MyTitle' ).
      lo_column->set_medium_text( 'MyTitle' ).
      lo_column->set_short_text( 'MyTitle' ).
    catch cx_salv_not_found.
    catch cx_salv_existing.
    catch cx_salv_data_error.
  endtry.

  lo_gr_alv->display( ).
endform.                    "display