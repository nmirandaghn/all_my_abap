report  zcl_alv_table.

tables: mara.

types: begin of ty_material,
        matnr type matnr,
        maktx type maktx,
       end of ty_material.

data it_material type standard table of ty_material.

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
    data: wa_st_data type ty_material, lv_count type i.

    if column eq 'MATNR'.
      read table it_material into wa_st_data index row.

* Check that material exists
      select count( * ) into lv_count from mara up to 1 rows where matnr eq wa_st_data-matnr.

      if lv_count > 0. " Exists?
* Load parameters
        set parameter id 'MXX' field 'K'. " Default view
        set parameter id 'MAT' field wa_st_data-matnr. " Material number

        call transaction 'MM03' and skip first screen.
      else. " No ?
        data err type string.

        call function 'CONVERSION_EXIT_ALPHA_OUTPUT'
          EXPORTING
            input  = wa_st_data-matnr
          IMPORTING
            output = wa_st_data-matnr.
        concatenate `Material ` wa_st_data-matnr ` does not exist.` into err.
        message err type 'I' display like 'E'.
      endif.
    else.
      message text-002 type 'I'. " Invalid cell
    endif.
  endmethod.                    "on_double_click
endclass.                    "cl_handler IMPLEMENTATION

selection-screen: begin of block b1 with frame title text-001.
select-options: s_matnr for mara-matnr.
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
    into table it_material
    where matnr in s_matnr and spras eq sy-langu.
endform.                    "get_data

*&---------------------------------------------------------------------*
*&      Form  display
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
form display.
  data: l_gr_alv type ref to cl_salv_table, " Variables for ALV properties
        l_gr_functions type ref to cl_salv_functions_list.

  data: lv_event_handler type ref to cl_handler, " Variables for events
        lv_events type ref to cl_salv_events_table.

  data: lr_grid type ref to cl_salv_form_layout_grid, " Variables for header
        lr_layout type ref to cl_salv_form_layout_logo,
        cr_content type ref to cl_salv_form_element,
        lv_title type string,
        rows type string.

  data: gr_layout type ref to cl_salv_layout, " Variables for enabling Save button
        key type salv_s_layout_key.

  data: lv_display type ref to cl_salv_display_settings. " Variable for layout settings

  data: lr_selections type ref to cl_salv_selections, " Variables for selection mode and column properties
        lr_columns type ref to cl_salv_columns,
        lr_column  type ref to cl_salv_column_table.

* Create the ALV object
  try.
      call method cl_salv_table=>factory
        IMPORTING
          r_salv_table = l_gr_alv
        CHANGING
          t_table      = it_material.
    catch cx_salv_msg.
  endtry.

* Let's show all default buttons of ALV
  l_gr_functions = l_gr_alv->get_functions( ).
  l_gr_functions->set_all( abap_true ).

* Fit the columns
  lr_columns = l_gr_alv->get_columns( ).
  lr_columns->set_optimize( 'X' ).

* Create header
  describe table it_material lines rows.
  concatenate 'Number of rows: ' rows into lv_title separated by space.

  create object lr_grid.
  create object lr_layout.
  lr_grid->create_label( row = 1 column = 1 text = lv_title tooltip = lv_title ).
  lr_layout->set_left_content( lr_grid ).
  cr_content = lr_layout.
  l_gr_alv->set_top_of_list( cr_content ).

* Apply zebra style to rows
  lv_display = l_gr_alv->get_display_settings( ).
  lv_display->set_striped_pattern( cl_salv_display_settings=>true ).

* Enable the save layout buttons
  key-report = sy-repid.
  gr_layout = l_gr_alv->get_layout( ).
  gr_layout->set_key( key ).
  gr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  gr_layout->set_default( abap_true ).

* Register events
  lv_events = l_gr_alv->get_event( ).
  create object lv_event_handler.
  set handler lv_event_handler->on_double_click for lv_events.

* Enable cell selection mode
  lr_selections = l_gr_alv->get_selections( ).
  lr_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

  try.
      lr_column ?= lr_columns->get_column( 'MAKTX' ). " Seek the 'MAKTX' column ans change attributes
      lr_column->set_visible( if_salv_c_bool_sap=>true ).
      lr_column->set_long_text( 'MyTitle' ).
      lr_column->set_medium_text( 'MyTitle' ).
      lr_column->set_short_text( 'MyTitle' ).
    catch cx_salv_not_found.
    catch cx_salv_existing.
    catch cx_salv_data_error.
  endtry.

  l_gr_alv->display( ).
endform.                    "display