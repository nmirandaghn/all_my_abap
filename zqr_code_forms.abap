*&---------------------------------------------------------------------*
*&      Form  GET_QRCODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TEXT  text
*      -->P_CHECK text
*----------------------------------------------------------------------*
form get_qrcode using p_text type char255 changing p_check type c.
  data oref type ref to cx_root.
  data wa_source type zgen_qrsource.
  select single * from zgen_qrsource into wa_source. " Get webservice address for QR code generation

  check sy-subrc eq 0.

  concatenate wa_source-address p_text into url.

  call method cl_http_client=>create_by_url
    exporting
      url                = url
    importing
      client             = http_client
    exceptions
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      others             = 4.

  if sy-subrc = 0.

*    http_client->send( ).
    call method http_client->send
    exceptions
      http_communication_failure = 1
      http_invalid_state = 2
      http_processing_failed = 3
      http_invalid_timeout = 4.

*    http_client->receive( ).
    call method http_client->receive
    exceptions
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      others                     = 4.

    check sy-subrc eq 0.

    content = http_client->response->get_data( ).

    http_client->close( ).

    l_str_length = xstrlen( content ).

    call function 'RSFO_XSTRING_TO_MIME'
      exporting
        c_xstring = content
        i_length  = l_str_length
      tables
        c_t_mime  = mime.

    p_check = 'X'.
  endif.
endform.                    " download_qrcode

*&---------------------------------------------------------------------*
*&      Form  convert_image
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_NAME     text
*      -->P_HEIGHT   text
*      -->P_WIDTH    text
*      -->P_CHECK    text
*----------------------------------------------------------------------*
form convert_image using p_name type char20 p_height type i p_width type i changing p_check type c.
  create object i_igs_image_converter .

  i_igs_image_converter->input = 'image/png'.
  i_igs_image_converter->output = 'image/bmp'.
  i_igs_image_converter->width = p_width.
  i_igs_image_converter->height = p_height.

  call method i_igs_image_converter->set_image
    exporting
      blob      = mime
      blob_size = l_content_length.

  call method i_igs_image_converter->execute
    exceptions
      communication_error = 1
      internal_error      = 2
      external_error      = 3
      others              = 4.

  if sy-subrc = 0.
    call method i_igs_image_converter->get_image
      importing
        blob      = blob
        blob_size = blob_size
        blob_type = blob_type.

    p_check = 'X'.
  else.
    clear p_check.
  endif.

  if sy-subrc = 0.
    perform generate_picture using p_name changing p_check.
  endif.
endform.                    " CONVERT_IMAGE

*&---------------------------------------------------------------------*
*&      Form  generate_picture
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_NAME     text
*      -->P_CHECK    text
*----------------------------------------------------------------------*
form generate_picture using p_name type char20 changing p_check type c.
  gi_name = p_name.
  gi_object = 'GRAPHICS'.
  gi_id = 'BMAP'.
  gi_btype = 'BCOL'. " If u want black and white pass BMON
  gi_resident = ' '.
  gi_autoheight =  'X'.
  gi_bmcomp = 'X'.
  l_extension = 'BMP'.

  "importing the image into se78 before displaying it in the smartform.
  perform import_bitmap_bds    using blob
                                   gi_name
                                   gi_object
                                   gi_id
                                   gi_btype
                                   l_extension
                                   ' '
                                   gi_resident
                                   gi_autoheight
                                   gi_bmcomp
                          changing l_docid
                                   gi_resolution.

  if sy-subrc = 0.
    p_check = 'X'.
  else.
    clear p_check.
  endif.
endform.                    " SHOW_SMART_FORM

