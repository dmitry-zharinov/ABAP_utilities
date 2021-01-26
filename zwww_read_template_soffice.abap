  METHOD read_template.
    DATA:
      l_filename    TYPE string,
      lt_folder_tab TYPE TABLE OF soxhi,
      l_path        TYPE string,
      l_dirlen      LIKE sy-fdpos.

    IF NOT m_file_source IS INITIAL AND
       NOT m_source_type IS INITIAL.

      l_dirlen = strlen( m_file_source ) - 1.

      WHILE l_dirlen > 0.
        IF m_file_source+l_dirlen(1) = '\' OR m_file_source+l_dirlen(1) = '/'. "dirlen is the part before '/' or '\'
          EXIT.
        ENDIF.
        l_dirlen = l_dirlen - 1.
      ENDWHILE.

      IF l_dirlen > 0.
        l_dirlen = l_dirlen + 1.
        l_path     = m_file_source(l_dirlen).
        l_filename = m_file_source+l_dirlen.
      ELSE.
        l_filename = m_file_source.
      ENDIF.
      ztkmmcl_ioi_utils=>get_file_parts(  EXPORTING  i_filename  =  l_filename  IMPORTING e_filename = DATA(l_obj_name) e_extension = DATA(l_ext) ).

      DATA:
        ls_folder_id           TYPE soodk,
        l_printforms_folder_id TYPE so_obj_id,
        lt_files               TYPE TABLE OF sofolenti1,
        ls_hd_display          TYPE sood2,
        lt_objcont             TYPE soli_tab,
        lt_objcontx            TYPE  solix_tab.
*   получаем корневую папку
      CALL FUNCTION 'SO_FOLDER_HIERARCHY_READ'
        TABLES
          hierarchy_table = lt_folder_tab
        EXCEPTIONS
          OTHERS          = 0.

      LOOP AT lt_folder_tab ASSIGNING FIELD-SYMBOL(<ls_folder>).
        IF <ls_folder>-node_text = m_folder.
          l_printforms_folder_id = <ls_folder>-node_key.
          EXIT.
        ENDIF.
      ENDLOOP.

* считаем все файлы из папки
      CALL FUNCTION 'SO_FOLDER_READ_API1'
        EXPORTING
          folder_id      = l_printforms_folder_id
        TABLES
          folder_content = lt_files
        EXCEPTIONS
          OTHERS         = 0.

      DATA(ls_template) = lt_files[ obj_descr = l_obj_name ].

      IF ls_template IS NOT INITIAL.

        CALL FUNCTION 'SO_OBJECT_READ'
          EXPORTING
            folder_id         = l_printforms_folder_id
            object_id         = ls_template-object_id
          IMPORTING
            object_hd_display = ls_hd_display
          TABLES
            objcont           = lt_objcont[]
          EXCEPTIONS
            OTHERS            = 0.

        IF ls_hd_display-extct = 'K'. "REFERENCE_TYPE_KPRO
          CALL FUNCTION 'SO_CONTENT_FROM_KPRO_GET'
            TABLES
              objcont = lt_objcont[]
            EXCEPTIONS
              OTHERS  = 0.
        ENDIF.

        CALL FUNCTION 'SO_SOLITAB_TO_SOLIXTAB'
          EXPORTING
            ip_solitab  = lt_objcont[]
          IMPORTING
            ep_solixtab = lt_objcontx[].


        CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
          EXPORTING
            input_length = CONV i( ls_hd_display-objlen )
          IMPORTING
            buffer       = es_data-file_template
          TABLES
            binary_tab   = lt_objcontx
          EXCEPTIONS
            OTHERS       = 0.

        es_data-file_template_ext = |.{ l_ext }|.
      ENDIF.


    ENDIF.

  ENDMETHOD.