function zqrcode .
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(I_TEXT) TYPE  CHAR255
*"     REFERENCE(I_NAME) TYPE  CHAR20
*"     REFERENCE(I_WIDHT) TYPE  I DEFAULT 200
*"     REFERENCE(I_HEIGHT) TYPE  I DEFAULT 200
*"  EXPORTING
*"     REFERENCE(E_CHECK) TYPE  CHAR01
*"----------------------------------------------------------------------
  perform get_qrcode using i_text changing e_check.
  check e_check is not initial.

  perform convert_image using i_name i_widht i_height changing e_check.
endfunction.