* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method 
* Преобразуем XSTRING-файл в исходном формате DOCX в HTML через OPENXML. Изображения встраиваем в HTML в BASE64-кодировке
* +-------------------------------------------------------------------------------------------------+
* | [--->] IM_DOCX_DATA                   TYPE        XSTRING
* | [<---] RE_HTML_DATA                   TYPE        XSTRING
* | [<---] RESSOURCES_TAB                 TYPE        T_RESSOURCES_TAB
* | [!CX!] CX_MERGE_PARTS
* | [!CX!] CX_TRANSFORMATION_ERROR
* | [!CX!] CX_OPENXML_FORMAT
* | [!CX!] CX_OPENXML_NOT_FOUND
* | [!CX!] ZCX_GENERIC
* +--------------------------------------------------------------------------------------</SIGNATURE>
METHOD convert_docx2html.
* FAQ: https://blogs.sap.com/2014/05/28/manipulate-docx-document-with-abap/

  DATA: l_docx_src TYPE xstring,
        lo_conv    TYPE REF TO cl_xsl_docx_fo_conv.


  DATA: lo_image_part_coll   TYPE REF TO cl_openxml_partcollection,
        lo_part              TYPE REF TO cl_openxml_part,
        lo_image_part        TYPE REF TO cl_oxml_imagepart,
        lo_docx_document     TYPE REF TO cl_docx_document,
        lo_maindocpart       TYPE REF TO cl_docx_maindocumentpart,
        lo_headerpartcoll    TYPE REF TO cl_openxml_partcollection,
        lo_footerpartcoll    TYPE REF TO cl_openxml_partcollection,
        lo_headerpart        TYPE REF TO cl_docx_headerpart,
        lo_footerpart        TYPE REF TO cl_docx_footerpart,
        l_headerpart_id      TYPE string,
        l_footerpart_id      TYPE string,
        l_num_of_image_parts TYPE i,
        l_counter            TYPE i,
        l_outer_counter      TYPE i,
        l_image_part_id      TYPE string,
        l_html_data          TYPE string.


  DATA: l_cid                TYPE string.

  DATA: ls_ressource          TYPE t_ressource.

  DATA: tidy               TYPE REF TO cl_htmltidy.

  DEFINE macro_get_ressource.

* get image part collection
    lo_image_part_coll = &1->get_imageparts( ).


* get number of image parts
    l_num_of_image_parts = lo_image_part_coll->get_count( ).

* loop over images
    l_counter = 0.
    do l_num_of_image_parts times.

* get image part
      lo_part = lo_image_part_coll->get_part( l_counter ).

* downcast to image part
      lo_image_part ?= lo_part.


* get id for part
      l_image_part_id = &1->get_id_for_part( lo_image_part ).


      concatenate &2 '_' &3 '_' l_image_part_id into l_cid.
      ls_ressource-cid          = l_cid.
      ls_ressource-ressource    = lo_image_part->get_data( ).
      ls_ressource-content_type = lo_image_part->get_content_type( ).


* append to ressource table
     append ls_ressource to ressources_tab.

     l_counter = l_counter + 1.

    enddo.

  END-OF-DEFINITION.

* get images from docx
  lo_docx_document = cl_docx_document=>load_document( im_docx_data ).


* get images from  main document part
  lo_maindocpart = lo_docx_document->get_maindocumentpart( ).

  macro_get_ressource lo_maindocpart 'main' ''.             "#EC NOTEX

*get images from header part
  lo_headerpartcoll = lo_maindocpart->get_headerparts( ).

  l_outer_counter = 0.
  DO lo_headerpartcoll->get_count( ) TIMES.
    lo_part = lo_headerpartcoll->get_part( l_outer_counter ).
    lo_headerpart ?= lo_part.
    l_headerpart_id = lo_maindocpart->get_id_for_part( lo_headerpart ).
*      catch CX_OPENXML_NOT_FOUND.  "
    macro_get_ressource lo_headerpart 'hdr' l_headerpart_id . "#EC NOTEX
    l_outer_counter = l_outer_counter + 1 .
  ENDDO.

*get images from footer part
  lo_footerpartcoll = lo_maindocpart->get_footerparts( ).


  l_outer_counter = 0.
  DO lo_footerpartcoll->get_count( ) TIMES.
    lo_part = lo_footerpartcoll->get_part( l_outer_counter ).
    lo_footerpart ?= lo_part.
    l_footerpart_id = lo_maindocpart->get_id_for_part( lo_footerpart ).
    macro_get_ressource lo_footerpart 'ftr' l_footerpart_id . "#EC NOTEX
    l_outer_counter = l_outer_counter + 1 .
  ENDDO.

  CREATE OBJECT lo_conv.

  TRY.
      CALL METHOD lo_conv->merge_parts_xstring
        EXPORTING
          im_input  = im_docx_data
        RECEIVING
          re_output = l_docx_src.
    CATCH cx_merge_parts.
      RAISE EXCEPTION TYPE cx_merge_parts.
  ENDTRY.
  CLEAR re_html_data.
  TRY.
      CALL TRANSFORMATION t_xsl_docx_html
      SOURCE XML l_docx_src
      RESULT XML l_html_data.
    CATCH cx_transformation_error.
      RAISE EXCEPTION TYPE cx_transformation_error.
  ENDTRY.

* Встраиваем в файл изображения в BASE64

  DATA: l_str_to_replace TYPE string,
        l_str_to_insert  TYPE string,
        l_image_base64   TYPE string.

  LOOP AT ressources_tab ASSIGNING FIELD-SYMBOL(<l_res>).
    CHECK <l_res>-content_type CS 'image'.
    CALL FUNCTION 'SSFC_BASE64_ENCODE'
      EXPORTING
        bindata = <l_res>-ressource
      IMPORTING
        b64data = l_image_base64
      EXCEPTIONS
        OTHERS  = 1. " Over simplifying exception handling
    IF sy-subrc <> 0.
      zcx__generic=>raise( ).
    ENDIF.

    l_str_to_replace = |cid:{ <l_res>-cid }|.
    l_str_to_insert = |data:{ <l_res>-content_type };base64,{ l_image_base64 }|.

    REPLACE FIRST OCCURRENCE OF l_str_to_replace IN l_html_data WITH l_str_to_insert.

  ENDLOOP.


  CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text   = l_html_data
    IMPORTING
      buffer = re_html_data.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.





ENDMETHOD.