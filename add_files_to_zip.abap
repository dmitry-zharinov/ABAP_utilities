
* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ADD_FILES_TO_ZIP
* +-------------------------------------------------------------------------------------------------+
* | [--->] IS_BINDATA                       TYPE        zs_bin_data.
* | [!CX!] ZCX_ERROR
* +--------------------------------------------------------------------------------------</SIGNATURE>
METHOD add_files_to_zip.
  DATA: lo_zip    TYPE REF TO cl_abap_zip,
        l_xstr    TYPE xstring.

  CHECK it_files IS NOT INITIAL.

  CREATE OBJECT lo_zip.
  lo_zip->support_unicode_names = abap_true.


* 1. BIN -> XSTRING
    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = is_bindata-length
      IMPORTING
        buffer       = l_xstr
      TABLES
        binary_tab   = ls_bindata-t_bindata.

    lo_zip->add( EXPORTING name = CONV string( 'TEST.zip' )
                        content = l_xstr ).

  e_zip_xstr = lo_zip->save( ).

  IF e_zip_xstr IS INITIAL.
* MESSAGE: Ошибка при создании zip-архива 
  ENDIF.


ENDMETHOD.