*&---------------------------------------------------------------------*
*&      Form  import_bitmap_bds
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_BLOB        text
*      -->P_NAME        text
*      -->P_OBJECT      text
*      -->P_ID          text
*      -->P_BTYPE       text
*      -->P_FORMAT      text
*      -->P_TITLE       text
*      -->P_RESIDENT    text
*      -->P_AUTOHEIGHT  text
*      -->P_BMCOMP      text
*      -->P_DOCID       text
*      -->P_RESOLUTION  text
*----------------------------------------------------------------------*
form import_bitmap_bds
        using    p_blob       type w3mimetabtype
                 p_name           type stxbitmaps-tdname
                 p_object         type stxbitmaps-tdobject
                 p_id             type stxbitmaps-tdid
                 p_btype          type stxbitmaps-tdbtype
                 p_format         type c
                 p_title          like bds_description
                 p_resident       type stxbitmaps-resident
                 p_autoheight     type stxbitmaps-autoheight
                 p_bmcomp         type stxbitmaps-bmcomp
        changing p_docid          type stxbitmaps-docid
                 p_resolution     type stxbitmaps-resolution.


  data: l_object_key type sbdst_object_key.
  data: l_tab        type ddobjname.

  data: begin of l_bitmap occurs 0,
          l(64) type x,
        end of l_bitmap.

  data: l_filename        type string,
        l_bytecount       type i,
        l_bds_bytecount   type i.
  data: l_color(1)        type c,

        l_width_tw        type stxbitmaps-widthtw,
        l_height_tw       type stxbitmaps-heighttw,
        l_width_pix       type stxbitmaps-widthpix,
        l_height_pix      type stxbitmaps-heightpix.
  data: l_bds_object      type ref to cl_bds_document_set,
        l_bds_content     type sbdst_content,
        l_bds_components  type sbdst_components,
        wa_bds_components type line of sbdst_components,
        l_bds_signature   type sbdst_signature,
        wa_bds_signature  type line of sbdst_signature,
        l_bds_properties  type sbdst_properties,
        wa_bds_properties type line of sbdst_properties.

  data  wa_stxbitmaps type stxbitmaps.

* Enqueue
  perform enqueue_graphic using p_object
                                p_name
                                p_id
                                p_btype.

* Bitmap conversion
  call function 'SAPSCRIPT_CONVERT_BITMAP_BDS'
    exporting
      color                    = 'X'
      format                   = p_format
      resident                 = p_resident
      bitmap_bytecount         = l_bytecount
      compress_bitmap          = p_bmcomp
    importing
      width_tw                 = l_width_tw
      height_tw                = l_height_tw
      width_pix                = l_width_pix
      height_pix               = l_height_pix
      dpi                      = p_resolution
      bds_bytecount            = l_bds_bytecount
    tables
      bitmap_file              = p_blob
      bitmap_file_bds          = l_bds_content
    exceptions
      format_not_supported     = 1
      no_bmp_file              = 2
      bmperr_invalid_format    = 3
      bmperr_no_colortable     = 4
      bmperr_unsup_compression = 5
      bmperr_corrupt_rle_data  = 6
      others                   = 7.

  if sy-subrc <> 0.

    perform dequeue_graphic using p_object
                                  p_name
                                  p_id
                                  p_btype.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
    raising conversion_failed.

  endif.

* Save bitmap in BDS
  create object l_bds_object.

  wa_bds_components-doc_count  = '1'.
  wa_bds_components-comp_count = '1'.
  wa_bds_components-mimetype   = c_bds_mimetype.
  wa_bds_components-comp_size  = l_bds_bytecount.
  append wa_bds_components to l_bds_components.

  if p_docid is initial.          " graphic is new

    wa_bds_signature-doc_count = '1'.
    append wa_bds_signature to l_bds_signature.


    call method l_bds_object->create_with_table
      exporting
        classname  = c_bds_classname
        classtype  = c_bds_classtype
        components = l_bds_components
        content    = l_bds_content
      changing
        signature  = l_bds_signature
        object_key = l_object_key
      exceptions
        others     = 1.

    if sy-subrc <> 0.

      perform dequeue_graphic using p_object
                                    p_name
                                    p_id
                                    p_btype.
*      message e285 with p_name  'BDS'.

    endif.

    read table l_bds_signature index 1 into wa_bds_signature
    transporting doc_id.

    if sy-subrc = 0.

      p_docid = wa_bds_signature-doc_id.

    else.

      perform dequeue_graphic using p_object
                                    p_name
                                    p_id
                                    p_btype.
*      message e285 with p_name 'BDS'.

    endif.

  else.                " graphic already exists

********* read object_key for faster access *****
    clear l_object_key.
    select single * from stxbitmaps into wa_stxbitmaps
        where tdobject = p_object
          and tdid     = p_id
          and tdname   = p_name
          and tdbtype  = p_btype.

    select single tabname from bds_locl into l_tab
       where classname = c_bds_classname
          and classtype = c_bds_classtype.

    if sy-subrc = 0.
      select single object_key from (l_tab) into l_object_key
        where loio_id = wa_stxbitmaps-docid+10(32)
          and classname = c_bds_classname
            and classtype = c_bds_classtype.
    endif.

******** read object_key end ********************
    call method l_bds_object->update_with_table
      exporting
        classname     = c_bds_classname
        classtype     = c_bds_classtype
        object_key    = l_object_key
        doc_id        = p_docid
        doc_ver_no    = '1'
        doc_var_id    = '1'
      changing
        components    = l_bds_components
        content       = l_bds_content
      exceptions
        nothing_found = 1
        others        = 2.

    if sy-subrc = 1.   " inconsistency STXBITMAPS - BDS; repeat check in

      wa_bds_signature-doc_count = '1'.
      append wa_bds_signature to l_bds_signature.

      call method l_bds_object->create_with_table
        exporting
          classname  = c_bds_classname
          classtype  = c_bds_classtype
          components = l_bds_components
          content    = l_bds_content
        changing
          signature  = l_bds_signature
          object_key = l_object_key
        exceptions
          others     = 1.

      if sy-subrc <> 0.
        perform dequeue_graphic using p_object
                                      p_name
                                      p_id
                                      p_btype.
