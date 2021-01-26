  METHOD create_xls_from_itab.

    DATA:
      lt_fcat        TYPE lvc_t_fcat,
      lt_data        TYPE REF TO data,
      l_flavour      TYPE string,
      l_version      TYPE string,
      lo_result_data TYPE REF TO cl_salv_ex_result_data_table,
      lo_columns     TYPE REF TO cl_salv_columns_table,
      lo_aggreg      TYPE REF TO cl_salv_aggregations,
      lo_salv_table  TYPE REF TO cl_salv_table,
      l_file_type    TYPE salv_bs_constant.

    FIELD-SYMBOLS <l_tab> TYPE ANY TABLE.

    GET REFERENCE OF ct_data INTO lt_data.

*if we didn't pass fieldcatalog we need to create it
    IF it_fieldcat[] IS INITIAL.
      ASSIGN lt_data->* TO <l_tab>.
      TRY .
          cl_salv_table=>factory(  EXPORTING
                                     list_display = abap_false
                                   IMPORTING
                                     r_salv_table = lo_salv_table
                                   CHANGING
                                     t_table      = <l_tab> ).
        CATCH cx_salv_msg.

      ENDTRY.
      "get colums & aggregation infor to create fieldcat
      lo_columns  = lo_salv_table->get_columns( ).
      lo_aggreg   = lo_salv_table->get_aggregations( ).
      lt_fcat     =  cl_salv_controller_metadata=>get_lvc_fieldcatalog( r_columns      = lo_columns
                                                                        r_aggregations = lo_aggreg ).
    ELSE.
*else we take the one we passed
      lt_fcat[] = it_fieldcat[].
    ENDIF.


    IF cl_salv_bs_a_xml_base=>get_version( ) EQ if_salv_bs_xml=>version_25 OR
       cl_salv_bs_a_xml_base=>get_version( ) EQ if_salv_bs_xml=>version_26.

      lo_result_data = cl_salv_ex_util=>factory_result_data_table( r_data                      = lt_data
                                                                   s_layout                    = is_layout
                                                                   t_fieldcatalog              = lt_fcat
                                                                   t_sort                      = it_sort
                                                                   t_filter                    = it_filt ).

      CASE cl_salv_bs_a_xml_base=>get_version( ).
        WHEN if_salv_bs_xml=>version_25.
          l_version = if_salv_bs_xml=>version_25.

        WHEN if_salv_bs_xml=>version_26.
          l_version = if_salv_bs_xml=>version_26.

      ENDCASE.

      "if we flag i_XLSX then we'll create XLSX if not then MHTML excel file
      IF i_xlsx IS NOT INITIAL.
        l_file_type = if_salv_bs_xml=>c_type_xlsx.
      ELSE.
        l_file_type = if_salv_bs_xml=>c_type_mhtml.
      ENDIF.


      l_flavour = if_salv_bs_c_tt=>c_tt_xml_flavour_export.
      "transformation of data to excel
      CALL METHOD cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform
        EXPORTING
          xml_type      = l_file_type
          xml_version   = l_version
          r_result_data = lo_result_data
          xml_flavour   = l_flavour
          gui_type      = if_salv_bs_xml=>c_gui_type_gui
        IMPORTING
          xml           = e_xstring.
    ENDIF.

  ENDMETHOD.