*        message e285 with p_name 'BDS'.

      endif.

      read table l_bds_signature index 1 into wa_bds_signature
      transporting doc_id.
      if sy-subrc = 0.
        p_docid = wa_bds_signature-doc_id.
      else.

        perform dequeue_graphic using p_object
                                      p_name
                                      p_id
                                      p_btype.

*        message e285 with p_name 'BDS'.

      endif.

    elseif sy-subrc = 2.

      perform dequeue_graphic using p_object
                                    p_name
                                    p_id
                                    p_btype.

*      message e285 with p_name 'BDS'.

    endif.

  endif.

* Save bitmap header in STXBITPMAPS
  wa_stxbitmaps-tdname     = p_name.
  wa_stxbitmaps-tdobject   = p_object.
  wa_stxbitmaps-tdid       = p_id.
  wa_stxbitmaps-tdbtype    = p_btype.
  wa_stxbitmaps-docid      = p_docid.
  wa_stxbitmaps-widthpix   = l_width_pix.
  wa_stxbitmaps-heightpix  = l_height_pix.
  wa_stxbitmaps-widthtw    = l_width_tw.
  wa_stxbitmaps-heighttw   = l_height_tw.
  wa_stxbitmaps-resolution = p_resolution.
  wa_stxbitmaps-resident   = p_resident.
  wa_stxbitmaps-autoheight = p_autoheight.
  wa_stxbitmaps-bmcomp     = p_bmcomp.
  insert into stxbitmaps values wa_stxbitmaps.

  if sy-subrc <> 0.

    update stxbitmaps from wa_stxbitmaps.

    if sy-subrc <> 0.
*       message e285 with p_name 'STXBITMAPS'.
    endif.
  endif.

* Set description in BDS attributes
  wa_bds_properties-prop_name  = 'DESCRIPTION'.
  wa_bds_properties-prop_value = p_title.
  append wa_bds_properties to l_bds_properties.
  call method l_bds_object->change_properties
    exporting
      classname  = c_bds_classname
      classtype  = c_bds_classtype
      object_key = l_object_key
      doc_id     = p_docid
      doc_ver_no = '1'
      doc_var_id = '1'
    changing
      properties = l_bds_properties
    exceptions
      others     = 1.

  perform dequeue_graphic using p_object
                                p_name
                                p_id
                                p_btype.
endform.                    "import_bitmap_bds

*&---------------------------------------------------------------------*
*&      Form  ENQUEUE_GRAPHIC
*&---------------------------------------------------------------------*
* Enqueue of graphics stored in BDS
*----------------------------------------------------------------------*
form enqueue_graphic using p_object
                           p_name
                           p_id
                           p_btype.
  call function 'ENQUEUE_ESSGRABDS'
       exporting
*           MODE_STXBITMAPS = 'E'
            tdobject        = p_object
            tdname          = p_name
            tdid            = p_id
            tdbtype         = p_btype
*           X_TDOBJECT      = ' '
*           X_TDNAME        = ' '
*           X_TDID          = ' '
*           X_TDBTYPE       = ' '
*           _SCOPE          = '2'
*           _WAIT           = ' '
*           _COLLECT        = ' '
       exceptions
            foreign_lock    = 1
            others          = 2.

  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
          with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
    raising enqueue_failed.
  endif.

endform.                    " ENQUEUE_GRAPHIC

*&---------------------------------------------------------------------*
*&      Form  DEQUEUE_GRAPHIC
*&---------------------------------------------------------------------*
* Dequeue of graphics stored in BDS
*----------------------------------------------------------------------*
form dequeue_graphic using p_object
                           p_name
                           p_id
                           p_btype.

  call function 'DEQUEUE_ESSGRABDS'
       exporting
*           MODE_STXBITMAPS = 'E'
*           X_TDOBJECT      = ' '
*           X_TDNAME        = ' '
*           X_TDID          = ' '
*           X_TDBTYPE       = ' '
*           _SCOPE          = '3'
*           _SYNCHRON       = ' '
*           _COLLECT        = ' '
            tdobject        = p_object
            tdname          = p_name
            tdid            = p_id
            tdbtype         = p_btype.

endform.                    " DEQUEUE_GRAPHIC